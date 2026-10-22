# OnePlus Nord 2 (denniz): LineageOS 23.2 kernel for DroidSpaces

Branch `droidspaces` (based on `lineage-23.2`) in `kernel_denniz`. Kernel is
4.19.325, non-GKI, MediaTek MT6893. Defconfig is
`arch/arm64/configs/mt6893_defconfig` (`CONFIG_MACH_MT6893`, project
`k6893v1_64`). `build.config.cupida` belongs to a Realme kernel and is not used.

Goal: `arch/arm64/boot/Image.gz` plus the DTB/DTBO files already named by
defconfig, with the options DroidSpaces needs on a 4.19 kernel. Packaging and
flash are covered separately.

Options source: [DroidSpaces kernel configuration](https://www.droidspaces.org/docs/kernel-configuration.html), Non-GKI section (3.18–4.19).

ROM context: [LineageOS 23.2 for Nord 2 / Realme X7 Max (XDA)](https://xdaforums.com/t/rom-op6893-lineage-os-23-2-for-oneplus-nord-2-and-realme-x7-max-14-08-2026.4780682/).

Kernel fork: https://github.com/tboege/android_kernel_oplus_mt6893

## Build environment

Built and verified under **WSL2 on Ubuntu 26.04.1 LTS** with Android
**clang-r547379** (clang 20.0.0) and `LLVM=1`. The Makefile fixes
(`-I$(src)` / `subdir-ccflags-y`) address clang 20 include behaviour in this
MTK tree — not WSL itself. The same toolchain on bare-metal Ubuntu should
behave similarly.

## Why `fix_build.sh` is not used

That script patches symptoms in the source tree and then starts a build that
continues after the first error.

- It deletes every `endif` in `drivers/misc/mediatek/vow/Makefile` and appends
  one at the end. The file is unbalanced: `ifeq` blocks for SCP, PCM callback,
  and DSP version lose their `endif`.
- It rewrites `#include <...>` to `"..."` and sprinkles `ccflags-y` across
  drivers. The same header name exists in multiple places (e.g. `sched.h`). A
  global `-I` list (as older `make` invocations in `../history` used) picks the
  wrong file. The script’s include edits are band-aids on top of that list.
- It runs `make -k` once after the sed patches. `-k` is useful to collect
  independent compile errors, but the log must separate real errors from
  cascading ones (missing `.o`, `vmlinux` link). The script does not, and it
  rebuilds the whole kernel after every fix.
- `CROSS_COMPILE=aarch64-linux-android-` points at binutils that are not on
  `PATH`. With `LLVM=1`, linker and objcopy should be the LLVM tools.
- There is no defconfig target and no `Image.gz`. The script uses whatever
  `.config` happens to sit in the tree.
- Clang is pinned to `clang-r547379` (clang 20.0.0) — the right choice here.
  `clang-r614150` is clang 23 and makes the 4.19 tree noisier.
  `build.config.cupida` points at `clang-r383902`, which is not in `toolchains/`.

`git status` once showed 44 modified source files matching the script’s sed
targets (vow, helio-dvfsrc, audio_ipi, trace headers, wlan, sched, ion, mdp,
adsp, reviser, mmc, display). Those are not feature work. Untracked `*.dtbo`,
`dtbimg.cfg`, and `dtboimg.cfg` are build products.

## What stock `.config` already has

Namespaces, seccomp, binder, ext4, loop, FUSE, TUN, veth, bridge, overlayfs,
memcg with swap accounting, cgroup freezer/sched/cpuacct, IPv4 NAT and
masquerade, IPv6 filter and IPv6 mangle.

## What DroidSpaces still needed

Enable these (were off or missing in `.config`):

| Option | DroidSpaces use |
| --- | --- |
| `CONFIG_POSIX_MQUEUE` | IPC in the container |
| `CONFIG_CGROUP_DEVICE` | device cgroup |
| `CONFIG_CGROUP_NET_PRIO` | per-cgroup net priority |
| `CONFIG_CFS_BANDWIDTH` | `--cpus` |
| `CONFIG_CGROUP_PIDS` | `--pids-limit` |
| `CONFIG_DEVTMPFS` | hardware in the container |
| `CONFIG_TMPFS_POSIX_ACL` and `CONFIG_TMPFS_XATTR` | NixOS and similar |
| `CONFIG_NF_TABLES` | nftables in NAT mode |
| `CONFIG_NETFILTER_XT_MATCH_ADDRTYPE` | NAT |
| `CONFIG_NF_CT_NETLINK` | conntrack from userspace (symbol name in this tree) |
| `CONFIG_IP6_NF_NAT` and `CONFIG_IP6_NF_TARGET_MASQUERADE` | IPv6 NAT |
| `CONFIG_MACVLAN` | `--net=macvlan` |
| `CONFIG_USER_NS` | user namespaces |
| `CONFIG_LOCALVERSION="-for_droidspaces"` | version string marker |

`CONFIG_ANDROID_PARANOID_NETWORK` and `CONFIG_FW_LOADER_COMPRESS` do not exist
in this tree — do not force them into `.config`.

`CONFIG_CFS_BANDWIDTH` and `CONFIG_CGROUP_PIDS` change structure sizes. On GKI
that would boot-loop against stock modules. This kernel is non-GKI and modules
are built from the same tree, so both options are included. Mali and other
prebuilt modules not rebuilt here may refuse to load afterward — note at first
boot; it does not block the config step.

Optional UFW/Fail2ban options from DroidSpaces are skipped in the first fragment.

## Turnaround

A full `Image.gz` is one pass. Run it once to fill the object tree and cache,
and again at the end when failing directories are clean. Between those, build
only directories whose source or Makefile changed.

With `LLVM=1`, `Makefile` sets `CC = clang` without `override`, so
`CC="ccache clang"` on the command line wins. Use the same line every call. A
change in `KCFLAGS` or the compiler invalidates the cache for the whole tree.

```sh
export PATH="$HOME/android/toolchains/clang/clang-r547379/bin:$PATH"
export ARCH=arm64
export CCACHE_CPP2=yes
export CCACHE_COMPRESS=true
export CCACHE_BASEDIR="$PWD"
unset CROSS_COMPILE

# MAKEFLAGS is reserved by make itself — use another name.
KMAKE=(
  -k -j"$(nproc)"
  LLVM=1 LLVM_IAS=1
  CROSS_COMPILE=aarch64-linux-gnu-
  CLANG_TRIPLE=aarch64-linux-gnu-
  CC="ccache clang"
  HOSTCC="ccache clang"
)
```

`-k` lets independent `.c` files keep compiling after one fails. `ccache` sits
in front of both kernel and host clang (`HOSTCC`), so `scripts/` / `fixdep`
also hit the cache if a later `mrproper` is needed. Inner rounds do not run
`mrproper`. Objects already built stay.

After a `-k` run, keep lines with `: error:` / `: fatal error:` on a source
file. `*** [vmlinux] Error`, directory `Error 2`, and linker `undefined
reference` are cascading while compile errors remain — do not “fix” those
first. When compile errors are gone, link errors become the real next failures.

Next `make` targets are the directories of the fixed `.c` files, or (if a
Makefile gained `ccflags-y`) those directories:

```sh
make "${KMAKE[@]}" \
  drivers/misc/mediatek/vow/ \
  sound/soc/mediatek/audio_dsp/v2/
```

`dir/` builds that directory and below. `dir/file.o` is useful when one file in
a large directory was fixed (wlan `gen4m` is large enough that it pays off).
Batch several targets in one `make` so kbuild parses once.

A header included by many files is rebuilt for the directories that already
showed errors in the log. The final `Image.gz` pass picks up the rest via `.d`
dependencies. That pass is ccache-heavy for everything if the compiler line is
unchanged, and costs link plus the objects that actually include the header.

## Procedure

No global `KCFLAGS=-I...`. No sed on `#include`. Do not run `fix_build.sh`.

Or use this repo’s scripts:

```sh
../scripts/build.sh --full    # first time
../scripts/build.sh --image   # incremental
../scripts/pack.sh            # -> out/droidspaces-denniz/boot-droidspaces.img
```

### 1. Restore source (if sed/fix_build damage remains)

From `kernel_denniz`, on a clean base before the DroidSpaces commits, restore
any sed-damaged paths, then check out branch `droidspaces`. Untracked dtbo /
`dtb*.cfg` should be removed before `mrproper` so an old overlay is not mistaken
for a new build.

### 2. Clean tree and config

Save the current `.config` beside the tree if needed, then:

```sh
export PATH="$HOME/android/toolchains/clang/clang-r547379/bin:$PATH"
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

make mrproper
make LLVM=1 LLVM_IAS=1 mt6893_defconfig
scripts/kconfig/merge_config.sh -m .config arch/arm64/configs/droidspaces.fragment
make LLVM=1 LLVM_IAS=1 olddefconfig
```

The fragment lives at `arch/arm64/configs/droidspaces.fragment` with the options
above as `=y`. `olddefconfig` may drop symbols Kconfig does not know or enable
dependencies. After the run, compare the fragment to `.config`. A symbol still
`not set` is resolved via `merge_config.sh` / Kconfig deps — not by hand-editing
`.config`.

### 3. One full pass with `-k`

```sh
make "${KMAKE[@]}" Image.gz dtbs 2>&1 | tee ../docs/build-01.log
```

Targets: `Image.gz` and `dtbs`. Defconfig has
`CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE` with `mediatek/mt6893` and overlay names
`oplus6893_*` plus `k6893v1_64_k419`.

### 4. Fix a batch, rebuild only those directories

1. Missing local header: add `ccflags-y` or `subdir-ccflags-y` in the Makefile
   that builds the `.o`. Path is the directory containing the header.
2. `TRACE_INCLUDE_PATH .` is fixed in the header named by the log.
3. Implicit declaration under clang 20: include the header that already has the
   prototype. Prefer that over `KCFLAGS=-Wno-error=...`.
4. Vendor code in `vow`, `helio-dvfsrc`, `audio_ipi`: fix in its own Makefile.
   Do not reintroduce the sed changes as a bulk patch.

Then one call with the affected `dir/` (or `dir/file.o`). Record each round in
`docs/build-log.md`.

### 5. Finished build

Success when all of this holds:

- Last `make Image.gz dtbs` with the same `KMAKE` exits 0.
- `arch/arm64/boot/Image.gz` and `arch/arm64/boot/dts/mediatek/mt6893.dtb` exist.
- Overlay dtbos for `CONFIG_BUILD_ARM64_DTB_OVERLAY_IMAGE_NAMES` are built.
- Version string includes `-for_droidspaces` and is not `-dirty`.

Then package for LineageOS 23.2 (`scripts/pack.sh`). Flash and
`droidspaces check` on device are next — not part of compile.

## Deliberately left out

- `fix_build.sh` and the `KCFLAGS` lists from `../history`.
- `cupida_defconfig` and `gki_defconfig`.
- Clang 23 (`clang-r614150`) until a concrete clang-20 bug is isolated.
- Disabling `CONFIG_MODVERSIONS` to force foreign modules in.
