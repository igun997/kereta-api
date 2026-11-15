#!/usr/bin/env bash
# Menarik hasil build rilis dari sandbox instabox ke build/rilis/ lewat SSH, potongan 4 MB,
# tiap potongan diverifikasi sha1 lalu seluruh berkas diverifikasi lagi.
# Dipakai karena `rflutter` dan `instabox pull` memutus transfer berkas besar (HTTPS reset).
#
#   rflutter --no-pull build apk --release --split-per-abi
#   rflutter --no-pull build appbundle --release
#   tools/tarik_rilis.sh                       # semua APK + AAB
#   tools/tarik_rilis.sh app-arm64-v8a-release.apk
set -uo pipefail
BOX="${BOX:-rcargo}"
cd "$(dirname "$0")/.."
OUT=build/rilis
mkdir -p "$OUT"
jalan() { instabox ssh "$BOX" -- "$@" 2>/dev/null </dev/null; }

WS=$(jalan 'ls -d /data/home/.rflutter/ws/kereta-api-*/home/*/FlutterProjects/kereta-api 2>/dev/null | head -1' | tail -1)
[ -n "$WS" ] || { echo "workspace remote tidak ditemukan" >&2; exit 1; }

if [ "$#" -gt 0 ]; then
  BERKAS=("$@")
else
  BERKAS=(app-arm64-v8a-release.apk app-armeabi-v7a-release.apk app-x86_64-release.apk app-release.aab)
fi

for nama in "${BERKAS[@]}"; do
  jalur=$(jalan "find $WS/build/app/outputs -name '$nama' | head -1" | tail -1)
  [ -n "$jalur" ] || { echo "lewati $nama (belum dibangun)"; continue; }
  sha_remote=$(jalan "sha1sum '$jalur' | cut -d' ' -f1" | tail -1)
  jalan "rm -rf /tmp/pp && mkdir /tmp/pp && split -b 4M -d -a 3 '$jalur' /tmp/pp/p_ && cd /tmp/pp && sha1sum p_* > SHA" >/dev/null
  tmp=$(mktemp -d)
  jalan 'cat /tmp/pp/SHA' > "$tmp/SHA"
  while read -r sha p; do
    ok=0
    for coba in 1 2 3 4 5 6; do
      jalan "cat /tmp/pp/$p" > "$tmp/$p"
      if [ "$(sha1sum "$tmp/$p" | cut -d' ' -f1)" = "$sha" ]; then ok=1; break; fi
      sleep 2
    done
    [ "$ok" = 1 ] || { echo "gagal menarik $p" >&2; exit 1; }
  done < "$tmp/SHA"
  cat "$tmp"/p_* > "$OUT/$nama"
  rm -rf "$tmp"
  sha_lokal=$(sha1sum "$OUT/$nama" | cut -d' ' -f1)
  if [ "$sha_lokal" = "$sha_remote" ]; then
    echo "OK  $nama  $(du -h "$OUT/$nama" | cut -f1)  sha1=$sha_lokal"
  else
    echo "SHA1 TIDAK COCOK untuk $nama (remote $sha_remote, lokal $sha_lokal)" >&2
    exit 1
  fi
done
jalan 'rm -rf /tmp/pp' >/dev/null || true
