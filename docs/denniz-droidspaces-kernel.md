# OnePlus Nord 2 (denniz): kerne til LineageOS 23.2 og DroidSpaces

Gren `droidspaces` (baseret på `lineage-23.2`) i `kernel_denniz`. Kernen er 4.19.325, non-GKI, MediaTek MT6893. Defconfig er `arch/arm64/configs/mt6893_defconfig` (`CONFIG_MACH_MT6893`, projekt `k6893v1_64`). `build.config.cupida` hører til en Realme-kerne og bruges ikke.

Målet er `arch/arm64/boot/Image.gz` plus de DTB/DTBO-filer, defconfig allerede navngiver, med de options DroidSpaces kræver på en 4.19-kerne. Pakning og flash ligger uden for dette forløb.

Kilde til options: [DroidSpaces kernel configuration](https://www.droidspaces.org/docs/kernel-configuration.html), afsnittet Non-GKI (3.18 til 4.19).

ROM-kontekst: [LineageOS 23.2 for Nord 2 / Realme X7 Max (XDA)](https://xdaforums.com/t/rom-op6893-lineage-os-23-2-for-oneplus-nord-2-and-realme-x7-max-14-08-2026.4780682/).

## Build environment

Bygget og verificeret under **WSL2 på Ubuntu 26.04.1 LTS** med Android
**clang-r547379** (clang 20.0.0) og `LLVM=1`. Makefile-rettelserne
(`-I$(src)` / `subdir-ccflags-y`) skyldes clang 20’s include-opførsel i dette
MTK-træ — ikke WSL som sådan. Samme toolchain på almindelig Ubuntu bør
fungere tilsvarende.

## Hvorfor `fix_build.sh` ikke kan bruges

Scriptet retter symptomer i kildeteksten og starter derefter et build, der fortsætter efter den første fejl.

- Det sletter hver `endif` i `drivers/misc/mediatek/vow/Makefile` og sætter én ny på til sidst. Filen er ubalanceret nu: `ifeq` til SCP, PCM-callback og DSP-version mangler deres `endif`.
- Det omskriver `#include <...>` til `"..."` og lægger `ccflags-y` på tværs af drivere. Samme header-navn findes flere steder (for eksempel `sched.h`). En global `-I`-liste, som de tidligere `make`-kald i `../history` brugte, vælger den forkerte fil. Include-rettelserne i scriptet er lapper oven på den liste.
- Scriptet bruger `make -k` som en enkelt kørsel oven på sed-rettelserne. `-k` er nyttigt til at samle uafhængige compile-fejl, men loggen skal deles i rigtige fejl og følgefejl (manglende `.o`, link af `vmlinux`). Det gør scriptet ikke, og det genbygger hele kernen efter hver rettelse.
- `CROSS_COMPILE=aarch64-linux-android-` peger på binutils, der ikke står i `PATH`. Med `LLVM=1` skal linker og objcopy være LLVM-værktøjerne.
- Der er ingen defconfig-target og ingen `Image.gz`. Scriptet bruger den `.config`, der tilfældigvis ligger i træet.
- Clang er fastlåst til `clang-r547379` (clang 20.0.0). Det er det rigtige valg her. `clang-r614150` er clang 23 og gør 4.19-træet mere støjende. `build.config.cupida` peger på `clang-r383902`, som ikke findes i `toolchains/`.

`git status` viser 44 ændrede kildefiler. De matcher scriptets sed-kald (vow, helio-dvfsrc, audio_ipi, trace-headers, wlan, sched, ion, mdp, adsp, reviser, mmc, display). De er ikke feature-arbejde. Usporede `*.dtbo`, `dtbimg.cfg` og `dtboimg.cfg` er byggprodukter.

## Hvad den nuværende `.config` allerede har

Namespaces, seccomp, binder, ext4, loop, FUSE, TUN, veth, bridge, overlayfs, memcg med swap accounting, cgroup freezer/sched/cpuacct, IPv4 NAT og masquerade, IPv6-filter og IPv6-mangle.

## Hvad DroidSpaces stadig mangler

Slå disse til. De er slået fra eller fraværende i `.config`:

| Option | DroidSpaces bruger den til |
| --- | --- |
| `CONFIG_POSIX_MQUEUE` | IPC i containeren |
| `CONFIG_CGROUP_DEVICE` | device-cgroup |
| `CONFIG_CGROUP_NET_PRIO` | net-prioritet pr. cgroup |
| `CONFIG_CFS_BANDWIDTH` | `--cpus` |
| `CONFIG_CGROUP_PIDS` | `--pids-limit` |
| `CONFIG_DEVTMPFS` | hardware i containeren |
| `CONFIG_TMPFS_POSIX_ACL` og `CONFIG_TMPFS_XATTR` | NixOS og tilsvarende |
| `CONFIG_NF_TABLES` | nftables i NAT-mode |
| `CONFIG_NETFILTER_XT_MATCH_ADDRTYPE` | NAT |
| `CONFIG_NF_CONNTRACK_NETLINK` | conntrack fra userspace, hvis symbolet findes |
| `CONFIG_IP6_NF_NAT` og `CONFIG_IP6_NF_TARGET_MASQUERADE` | IPv6-NAT |
| `CONFIG_MACVLAN` | `--net=macvlan` |

`CONFIG_ANDROID_PARANOID_NETWORK` og `CONFIG_FW_LOADER_COMPRESS` findes ikke i dette træ. De skal ikke tvinges ind i `.config`.

`CONFIG_CFS_BANDWIDTH` og `CONFIG_CGROUP_PIDS` ændrer strukturstørrelser. På GKI ville det bootloope mod stock-moduler. Denne kerne er non-GKI, og modulerne bygges fra samme træ, så de to options skal med. Mali og andre prebuilt-moduler, der ikke genbygges her, kan nægte at loade bagefter. Det noteres ved første boot, det blokerer ikke config-trinnet.

UFW/Fail2ban-options fra DroidSpaces er valgfri og tages ikke med i første fragment.

## Turnaround

En fuld `Image.gz` er én tur. Den køres én gang for at fylde objekttræet og cachen, og igen til sidst når de fejlende mapper er rene. Mellem de to ture bygges kun de mapper, hvis kilde eller Makefile blev ændret.

`Makefile` sætter `CC = clang`, når `LLVM=1`. Tildelingen har ikke `override`, så `CC="ccache clang"` på kommandolinjen vinder. Samme linje bruges ved hvert kald. Et skift i `KCFLAGS` eller compiler invaliderer cachen for hele træet.

```sh
export PATH="$HOME/android/toolchains/clang/clang-r547379/bin:$PATH"
export ARCH=arm64
export CCACHE_CPP2=yes
export CCACHE_COMPRESS=true
export CCACHE_BASEDIR="$PWD"
unset CROSS_COMPILE

# Navnet MAKEFLAGS er optaget af make selv. Brug et andet.
KMAKE=(
  -k -j"$(nproc)"
  LLVM=1 LLVM_IAS=1
  CLANG_TRIPLE=aarch64-linux-gnu-
  CC="ccache clang"
  HOSTCC="ccache clang"
)
```

`-k` lader uafhængige `.c`-filer kompilere videre, efter én af dem er fejlet. `ccache` ligger foran både kerne- og host-clang (`HOSTCC`), så `scripts/` og `fixdep` også rammer cachen, hvis et senere `mrproper` bliver nødvendigt. Indre runder kører `mrproper` ikke. Objekter, der allerede er bygget, bliver liggende.

Efter et `-k`-kald beholdes linjer med `: error:` og `: fatal error:` på en kildefil. `*** [vmlinux] Error`, `Error 2` efter en mappe og `undefined reference` fra linkeren er følgefejl, så længe der stadig er compile-fejl. De rettes ikke. Når compile-fejlene er væk, er linkfejl de næste rigtige fejl.

Mål for næste `make` er mapperne for de `.c`-filer, der blev rettet, eller hvis Makefile fik ny `ccflags-y`:

```sh
make "${KMAKE[@]}" \
  drivers/misc/mediatek/vow/ \
  sound/soc/mediatek/audio_dsp/v2/
```

`dir/` bygger den mappe og nedefter. `dir/file.o` bruges, når én fil i en stor mappe blev rettet (wlan `gen4m` er stor nok til at det betaler sig). Flere mål samles i ét `make`, så kbuild kun parses én gang.

En header, som mange filer inkluderer, genbygges for de mapper, loggen allerede viste fejl i. Den afsluttende `Image.gz`-tur tager resten via `.d`-afhængighederne. Den tur er ccache-ramt for alt, hvis compiler-linje er uændret, og koster link plus de objekter, headeren faktisk indgår i.

## Forløb

Ingen global `KCFLAGS=-I...`. Ingen sed på `#include`. `fix_build.sh` køres ikke.

### 1. Gendan kildeteksten

Fra `kernel_denniz`, på `lineage-23.2`:

```sh
git restore \
  block/uxio_first/uxio_first_opt.c \
  drivers/cpuidle/cpuidle-mediatek.c \
  drivers/devfreq/helio-dvfsrc-v3 \
  drivers/gpu/drm/mediatek/mtk_drm_mmp.c \
  drivers/gpu/drm/mediatek/mtk_layer_layout_trace.h \
  drivers/gpu/drm/oplus/oplus_display_common.c \
  drivers/gpu/drm/oplus/oplus_display_common.h \
  drivers/misc/mediatek/adsp/Makefile \
  drivers/misc/mediatek/apusys/reviser/Makefile \
  drivers/misc/mediatek/audio_ipi/common_v2/framework \
  drivers/misc/mediatek/connectivity/wlan/core/gen4m/Makefile \
  drivers/misc/mediatek/eccci/hif/Makefile \
  drivers/misc/mediatek/eccci/hif/modem_cldma_events.h \
  drivers/misc/mediatek/lpm/platform/mtk_lpm_platform.c \
  drivers/misc/mediatek/mdp/Makefile \
  drivers/misc/mediatek/vow/Makefile \
  drivers/mmc/host/mtk-sd-dbg.c \
  drivers/soc/oplus/oplus_criticallog/oplus_criticallog.c \
  drivers/staging/android/mtk_ion/Makefile \
  kernel/sched/extension/tuning.h \
  kernel/sched/stats.h \
  kernel/sched_assist/sched_assist_trace.h \
  kernel/trace/mtk_ftrace.h \
  kernel/trace/trace_mmstat.h \
  sound/soc/mediatek/audio_dsp/v2/mtk-dsp-common.c
```

`fix_build.sh` bliver liggende og køres ikke. Usporede dtbo-filer og `dtb*.cfg` slettes før `mrproper`, så et gammelt overlay ikke ligner et nyt build.

### 2. Rent træ og config

Gem den nuværende `.config` ved siden af træet (`../docs/config-before-droidspaces`), kør derefter:

```sh
export PATH="$HOME/android/toolchains/clang/clang-r547379/bin:$PATH"
export ARCH=arm64
unset CROSS_COMPILE

make mrproper

make LLVM=1 LLVM_IAS=1 mt6893_defconfig
scripts/kconfig/merge_config.sh -m .config arch/arm64/configs/droidspaces.fragment
make LLVM=1 LLVM_IAS=1 olddefconfig
```

Fragmentet lægges i `arch/arm64/configs/droidspaces.fragment` med options fra tabellen ovenfor, alle `=y`. `olddefconfig` må droppe et symbol, Kconfig ikke kender, eller slå afhængigheder til. Efter kørsel sammenlignes fragmentet med `.config`. Et symbol, der stadig er `not set`, løses via `scripts/kconfig/merge_config.sh -n` og Kconfig-afhængigheden, ikke ved at skrive linjen ind i `.config` i hånden.

`Makefile` inkluderer allerede `OplusKernelEnvConfig.mk`, så Oplus-makroerne i `ALLOWED_MCROS` kommer med på et almindeligt `make`. De betingede `OPLUS_FEATURE_SECURE_*` kræver variabler fra Android-bygget og sættes ikke her.

### 3. Én fuld tur med `-k`

```sh
make "${KMAKE[@]}" Image.gz dtbs 2>&1 | tee ../docs/build-01.log
```

Target er `Image.gz` og `dtbs`. Defconfig har `CONFIG_BUILD_ARM64_APPENDED_DTB_IMAGE` med `mediatek/mt6893` og overlay-listen `oplus6893_*` plus `k6893v1_64_k419`.

Loggen tee's til `../docs/build-01.log`. Næste fulde tur bliver `build-02.log` først, når de rettede mapper er rene. Modul-ture tee's til `../docs/mod-01.log`, `mod-02.log`, og så videre.

```sh
grep -E ':[0-9]+:[0-9]+: (fatal )?error:' ../docs/build-01.log
```

Hver unik `.c` noteres med mappe. Følgefejl fra link og `Error 2` udelades.

### 4. Ret en bunke, byg kun de mapper

1. Manglende lokal header: tilføj `ccflags-y` eller `subdir-ccflags-y` i den Makefile, der bygger den pågældende `.o`. Stien er den mappe, headeren ligger i.
2. `TRACE_INCLUDE_PATH .` rettes i den header, loggen navngiver.
3. Implicit declaration under clang 20: inkluder den header, der allerede har prototypen. `KCFLAGS=-Wno-error=implicit-function-declaration` kommer først på, når prototypen ikke findes, og da som en fast del af `KMAKE` fra den runde og frem, så ccache-nøglen ikke skifter frem og tilbage.
4. Vendor-kode i `vow`, `helio-dvfsrc` og `audio_ipi` rettes i sin egen Makefile. De tilbageførte sed-ændringer genindføres ikke som samlet patch.

Derefter ét kald med de berørte `dir/` (eller `dir/file.o` i store mapper). Ny compile-fejl i den log rettes, og samme mål køres igen. En mappe, der er ren, tages af listen.

Hver runde får en linje i `../docs/build-log.md`: logfil, antal compile-fejl, hvilke mapper der blev bygget, og `ccache -s` kort (hits, misses). En fuld `Image.gz`-tur skrives kun, når den køres.

### 5. DroidSpaces-patches

Non-GKI-patches fra DroidSpaces (`assets/resources/kernel-patches/non-GKI` i deres OSS-repo) prøves med `patch -p1 --dry-run` efter config, før de rører træet. En patch, der allerede er i 4.19.325, springes over. En patch, der konflikter, gemmes som afvist i `../docs/` med filnavn og den hunk, der fejlede. GKI-kABI-patches bruges ikke. De er til 5.4 og nyere.

### 6. Færdigt build

Succes er alt dette på én gang:

- Sidste `make Image.gz dtbs` med samme `KMAKE` (stadig `-k` og ccache) slutter med status 0. `-k` ændrer ikke status, når intet fejler.
- `arch/arm64/boot/Image.gz` findes, og `arch/arm64/boot/dts/mediatek/mt6893.dtb` findes.
- Overlay-dtbo for navnene i `CONFIG_BUILD_ARM64_DTB_OVERLAY_IMAGE_NAMES` er bygget.
- `scripts/diffconfig` mod den gemte `.config` viser DroidSpaces-options som tilføjet, og vendor-options fra `mt6893_defconfig` er ikke fjernet.
- `.config` har de symboler, tabellen kræver, og som Kconfig accepterede.

Derefter kan imaget pakkes til LineageOS 23.2 (samme boot-header og dtb-layout som den kørende denniz-build). Flash og `droidspaces check` på telefonen er næste skridt efter pakning, ikke en del af compileringen.

## Hvad dette forløb bevidst lader ligge

- `fix_build.sh` og KCFLAGS-listerne fra `../history`.
- `cupida_defconfig` og `gki_defconfig`.
- Clang 23 (`clang-r614150`), indtil et konkret clang-20-bug er isoleret.
- At slå `CONFIG_MODVERSIONS` fra for at tvinge fremmede moduler ind.
