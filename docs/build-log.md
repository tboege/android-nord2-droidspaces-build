# Build log — denniz DroidSpaces kernel

Tid: `real` fra `{ time make …; }` (wall). ccache: hits/misses.

KMAKE (fra build-02 og frem): `LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu- CLANG_TRIPLE=aarch64-linux-gnu- CC="ccache clang" HOSTCC="ccache clang" -k -j$(nproc)`.

| Runde | Log | Tid (real) | Compile-fejl | Mål | ccache hits/misses | Note |
| --- | --- | --- | --- | --- | --- | --- |
| prep | — | ~13s | — | mrproper + defconfig + fragment | — | Stub `accdet/mt8167` under mrproper. `NF_CONNTRACK_NETLINK` findes ikke. |
| 01 | build-01.log | ~18s | prepare0 | Image.gz dtbs | 63/78 | `unset CROSS_COMPILE` → ingen `--target` |
| 02 | build-02.log | **18m06.87s** | 165 (45 .c) | Image.gz dtbs | 303/3875 | Første rigtige tur; dtb OK |
| mod-01 | mod-01.log | **1m11.26s** | 39 | 23 dirs | 0/261 | `-I$(src)`; 3 Makefiles limet uden newline |
| mod-02 | mod-02.log | **0m27.32s** | 13 | 7 dirs | — | ion/adsp/lpm/drm OK |
| mod-03 | mod-03.log | **0m16.61s** | 1 | mdp eccci reviser | — | Kun `mdp.c` → `mach/mt_iommu.h` |
| mod-04 | mod-04.log | **0m4.72s** | 0 | mdp/ | — | Ren |
| 03 | build-03.log | **0m49.89s** | 38 | Image.gz dtbs | 314/468 | Nye MTK-dirs; stderr lå i `.time` |
| mod-05 | mod-05.log | **0m47.77s** | 35 | 14 dirs | — | tee GUD-sti; sched/trace `-I$(src)` |
| mod-06 | mod-06.log | **0m23.01s** | 5 | sched/ppm/cam/thermal | — | Forkert `-I…/mach` (dobbelt mach/) |
| mod-07 | mod-07.log | **0m7.34s** | 0 | ppm + thermal | — | Ren |
| 04 | build-04.log | **1m25.86s** | 0 | Image.gz dtbs | — | **Succes** — Image.gz + dtb + dtbo |

## Resultat (build-04)

- `arch/arm64/boot/Image.gz` — OK (MAKE_EXIT=0)
- `arch/arm64/boot/dts/mediatek/mt6893.dtb` — OK
- Overlay-dtbo for `CONFIG_BUILD_ARM64_DTB_OVERLAY_IMAGE_NAMES` — bygget
- DroidSpaces-fragment: symboler i `.config` (undtagen `NF_CONNTRACK_NETLINK`, som ikke findes i træet)

## Pakning

Se [`packaging.md`](packaging.md). Leverance: `/home/tbn/android/out/droidspaces-denniz/boot-droidspaces.img`.

## Vigtige rettelser undervejs

1. `CROSS_COMPILE=aarch64-linux-gnu-` kræves for `--target` (selv med LLVM=1).
2. Lokale angled includes: `ccflags-y += -I$(src)` (ikke sed på `#include`).
3. Undermapper arver ikke forældre-`ccflags-y` → brug `subdir-ccflags-y` eller flags i undermappens Makefile.
4. `#include <mach/foo.h>` kræver `-I…/include`, ikke `-I…/include/mach`.
5. Append til Makefiles: filen skal ende med newline (ellers limer `echo` linjerne sammen).
6. Time-log: `{ time make … > log 2>&1; } 2> timefile` så compiler-stderr ikke kun lander i `.time`.
