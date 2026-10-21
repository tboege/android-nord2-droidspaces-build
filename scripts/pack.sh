#!/usr/bin/env bash
# Pack Image + mt6893.dtb into a flashable boot.img (LOS 23.2 / ManshuTyagi layout).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="${KERNEL:-$ROOT/kernel_denniz}"
OUT="${OUT:-$ROOT/out/droidspaces-denniz}"
PACK="${PACK:-$ROOT/out/pack}"
REF_URL="${REF_URL:-https://github.com/ManshuTyagi/releases/releases/download/20261004_lineage/boot.img}"
MAGISK_URL="${MAGISK_URL:-https://github.com/topjohnwu/Magisk/releases/download/v30.7/Magisk-v30.7.apk}"
MKDTBO_URL="${MKDTBO_URL:-https://raw.githubusercontent.com/LineageOS/android_system_libufdt/lineage-21.0/utils/src/mkdtboimg.py}"

IMAGE="$KERNEL/arch/arm64/boot/Image"
DTB="$KERNEL/arch/arm64/boot/dts/mediatek/mt6893.dtb"
DTBDIR="$KERNEL/arch/arm64/boot/dts/mediatek"

OVERLAYS=(
  oplus6893_20827 oplus6893_20827_EVT oplus6893_20171 oplus6893_21061
  oplus6893_21015_v1 oplus6893_21015_v2 oplus6893_20615_v1 oplus6893_20615_v2
  oplus6893_21609 oplus6893_21651 k6893v1_64_k419
  k6893v1_64_k419_dummy0 k6893v1_64_k419_dummy1 k6893v1_64_k419_dummy2
  k6893v1_64_k419_dummy3 k6893v1_64_k419_dummy4 k6893v1_64_k419_dummy5
  k6893v1_64_k419_dummy6 k6893v1_64_k419_dummy7 k6893v1_64_k419_dummy8
  k6893v1_64_k419_dummy9
)

need() { [ -f "$1" ] || { echo "missing: $1 (build kernel first)"; exit 1; }; }
need "$IMAGE"
need "$DTB"

mkdir -p "$PACK" "$OUT"
cd "$PACK"

if [ ! -x ./magiskboot ]; then
  echo "Fetching Magisk for magiskboot..."
  curl -fsSL -o Magisk.apk "$MAGISK_URL"
  python3 - <<'PY'
import zipfile
from pathlib import Path
with zipfile.ZipFile('Magisk.apk') as z:
    data = z.read('lib/x86_64/libmagiskboot.so')
Path('magiskboot').write_bytes(data)
PY
  chmod +x magiskboot
fi

if [ ! -f boot-ref.img ]; then
  echo "Downloading reference boot.img..."
  curl -fL -o boot-ref.img "$REF_URL"
fi

if [ ! -f mkdtboimg.py ]; then
  curl -fsSL -o mkdtboimg.py "$MKDTBO_URL"
fi

rm -rf unpack && mkdir unpack && cd unpack
../magiskboot unpack -h ../boot-ref.img
cp -a "$IMAGE" kernel
cp -a "$DTB" dtb
../magiskboot repack ../boot-ref.img ../boot-droidspaces.img
cd ..

args=()
for o in "${OVERLAYS[@]}"; do
  f="$DTBDIR/${o}.dtbo"
  need "$f"
  args+=("$f")
done
python3 mkdtboimg.py create dtbo-droidspaces.img --page_size=2048 "${args[@]}"

cp -a boot-droidspaces.img dtbo-droidspaces.img boot-ref.img \
  "$IMAGE" "$KERNEL/arch/arm64/boot/Image.gz" "$DTB" \
  "$OUT/"
# optional appended
[ -f "$KERNEL/arch/arm64/boot/Image.gz-dtb" ] && \
  cp -a "$KERNEL/arch/arm64/boot/Image.gz-dtb" "$OUT/"

if [ -f "$ROOT/docs/package-README.md" ]; then
  cp -a "$ROOT/docs/package-README.md" "$OUT/README.md"
fi

(cd "$OUT" && sha256sum boot-droidspaces.img dtbo-droidspaces.img Image.gz mt6893.dtb > SHA256SUMS)
ls -lh "$OUT"
echo "Done: $OUT/boot-droidspaces.img"
