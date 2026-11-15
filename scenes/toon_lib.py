import json
import math

import bmesh
import bpy
import rb
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Matrix, Vector

PPU = 160
KANVAS = 1024                       # persegi; ortho_scale = KANVAS / PPU = 6.4 unit
JARAK = 40.0                        # jarak kamera dari target (unit, ortografik)
SAMPEL = 16
TEBAL_GARIS = 8.0                   # px pada 160 ppu (kontrak: ±7 px; logo lebih tebal)
GARIS = "#14213D"
SUDUT_DERAJAT = {"samping": 8.0, "belakang": 20.0, "depan": 8.0}
LIGHT = Vector((-0.35, -0.55, 0.75)).normalized()   # arah ke cahaya (dari objek)

_bahan = {}
root = None


# ---------- warna dan material ----------

def _lin(c):
    c = c / 255.0
    return ((c + 0.055) / 1.055) ** 2.4 if c > 0.04045 else c / 12.92


def _rgb(hexs, faktor=1.0):
    h = hexs.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return tuple(_lin(min(255.0, v * faktor)) for v in (r, g, b)) + (1.0,)


def bahan(hexs, gelap=0.72):
    """Material toon: sisi terang = warna, sisi membelakangi cahaya = warna * gelap."""
    key = (hexs, gelap)
    if key in _bahan:
        return _bahan[key]
    m = bpy.data.materials.new(f"toon_{hexs}_{gelap}")
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    dot = nt.nodes.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    dot.inputs[1].default_value = tuple(LIGHT)
    nt.links.new(geo.outputs["Normal"], dot.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    el0 = ramp.color_ramp.elements[0]
    el0.position = 0.0
    el0.color = (0.0, 0.0, 0.0, 1.0)
    el1 = ramp.color_ramp.elements.new(0.12)
    el1.color = (1.0, 1.0, 1.0, 1.0)
    nt.links.new(dot.outputs["Value"], ramp.inputs["Fac"])
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    warna_in = [s for s in mix.inputs if s.type == "RGBA" and not s.is_linked]
    warna_in[0].default_value = _rgb(hexs, gelap)     # A: faktor 0 = bayangan
    warna_in[1].default_value = _rgb(hexs)            # B: faktor 1 = terang
    nt.links.new(ramp.outputs["Color"], mix.inputs[0])
    warna_out = [s for s in mix.outputs if s.type == "RGBA"][0]
    emi = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(warna_out, emi.inputs["Color"])
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    nt.links.new(emi.outputs["Emission"], out.inputs["Surface"])
    _bahan[key] = m
    return m


# ---------- primitif (satu objek per bagian; semua anak akar) ----------

def _tempel(ob, nama, hexs, gelap, bevel, halus):
    ob.name = nama
    ob.data.name = nama
    ob.data.materials.clear()
    ob.data.materials.append(bahan(hexs, gelap))
    for p in ob.data.polygons:
        p.use_smooth = halus
    if bevel > 0:
        md = ob.modifiers.new("lengkung", "BEVEL")
        md.width = bevel
        md.segments = 3
        md.limit_method = "ANGLE"
        md.angle_limit = math.radians(35)
    ob.parent = root
    return ob


def kotak(nama, ukuran, pos, hexs, bevel=0.08, gelap=0.72):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=pos)
    ob = bpy.context.object
    ob.data.transform(Matrix.Diagonal((ukuran[0], ukuran[1], ukuran[2], 1.0)))
    return _tempel(ob, nama, hexs, gelap, bevel, halus=False)


def silinder(nama, r, panjang, pos, hexs, sumbu="Z", bevel=0.02, gelap=0.72, segmen=40):
    rot = {"X": (0.0, math.pi / 2, 0.0), "Y": (math.pi / 2, 0.0, 0.0), "Z": (0.0, 0.0, 0.0)}[sumbu]
    bpy.ops.mesh.primitive_cylinder_add(vertices=segmen, radius=r, depth=panjang,
                                        location=pos, rotation=rot)
    return _tempel(bpy.context.object, nama, hexs, gelap, bevel, halus=True)


def kerucut(nama, r, tinggi, pos, hexs, rot=(0.0, 0.0, 0.0), gelap=0.72):
    bpy.ops.mesh.primitive_cone_add(vertices=32, radius1=r, radius2=0.0, depth=tinggi,
                                    location=pos, rotation=rot)
    return _tempel(bpy.context.object, nama, hexs, gelap, 0.0, halus=True)


def elips(nama, pos, r, hexs, gelap=0.72, rot=(0.0, 0.0, 0.0)):
    """Elipsoid dengan radius (rx, ry, rz) di sekitar pos."""
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=16, radius=1.0,
                                         location=pos, rotation=rot)
    ob = bpy.context.object
    ob.data.transform(Matrix.Diagonal((r[0], r[1], r[2], 1.0)))
    return _tempel(ob, nama, hexs, gelap, 0.0, halus=True)


def prisma(nama, pts, tebal, sumbu, offset, hexs, gelap=0.72, bevel=0.03):
    """Poligon (u, v) diekstrusi setebal `tebal`.
    sumbu 'Y': (u, v) = (X, Z), tebal di Y. sumbu 'X': (u, v) = (Y, Z), tebal di X.
    offset = pusat tebal pada sumbu ekstrusi."""
    bm = bmesh.new()
    h = tebal / 2.0

    def titik(u, v, d):
        p = (u, offset + d, v) if sumbu == "Y" else (offset + d, u, v)
        return bm.verts.new(p)

    depan = [titik(u, v, -h) for u, v in pts]
    belakang = [titik(u, v, h) for u, v in pts]
    bm.faces.new(depan)
    bm.faces.new(belakang[::-1])
    n = len(pts)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((depan[i], depan[j], belakang[j], belakang[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(nama)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(nama, me)
    bpy.context.collection.objects.link(ob)
    return _tempel(ob, nama, hexs, gelap, bevel, halus=False)


def skala_akar(tinggi):
    """Samakan tinggi model (unit) dengan `tinggi`; semua anak ikut lewat akar."""
    root.scale = (1.0, 1.0, 1.0)
    bpy.context.view_layer.update()
    z = max((ob.matrix_world @ Vector(c)).z for ob in bpy.context.scene.objects
            if ob.type == "MESH" for c in ob.bound_box)
    k = tinggi / z
    root.scale = (k, k, k)
    bpy.context.view_layer.update()


def pusat():
    """Titik target kamera: tengah tinggi seluruh model (sumbu x dan y = 0)."""
    zs = [(ob.matrix_world @ Vector(c)).z for ob in bpy.context.scene.objects
          if ob.type == "MESH" for c in ob.bound_box]
    return Vector((0.0, 0.0, (min(zs) + max(zs)) / 2.0))


# ---------- adegan, garis, kamera, render ----------

def _garis(sc):
    """Garis tepi Freestyle: siluet, crease, dan batas objek yang terlihat, warna biru malam."""
    sc.render.use_freestyle = True
    sc.render.line_thickness_mode = "ABSOLUTE"
    sc.render.line_thickness = TEBAL_GARIS
    vl = sc.view_layers[0]
    vl.use_freestyle = True
    fs = vl.freestyle_settings
    fs.crease_angle = math.radians(50)
    if len(fs.linesets) == 0:
        fs.linesets.new("garis")
    ls = fs.linesets[0]
    ls.select_silhouette = True
    ls.select_border = False
    ls.select_crease = True
    ls.select_external_contour = True
    ls.select_by_visibility = True
    gaya = bpy.data.linestyles.new("garis")
    gaya.color = _rgb(GARIS)[:3]
    gaya.thickness = 1.0                 # pengali; tebal akhir = line_thickness (px)
    gaya.caps = "ROUND"
    ls.linestyle = gaya


def mulai():
    """Scene kosong dan pengaturan render tetap untuk semua sprite toon."""
    global root
    rb.clean()
    _bahan.clear()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPEL
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 0            # tanpa cahaya global: hanya emisi datar
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.color_depth = "8"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.render.resolution_percentage = 100
    sc.render.resolution_x = sc.render.resolution_y = KANVAS
    _garis(sc)
    root = bpy.data.objects.new("akar", None)
    bpy.context.collection.objects.link(root)


def _kamera(sudut, target):
    e = math.radians(SUDUT_DERAJAT[sudut])
    arah = {
        "samping": Vector((0.0, -math.cos(e), math.sin(e))),    # dari sisi -Y, model menghadap +X (kanan)
        "belakang": Vector((-math.cos(e), 0.0, math.sin(e))),   # dari belakang (-X), lebih tinggi
        "depan": Vector((math.cos(e), 0.0, math.sin(e))),       # dari depan (+X)
    }[sudut]
    lokasi = target + arah * JARAK
    data = bpy.data.cameras.new("kamera")
    data.type = "ORTHO"
    data.ortho_scale = KANVAS / PPU
    data.clip_start = 0.1
    data.clip_end = 400.0
    cam = bpy.data.objects.new("kamera", data)
    bpy.context.collection.objects.link(cam)
    cam.location = lokasi
    cam.rotation_euler = (target - lokasi).to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    bpy.context.view_layer.update()
    return cam


def proyeksi(cam, p):
    """Titik dunia -> piksel kanvas (sumbu y ke bawah), dari kamera Blender."""
    x, y, _ = world_to_camera_view(bpy.context.scene, cam, Vector(p))
    return [round(x * KANVAS, 2), round((1.0 - y) * KANVAS, 2)]


def render(nama, sudut, target, anchor=None):
    """Render satu sudut ke out/<nama>.png dan tulis out/<nama>.json (pivot dan anchor dalam piksel)."""
    sc = bpy.context.scene
    cam = _kamera(sudut, target)
    sc.render.filepath = rb.out(nama + ".png")
    bpy.ops.render.render(write_still=True)
    data = {
        "nama": nama,
        "sudut": sudut,
        "kanvas": KANVAS,
        "pivot": proyeksi(cam, (0.0, 0.0, 0.0)),
        "anchors": anchor(lambda p: proyeksi(cam, p)) if anchor else {},
    }
    with open(rb.out(nama + ".json"), "w") as fh:
        json.dump(data, fh, ensure_ascii=False)
    print("TOON", nama, sudut, "pivot", data["pivot"])
    bpy.data.objects.remove(cam, do_unlink=True)
