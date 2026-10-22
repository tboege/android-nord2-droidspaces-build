# Denniz DroidSpaces (LineageOS 23.2)

Meta-repo for docs and scripts. Kernel source and patches live in
`kernel_denniz` (separate git repo, branch `droidspaces`).

Kernel fork: https://github.com/tboege/android_kernel_oplus_mt6893

ROM context: [LineageOS 23.2 for Nord 2 / Realme X7 Max (XDA)](https://xdaforums.com/t/rom-op6893-lineage-os-23-2-for-oneplus-nord-2-and-realme-x7-max-14-08-2026.4780682/)

## Build environment

Verified on **WSL2 / Ubuntu 26.04.1 LTS** with Android
**clang-r547379** (LLVM 20). The DroidSpaces/`Makefile` patches target that
toolchain (include paths under clang 20), not WSL-specific APIs — the same
tree should build on bare-metal Ubuntu with the same clang.

## Quick start

```sh
# In kernel_denniz, on branch droidspaces:
../scripts/build.sh --full          # first time (mrproper + config + Image)
../scripts/build.sh --image         # incremental
../scripts/pack.sh                  # -> out/droidspaces-denniz/boot-droidspaces.img
```

## Docs

- `docs/denniz-droidspaces-kernel.md` — build forløb
- `docs/packaging.md` — boot.img layout
- `docs/build-log.md` — timing / rounds
