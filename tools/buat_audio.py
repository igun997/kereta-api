#!/usr/bin/env python3
"""Pembuat audio Kereta Api: suara pemandu (edge-tts), efek suara dan musik (sintesis numpy), daftar.

Pemakaian (dari root proyek):
  python3 tools/buat_audio.py suara    # id-ID-GadisNeural -> assets/audio/suara/*.mp3
  python3 tools/buat_audio.py sfx      # efek suara       -> assets/audio/sfx/*.mp3
  python3 tools/buat_audio.py musik    # musik loop       -> assets/audio/musik/*.mp3
  python3 tools/buat_audio.py daftar   # tulis assets/audio/daftar.md (durasi dari ffprobe)
  python3 tools/buat_audio.py semua

Catatan:
- edge-tts memakai biner dari env EDGE_TTS (default: edge-tts di PATH). Versi 7.2.x sering
  ditolak (403); versi 7.3.x berfungsi.
- Semua keluaran: MP3 mono 44,1 kHz, ffmpeg -c:a libmp3lame -q:a 4.
- SFX: puncak dinormalisasi ke -9 dBFS (aman di bawah -6 dBFS).
- Musik: loudness diukur ffmpeg ebur128 lalu diset ke -18 LUFS dengan gain linear.
  Loop dibangun secara periodik (tidak dipotong): ekor nada yang melewati akhir dibungkus
  ke awal, sehingga sambungan loop tidak punya lompatan.
"""
import argparse
import concurrent.futures as cf
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import time
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parent.parent
AUDIO = ROOT / "assets" / "audio"
SR = 44100
SUARA_VOICE = "id-ID-GadisNeural"
EDGE_TTS = os.environ.get("EDGE_TTS", "edge-tts")
PARALEL = 4

SUARA = [
    ("halo", "Halo! Ayo naik kereta bersama Tuut!"),
    ("ayo_jalan", "Ayo jalan!"),
    ("tekan_hijau", "Tekan tombol hijau, supaya kereta jalan!"),
    ("tekan_merah", "Tekan tombol merah, supaya kereta berhenti!"),
    ("tekan_kuning", "Tekan tombol kuning, untuk bunyikan peluit!"),
    ("hebat", "Hebat!"),
    ("pintar", "Pintar sekali!"),
    ("bagus", "Bagus!"),
    ("yeay", "Yeay!"),
    ("coba_lagi", "Coba lagi ya!"),
    ("satu", "Satu"),
    ("dua", "Dua"),
    ("tiga", "Tiga"),
    ("merah", "Merah"),
    ("kuning", "Kuning"),
    ("biru", "Biru"),
    ("hijau", "Hijau"),
    ("bulat", "Bulat"),
    ("bintang", "Bintang"),
    ("kotak", "Kotak"),
    ("segitiga", "Segitiga"),
    ("ayam", "Ayam"),
    ("kucing", "Kucing"),
    ("bebek", "Bebek"),
    ("kerbau", "Kerbau"),
    ("kelinci", "Kelinci"),
    ("monyet", "Monyet"),
    ("apel", "Apel"),
    ("pisang", "Pisang"),
    ("jeruk", "Jeruk"),
    ("blueberry", "Blueberry"),
    ("stasiun", "Stasiun! Tekan tombol merah ya!"),
    ("tuut_tuut", "Tuut tuut!"),
    ("misi1", "Ayo jemput teman-teman!"),
    ("misi2", "Masukkan buah ke gerbong yang warnanya sama!"),
    ("misi3", "Ada hewan di rel! Ayo bunyikan peluit!"),
    ("misi4", "Gelap sekali! Ayo nyalakan lampunya!"),
    ("misi5", "Cocokkan bentuknya ke lubang jembatan!"),
    ("misi6", "Antar paket ke rumah yang warnanya sama!"),
    ("misi_selesai", "Hebat! Misi selesai! Kamu dapat stiker!"),
    ("istirahat", "Yuk, istirahat dulu ya! Sampai jumpa!"),
    ("pilih_jalan", "Mau lewat jalan yang mana?"),
]

# ---------------------------------------------------------------- utilitas umum


def ffmpeg_mp3(masuk, keluar, filter_af=None):
    keluar.parent.mkdir(parents=True, exist_ok=True)
    cmd = ["ffmpeg", "-y", "-v", "error", "-i", str(masuk)]
    if filter_af:
        cmd += ["-af", filter_af]
    cmd += ["-ac", "1", "-ar", "44100", "-c:a", "libmp3lame", "-q:a", "4", str(keluar)]
    subprocess.run(cmd, check=True)


def tulis_wav(path, x):
    pcm = (np.clip(x, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def durasi(path):
    r = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "default=nw=1:nk=1", str(path)],
        capture_output=True, text=True, check=True,
    )
    return float(r.stdout.strip())


def ukur_lufs(wav_path):
    r = subprocess.run(
        ["ffmpeg", "-nostats", "-i", str(wav_path), "-af", "ebur128=peak=true", "-f", "null", "-"],
        capture_output=True, text=True,
    )
    nilai = re.findall(r"I:\s+(-?\d+(?:\.\d+)?) LUFS", r.stderr)
    return float(nilai[-1])


# ---------------------------------------------------------------- suara pemandu


def suara_satu(nama, teks):
    keluar = AUDIO / "suara" / f"{nama}.mp3"
    with tempfile.TemporaryDirectory() as tmp:
        raw = pathlib.Path(tmp) / f"{nama}.mp3"
        for coba in range(4):
            r = subprocess.run(
                [EDGE_TTS, "--voice", SUARA_VOICE, "--rate=-12%", "--pitch=+4Hz",
                 "--text", teks, "--write-media", str(raw)],
                capture_output=True, text=True, timeout=180,
            )
            if r.returncode == 0 and raw.exists() and raw.stat().st_size > 1000:
                break
            time.sleep(2 * (coba + 1))
        else:
            raise RuntimeError(f"edge-tts gagal untuk {nama}: {r.stderr.strip()[-200:]}")
        filt = (
            "silenceremove=start_periods=1:start_threshold=-42dB:start_silence=0.03,"
            "areverse,silenceremove=start_periods=1:start_threshold=-42dB:start_silence=0.03,areverse,"
            "loudnorm=I=-16:TP=-1.5:LRA=7"
        )
        ffmpeg_mp3(raw, keluar, filt)
    return nama, durasi(keluar)


def cmd_suara():
    with cf.ThreadPoolExecutor(max_workers=PARALEL) as ex:
        futs = [ex.submit(suara_satu, n, t) for n, t in SUARA]
        for f in cf.as_completed(futs):
            nama, d = f.result()
            print(f"suara {nama}: {d:.2f}s", flush=True)


# ---------------------------------------------------------------- sintesis dasar


def _t(d):
    return np.arange(int(round(d * SR))) / SR


def _amp(n, serang, lepas):
    e = np.ones(n)
    a = min(n, int(serang * SR))
    r = min(n, int(lepas * SR))
    if a:
        e[:a] = np.linspace(0.0, 1.0, a)
    if r:
        e[n - r:] *= np.linspace(1.0, 0.0, r)
    return e


def _lowpass(x, k):
    """Low-pass FIR sederhana (rata-rata bergerak)."""
    return np.convolve(x, np.ones(k) / k, mode="same")


def _derau(n, seed):
    return np.random.default_rng(seed).standard_normal(n)


def _taruh(buf, x, mulai_s, bungkus=False):
    i0 = int(round(mulai_s * SR))
    n = len(x)
    if bungkus:
        idx = (i0 + np.arange(n)) % len(buf)
        buf[idx] += x
    elif i0 < len(buf):
        end = min(len(buf), i0 + n)
        buf[i0:end] += x[: end - i0]


def _normal(x, puncak_db=-9.0):
    m = np.max(np.abs(x))
    return x * (10 ** (puncak_db / 20) / m) if m > 0 else x


def _midi(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


def _marimba(f, ekor=1.2):
    n = int(ekor * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * f * t) * np.exp(-t * 6.0)
         + 0.25 * np.sin(2 * np.pi * 4.0 * f * t) * np.exp(-t * 22.0)
         + 0.08 * np.sin(2 * np.pi * 9.9 * f * t) * np.exp(-t * 40.0))
    return x * _amp(n, 0.008, ekor * 0.5)


def _sub(f, ekor=1.0):
    n = int(ekor * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.18 * np.sin(2 * np.pi * 2 * f * t)
    return x * np.exp(-t * 2.2) * _amp(n, 0.02, ekor * 0.4)


def _chug(vol=1.0):
    n = int(0.12 * SR)
    t = np.arange(n) / SR
    f = 150.0 * np.exp(-t * 14.0) + 70.0
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * np.exp(-t * 26.0) + 0.06 * _lowpass(_derau(n, 9), 6) * np.exp(-t * 60.0)
    return vol * x * _amp(n, 0.002, 0.03)


# ---------------------------------------------------------------- efek suara (SFX)


def sfx_peluit():
    n = int(0.95 * SR)
    t = np.arange(n) / SR
    f = np.where(t < 0.45, 700.0 + 40.0 * t / 0.45, 900.0 + 30.0 * (t - 0.45) / 0.5)
    f = f * (1.0 + 0.008 * np.sin(2 * np.pi * 5.0 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    nada = np.sin(ph) + 0.22 * np.sin(2 * ph)
    napas = _lowpass(_derau(n, 1), 12) * 0.5
    return (0.75 * nada + 0.25 * napas) * _amp(n, 0.05, 0.14)


def sfx_rem():
    n = int(0.8 * SR)
    t = np.arange(n) / SR
    desis = _lowpass(_derau(n, 2), 25) * 4.0
    nada = 0.25 * np.sin(2 * np.pi * (420.0 - 120.0 * t / 0.8) * t)
    return (desis + nada) * _amp(n, 0.08, 0.45)


def sfx_chug():
    return _chug(1.0)


def sfx_ding():
    n = int(1.0 * SR)
    t = np.arange(n) / SR
    x = (np.sin(2 * np.pi * 1318.5 * t) * np.exp(-t * 5.0)
         + 0.3 * np.sin(2 * np.pi * 2637.0 * t) * np.exp(-t * 9.0)
         + 0.1 * np.sin(2 * np.pi * 3960.0 * t) * np.exp(-t * 14.0))
    return x * _amp(n, 0.003, 0.2)


def sfx_pop():
    n = int(0.15 * SR)
    t = np.arange(n) / SR
    f = 320.0 + 700.0 * np.clip(t / 0.12, 0, 1)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 22.0) * _amp(n, 0.002, 0.02)


def sfx_boing():
    n = int(0.55 * SR)
    t = np.arange(n) / SR
    f = (260.0 + 620.0 * (1 - np.exp(-t * 9.0))) * (1.0 + 0.04 * np.sin(2 * np.pi * 14.0 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.exp(-t * 4.0) * _amp(n, 0.01, 0.12)


def sfx_bintang():
    total = int(0.95 * SR)
    buf = np.zeros(total)
    for f, mulai in [(1046.5, 0.0), (1318.5, 0.09), (1568.0, 0.18), (2093.0, 0.27)]:
        n = int(0.6 * SR)
        t = np.arange(n) / SR
        x = (np.sin(2 * np.pi * f * t) + 0.2 * np.sin(2 * np.pi * 2 * f * t)) * np.exp(-t * 9.0)
        _taruh(buf, x * _amp(n, 0.004, 0.2), mulai)
    return buf


def sfx_tap():
    n = int(0.06 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 1100.0 * t) * np.exp(-t * 90.0) + 0.2 * _derau(n, 3) * np.exp(-t * 150.0)
    return x * _amp(n, 0.0005, 0.01)


def sfx_selesai():
    buf = np.zeros(int(2.2 * SR))
    nada = [(523.25, 0.0), (659.25, 0.2), (783.99, 0.4), (1046.5, 0.6)]
    for f, mulai in nada:
        _taruh(buf, _marimba(f, 0.6) * 0.8, mulai)
    for f in (1046.5, 1318.5, 1568.0):
        _taruh(buf, _marimba(f, 1.4) * 0.6, 1.0)
    return buf


def sfx_salah():
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    f = 420.0 - 90.0 * t / 0.5
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) + 0.12 * np.sin(3 * ph)
    return x * _amp(n, 0.02, 0.22)


def sfx_lampu():
    n = int(0.7 * SR)
    t = np.arange(n) / SR
    klik = _derau(n, 4) * np.exp(-t * 300.0) * 0.8
    dengung = (0.4 * np.sin(2 * np.pi * 110.0 * t) + 0.2 * np.sin(2 * np.pi * 220.0 * t)
               + 0.1 * np.sin(2 * np.pi * 330.0 * t))
    return (klik + dengung * _amp(n, 0.15, 0.25))


def sfx_kunang():
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 2093.0 * t) * (0.6 + 0.4 * np.sin(2 * np.pi * 6.0 * t))
    return x * _amp(n, 0.12, 0.4)


def sfx_klak_wesel():
    total = int(0.6 * SR)
    buf = np.zeros(total)
    for f, mulai, seed in [(900.0, 0.0, 5), (760.0, 0.22, 6)]:
        n = int(0.2 * SR)
        t = np.arange(n) / SR
        x = np.sin(2 * np.pi * f * t) * np.exp(-t * 35.0) + 0.5 * _lowpass(_derau(n, seed), 4) * np.exp(-t * 120.0)
        _taruh(buf, x, mulai)
    return buf


SFX = {
    "peluit": (sfx_peluit, "Peluit uap, dua nada naik (±0,95 s)."),
    "rem": (sfx_rem, "Desis lembut saat rem (0,8 s)."),
    "chug": (sfx_chug, "Satu ketukan \"cuk\" pendek, dipicu kode sesuai kecepatan (0,12 s)."),
    "ding": (sfx_ding, "Denting lonceng lembut (1 s)."),
    "pop": (sfx_pop, "Pop gelembung kecil (0,15 s)."),
    "boing": (sfx_boing, "Boing naik saat hewan masuk (0,55 s)."),
    "bintang": (sfx_bintang, "Kilau naik empat nada (0,95 s)."),
    "tap": (sfx_tap, "Klik lembut saat tap (0,06 s)."),
    "selesai": (sfx_selesai, "Fanfare riang misi selesai (2,2 s)."),
    "salah": (sfx_salah, "Nada turun lembut dan ramah (0,5 s)."),
    "lampu": (sfx_lampu, "Klik saklar dan dengung lampu (0,7 s)."),
    "kunang": (sfx_kunang, "Nada tinggi lembut berkelip, kunang-kunang (0,9 s)."),
    "klak_wesel": (sfx_klak_wesel, "Tok-tok kayu saat wesel bergerak (0,6 s)."),
}


def cmd_sfx():
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="kereta_sfx_"))
    for nama, (fn, _) in SFX.items():
        x = _normal(np.asarray(fn(), dtype=np.float64), -9.0)
        wav = tmp / f"{nama}.wav"
        tulis_wav(wav, x)
        ffmpeg_mp3(wav, AUDIO / "sfx" / f"{nama}.mp3")
        print("sfx", nama, f"{durasi(AUDIO / 'sfx' / (nama + '.mp3')):.2f}s", flush=True)


# ---------------------------------------------------------------- musik loop

PENTA_C = (0, 2, 4, 7, 9)
MUSIK_CFG = {
    "menu": dict(bpm=100, bar=16, seed=11, akar=[48, 45, 41, 43], pusat=74),
    "main": dict(bpm=110, bar=22, seed=23, akar=[48, 43, 45, 41], pusat=72),
}


def _jalur_lead(seed, panjang, pusat=74):
    """Jalan acak di atas pentatonik C mayor, rentang ±1 oktaf dari pusat (MIDI)."""
    rng = np.random.default_rng(seed)
    kandidat = [m for m in range(pusat - 12, pusat + 13) if m % 12 in PENTA_C]
    idx = kandidat.index(min(kandidat, key=lambda m: abs(m - pusat)))
    hasil = []
    for _ in range(panjang):
        if rng.random() < 0.22:
            hasil.append(None)
            continue
        langkah = [-2, -1, 1, 2][rng.integers(0, 4)]
        idx = int(np.clip(idx + langkah, 0, len(kandidat) - 1))
        hasil.append(kandidat[idx])
    return hasil


def render_musik(nama):
    cfg = MUSIK_CFG[nama]
    bpm = cfg["bpm"]
    beat = 60.0 / bpm
    bar_s = 4 * beat
    total_bar = cfg["bar"]
    N = int(round(total_bar * bar_s * SR))
    buf = np.zeros(N)

    # lead: 8 nada per bar (ketukan delapan)
    langkah8 = beat / 2
    lead = _jalur_lead(cfg["seed"], total_bar * 8, pusat=cfg["pusat"])
    for i, m in enumerate(lead):
        if m is None:
            continue
        _taruh(buf, _marimba(_midi(m), 1.0) * 0.32, i * langkah8, bungkus=True)

    # bass: akar akor di ketukan 1 dan 3 setiap bar
    for b in range(total_bar):
        akar = cfg["akar"][b % len(cfg["akar"])]
        for k in (0, 2):
            _taruh(buf, _sub(_midi(akar), 1.4) * 0.45, b * bar_s + k * beat, bungkus=True)

    if nama == "main":
        # ritme kereta: ketukan ringan setiap seperempat
        for ketuk in range(total_bar * 4):
            _taruh(buf, _chug(0.28), ketuk * beat, bungkus=True)

    return buf


def ffmpeg_loop_mp3(x, nama):
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="kereta_musik_"))
    wav = tmp / f"{nama}.wav"
    tulis_wav(wav, x)
    lufs = ukur_lufs(wav)
    gain = 10 ** ((-18.0 - lufs) / 20.0)
    x2 = x * gain
    puncak = np.max(np.abs(x2))
    if puncak > 10 ** (-1.0 / 20):
        x2 = x2 * (10 ** (-1.0 / 20) / puncak)
    tulis_wav(wav, x2)
    ffmpeg_mp3(wav, AUDIO / "musik" / f"{nama}.mp3")
    return lufs, 20 * np.log10(np.max(np.abs(x2)) + 1e-12)


def cmd_musik():
    for nama in MUSIK_CFG:
        x = render_musik(nama)
        lufs, puncak_db = ffmpeg_loop_mp3(x, nama)
        d = durasi(AUDIO / "musik" / f"{nama}.mp3")
        print(f"musik {nama}: {d:.2f}s, awal {lufs:.1f} LUFS, puncak {puncak_db:.1f} dBFS", flush=True)


# ---------------------------------------------------------------- daftar


def cmd_daftar():
    def baris(folder, nama, ket):
        p = AUDIO / folder / f"{nama}.mp3"
        return f"| `{folder}/{nama}.mp3` | {durasi(p):.2f} | {ket} |"

    tulis = [
        "# Audio Kereta Api",
        "",
        "Semua berkas MP3 mono 44,1 kHz (`ffmpeg -c:a libmp3lame -q:a 4`). Durasi diukur dengan ffprobe.",
        "",
        "## Suara pemandu (`suara/`)",
        "",
        "Suara `id-ID-GadisNeural` (edge-tts), rate -12%, pitch +4Hz. Hening di awal/akhir dipotong, volume dinormalisasi (loudnorm -16 LUFS).",
        "",
        "| Berkas | Durasi (s) | Teks |",
        "|---|---|---|",
    ]
    tulis += [baris("suara", n, t) for n, t in SUARA]
    tulis += ["", "## Efek suara (`sfx/`)", "", "Sintesis numpy, puncak -9 dBFS.", "",
              "| Berkas | Durasi (s) | Keterangan |", "|---|---|---|"]
    tulis += [baris("sfx", n, ket) for n, (_, ket) in SFX.items()]
    tulis += ["", "## Musik latar (`musik/`)", "",
              "Loop periodik: nada yang melewati akhir dibungkus ke awal, sehingga sambungan mulus. "
              "Loudness -18 LUFS (ebur128), puncak di bawah -1 dBFS.", "",
              "| Berkas | Durasi (s) | Keterangan |", "|---|---|---|",
              baris("musik", "menu", "Riang pelan 100 bpm, pentatonik C mayor, marimba lembut + bass."),
              baris("musik", "main", "Ritme kereta ringan 110 bpm, ketukan lembut tiap seperempat + marimba."),
              ""]
    (AUDIO / "daftar.md").write_text("\n".join(tulis), encoding="utf-8")
    print("wrote", AUDIO / "daftar.md")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("perintah", choices=["suara", "sfx", "musik", "daftar", "semua"])
    a = ap.parse_args()
    if a.perintah in ("suara", "semua"):
        cmd_suara()
    if a.perintah in ("sfx", "semua"):
        cmd_sfx()
    if a.perintah in ("musik", "semua"):
        cmd_musik()
    if a.perintah in ("daftar", "semua"):
        cmd_daftar()


if __name__ == "__main__":
    main()
