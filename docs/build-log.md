# Build log — denniz DroidSpaces kernel

Times: `real` from `{ time make …; }` (wall clock). ccache: hits/misses.

KMAKE (from build-02 onward): `LLVM=1 LLVM_IAS=1 CROSS_COMPILE=aarch64-linux-gnu-
CLANG_TRIPLE=aarch64-linux-gnu- CC="ccache clang" HOSTCC="ccache clang" -k
-j$(nproc)`.

| Round | Log | Time (real) | Compile errors | Target | ccache hits/misses | Note |
| --- | --- | --- | --- | --- | --- | --- |
| prep | — | ~13s | — | mrproper + defconfig + fragment | — | Stub `accdet/mt8167` under mrproper. Use `NF_CT_NETLINK` (not `NF_CONNTRACK_NETLINK`). |
| 01 | build-01.log | ~18s | prepare0 | Image.gz dtbs | 63/78 | `unset CROSS_COMPILE` → no `--target` |
| 02 | build-02.log | **18m06.87s** | 165 (45 .c) | Image.gz dtbs | 303/3875 | First real pass; dtb OK |
| mod-01 | mod-01.log | **1m11.26s** | 39 | 23 dirs | 0/261 | `-I$(src)`; 3 Makefiles glued without newline |
| mod-02 | mod-02.log | **0m27.32s** | 13 | 7 dirs | — | ion/adsp/lpm/drm OK |
| mod-03 | mod-03.log | **0m16.61s** | 1 | mdp eccci reviser | — | Only `mdp.c` → `mach/mt_iommu.h` |
| mod-04 | mod-04.log | **0m4.72s** | 0 | mdp/ | — | Clean |
| 03 | build-03.log | **0m49.89s** | 38 | Image.gz dtbs | 314/468 | New MTK dirs; stderr was in `.time` |
| mod-05 | mod-05.log | **0m47.77s** | 35 | 14 dirs | — | tee GUD path; sched/trace `-I$(src)` |
| mod-06 | mod-06.log | **0m23.01s** | 5 | sched/ppm/cam/thermal | — | Wrong `-I…/mach` (double mach/) |
| mod-07 | mod-07.log | **0m7.34s** | 0 | ppm + thermal | — | Clean |
| 04 | build-04.log | **1m25.86s** | 0 | Image.gz dtbs | — | **Success** — Image.gz + dtb + dtbo |
| user_ns | build-user_ns.log | **15m50s** | 0 | Image.gz dtbs | — | `USER_NS`, `-for_droidspaces`, no `-dirty` |

## Result (build-04 / user_ns)

- `arch/arm64/boot/Image.gz` — OK
- `arch/arm64/boot/dts/mediatek/mt6893.dtb` — OK
- Overlay dtbos for `CONFIG_BUILD_ARM64_DTB_OVERLAY_IMAGE_NAMES` — built
- Version: `4.19.325-…-for_droidspaces-…` (not `-dirty`)

## Packaging

See [`packaging.md`](packaging.md). Deliverable:
`out/droidspaces-denniz/boot-droidspaces.img`.

## Important fixes along the way

1. `CROSS_COMPILE=aarch64-linux-gnu-` is required for `--target` (even with `LLVM=1`).
2. Local angled includes: `ccflags-y += -I$(src)` (not sed on `#include`).
3. Subdirs do not inherit parent `ccflags-y` → use `subdir-ccflags-y` or flags in the subdir Makefile.
4. `#include <mach/foo.h>` needs `-I…/include`, not `-I…/include/mach`.
5. Appending to Makefiles: the file must end with a newline (else `echo` glues lines).
6. Timing: `{ time make … > log 2>&1; } 2> timefile` so compiler stderr is not only in `.time`.
