# Audio Kereta Api

Semua berkas MP3 mono 44,1 kHz (`ffmpeg -c:a libmp3lame -q:a 4`). Durasi diukur dengan ffprobe.

## Suara pemandu (`suara/`)

Suara `id-ID-GadisNeural` (edge-tts), rate -12%, pitch +4Hz. Hening di awal/akhir dipotong, volume dinormalisasi (loudnorm -16 LUFS).

| Berkas | Durasi (s) | Teks |
|---|---|---|
| `suara/halo.mp3` | 4.08 | Halo! Ayo naik kereta bersama Tuut! |
| `suara/ayo_jalan.mp3` | 1.20 | Ayo jalan! |
| `suara/tekan_hijau.mp3` | 3.76 | Tekan tombol hijau, supaya kereta jalan! |
| `suara/tekan_merah.mp3` | 3.66 | Tekan tombol merah, supaya kereta berhenti! |
| `suara/tekan_kuning.mp3` | 3.37 | Tekan tombol kuning, untuk bunyikan peluit! |
| `suara/hebat.mp3` | 0.65 | Hebat! |
| `suara/pintar.mp3` | 1.23 | Pintar sekali! |
| `suara/bagus.mp3` | 0.89 | Bagus! |
| `suara/yeay.mp3` | 0.99 | Yeay! |
| `suara/coba_lagi.mp3` | 1.20 | Coba lagi ya! |
| `suara/satu.mp3` | 0.86 | Satu |
| `suara/dua.mp3` | 0.71 | Dua |
| `suara/tiga.mp3` | 0.63 | Tiga |
| `suara/merah.mp3` | 0.71 | Merah |
| `suara/kuning.mp3` | 0.65 | Kuning |
| `suara/biru.mp3` | 0.68 | Biru |
| `suara/hijau.mp3` | 0.71 | Hijau |
| `suara/bulat.mp3` | 0.57 | Bulat |
| `suara/bintang.mp3` | 0.81 | Bintang |
| `suara/kotak.mp3` | 0.55 | Kotak |
| `suara/segitiga.mp3` | 1.15 | Segitiga |
| `suara/ayam.mp3` | 0.68 | Ayam |
| `suara/kucing.mp3` | 0.68 | Kucing |
| `suara/bebek.mp3` | 0.60 | Bebek |
| `suara/kerbau.mp3` | 0.68 | Kerbau |
| `suara/kelinci.mp3` | 0.84 | Kelinci |
| `suara/monyet.mp3` | 0.63 | Monyet |
| `suara/apel.mp3` | 0.68 | Apel |
| `suara/pisang.mp3` | 0.65 | Pisang |
| `suara/jeruk.mp3` | 0.57 | Jeruk |
| `suara/blueberry.mp3` | 0.89 | Blueberry |
| `suara/stasiun.mp3` | 3.84 | Stasiun! Tekan tombol merah ya! |
| `suara/tuut_tuut.mp3` | 0.76 | Tuut tuut! |
| `suara/misi1.mp3` | 1.83 | Ayo jemput teman-teman! |
| `suara/misi2.mp3` | 3.06 | Masukkan buah ke gerbong yang warnanya sama! |
| `suara/misi3.mp3` | 4.28 | Ada hewan di rel! Ayo bunyikan peluit! |
| `suara/misi4.mp3` | 4.08 | Gelap sekali! Ayo nyalakan lampunya! |
| `suara/misi5.mp3` | 2.87 | Cocokkan bentuknya ke lubang jembatan! |
| `suara/misi6.mp3` | 2.82 | Antar paket ke rumah yang warnanya sama! |
| `suara/misi_selesai.mp3` | 5.67 | Hebat! Misi selesai! Kamu dapat stiker! |
| `suara/istirahat.mp3` | 4.86 | Yuk, istirahat dulu ya! Sampai jumpa! |
| `suara/pilih_jalan.mp3` | 1.96 | Mau lewat jalan yang mana? |

## Efek suara (`sfx/`)

Sintesis numpy, puncak -9 dBFS.

| Berkas | Durasi (s) | Keterangan |
|---|---|---|
| `sfx/peluit.mp3` | 0.99 | Peluit uap, dua nada naik (±0,95 s). |
| `sfx/rem.mp3` | 0.84 | Desis lembut saat rem (0,8 s). |
| `sfx/chug.mp3` | 0.16 | Satu ketukan "cuk" pendek, dipicu kode sesuai kecepatan (0,12 s). |
| `sfx/ding.mp3` | 1.04 | Denting lonceng lembut (1 s). |
| `sfx/pop.mp3` | 0.18 | Pop gelembung kecil (0,15 s). |
| `sfx/boing.mp3` | 0.60 | Boing naik saat hewan masuk (0,55 s). |
| `sfx/bintang.mp3` | 0.99 | Kilau naik empat nada (0,95 s). |
| `sfx/tap.mp3` | 0.10 | Klik lembut saat tap (0,06 s). |
| `sfx/selesai.mp3` | 2.25 | Fanfare riang misi selesai (2,2 s). |
| `sfx/salah.mp3` | 0.55 | Nada turun lembut dan ramah (0,5 s). |
| `sfx/lampu.mp3` | 0.73 | Klik saklar dan dengung lampu (0,7 s). |
| `sfx/kunang.mp3` | 0.94 | Nada tinggi lembut berkelip, kunang-kunang (0,9 s). |
| `sfx/klak_wesel.mp3` | 0.63 | Tok-tok kayu saat wesel bergerak (0,6 s). |

## Musik latar (`musik/`)

Loop periodik: nada yang melewati akhir dibungkus ke awal, sehingga sambungan mulus. Loudness -18 LUFS (ebur128), puncak di bawah -1 dBFS.

| Berkas | Durasi (s) | Keterangan |
|---|---|---|
| `musik/menu.mp3` | 38.43 | Riang pelan 100 bpm, pentatonik C mayor, marimba lembut + bass. |
| `musik/main.mp3` | 48.04 | Ritme kereta ringan 110 bpm, ketukan lembut tiap seperempat + marimba. |
