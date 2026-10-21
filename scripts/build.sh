#!/usr/bin/env bash
# Build denniz Image.gz (+ dtbs / Image.gz-dtb) with DroidSpaces fragment.
# Run from anywhere. Expects: ../kernel_denniz, clang-r547379, ccache.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="${KERNEL:-$ROOT/kernel_denniz}"
CLANG="${CLANG:-$HOME/android/toolchains/clang/clang-r547379/bin}"
DOCS="${DOCS:-$ROOT/docs}"
JOBS="${JOBS:-$(nproc)}"

cd "$KERNEL"
export PATH="$CLANG:$PATH"
export ARCH=arm64
export CCACHE_CPP2=yes
export CCACHE_COMPRESS=true
export CCACHE_BASEDIR="$PWD"
# Required for --target= even with LLVM=1 (linker/objcopy stay llvm-*)
export CROSS_COMPILE=aarch64-linux-gnu-

KMAKE=(
  -k -j"$JOBS"
  LLVM=1 LLVM_IAS=1
  CROSS_COMPILE=aarch64-linux-gnu-
  CLANG_TRIPLE=aarch64-linux-gnu-
  CC="ccache clang"
  HOSTCC="ccache clang"
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [--config-only | --full | --image]
  --config-only  mrproper + mt6893_defconfig + droidspaces.fragment + olddefconfig
  --full         config + Image.gz dtbs (tee to docs/build-full.log)
  --image        Image.gz dtbs Image.gz-dtb only (default; needs existing .config)
EOF
}

do_config() {
  mkdir -p "$DOCS"
  if [ -f .config ]; then
    cp -a .config "$DOCS/config-before-rebuild-$(date +%Y%m%d%H%M%S)" || true
  fi
  # Stub for broken clean path (missing accdet/mt8167)
  if [ ! -f drivers/misc/mediatek/accdet/mt8167/Makefile ]; then
    mkdir -p drivers/misc/mediatek/accdet/mt8167
    printf '# stub for mrproper\n' > drivers/misc/mediatek/accdet/mt8167/Makefile
    STUB=1
  fi
  make mrproper || true
  [ "${STUB:-0}" = 1 ] && rm -rf drivers/misc/mediatek/accdet/mt8167

  make LLVM=1 LLVM_IAS=1 mt6893_defconfig
  scripts/kconfig/merge_config.sh -m .config arch/arm64/configs/droidspaces.fragment
  make LLVM=1 LLVM_IAS=1 olddefconfig
  echo "Config done. NF_CONNTRACK_NETLINK is absent in this tree (expected)."
}

do_image() {
  mkdir -p "$DOCS"
  local log="${DOCS}/build-$(date +%Y%m%d%H%M%S).log"
  echo "Building Image.gz dtbs Image.gz-dtb -> $log"
  { time make "${KMAKE[@]}" Image.gz dtbs Image.gz-dtb >"$log" 2>&1; } 2>"${log%.log}.time"
  cat "${log%.log}.time" | tee -a "$log"
  ls -lh arch/arm64/boot/Image.gz arch/arm64/boot/Image \
    arch/arm64/boot/dts/mediatek/mt6893.dtb \
    arch/arm64/boot/Image.gz-dtb
}

cmd="${1:---image}"
case "$cmd" in
  -h|--help) usage ;;
  --config-only) do_config ;;
  --full) do_config; do_image ;;
  --image) do_image ;;
  *) usage; exit 1 ;;
esac
