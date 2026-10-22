# android-nord2-droidspaces-build

Build **docs and scripts** for the OnePlus Nord 2 (denniz) LineageOS 23.2
kernel with [DroidSpaces](https://www.droidspaces.org/) options.

Kernel source and patches:
[tboege/android_kernel_oplus_mt6893](https://github.com/tboege/android_kernel_oplus_mt6893)
(branch `droidspaces`).

ROM context: [LineageOS 23.2 for Nord 2 / Realme X7 Max (XDA)](https://xdaforums.com/t/rom-op6893-lineage-os-23-2-for-oneplus-nord-2-and-realme-x7-max-14-08-2026.4780682/).

Prebuilt boot images belong in **Releases** on the kernel fork, not in this
repo.

## Build environment

Verified on **WSL2 / Ubuntu 26.04.1 LTS** with Android **clang-r547379**
(LLVM 20). Makefile patches target that toolchain’s include behaviour on this
MediaTek 4.19 tree, not WSL-specific APIs.

## Layout

```text
scripts/build.sh   # config + Image.gz
scripts/pack.sh    # boot-droidspaces.img (+ optional dtbo)
docs/              # English build / packaging notes
```

Expect sibling directories (not in this git repo):

- `kernel_denniz/` — kernel checkout
- `toolchains/clang/clang-r547379/` — Android clang
- `out/droidspaces-denniz/` — pack output

## Quick start

```sh
# With kernel_denniz on branch droidspaces next to this repo:
./scripts/build.sh --full          # first time (mrproper + config + Image)
./scripts/build.sh --image         # incremental
./scripts/pack.sh                  # -> out/droidspaces-denniz/boot-droidspaces.img
```

## Docs

- [`docs/denniz-droidspaces-kernel.md`](docs/denniz-droidspaces-kernel.md) — build flow
- [`docs/packaging.md`](docs/packaging.md) — boot.img layout
- [`docs/build-log.md`](docs/build-log.md) — timing / rounds
- [`docs/package-README.md`](docs/package-README.md) — flash/Magisk text shipped with releases
