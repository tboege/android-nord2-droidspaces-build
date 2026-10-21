# Denniz DroidSpaces kernel package

Bygget fra `kernel_denniz` (lineage-23.2) med DroidSpaces non-GKI-options.
`boot-droidspaces.img` er pakket med samme layout som ManshuTyagi LineageOS 23.2
(header v2, gzip-kernel, separat `mt6893.dtb`, samme ramdisk/cmdline).

## Filer

| Fil | Brug |
| --- | --- |
| `boot-droidspaces.img` | Flash til `boot` (primær leverance) |
| `boot-ref.img` | Original LOS 23.2 boot (nød-rollback) |
| `dtbo-droidspaces.img` | **Valgfri** — kun hvis du ved, at din ROM forventer nye overlays |
| `Image` / `Image.gz` / `Image.gz-dtb` / `mt6893.dtb` | Rå artefakter |

## Anbefalet flash (fastboot)

1. Boot til fastboot (`adb reboot bootloader` eller Vol− + power).
2. Hav recovery klar (TWRP/LOS).
3. Flash **kun boot** først (lad `dtbo` være den fra din ROM):

```sh
fastboot flash boot boot-droidspaces.img
fastboot reboot
```

4. Hvis den ikke booter: `fastboot flash boot boot-ref.img` og reboot.

## Magisk

Patch **efter** (eller før) flash via Magisk-appen:

1. Kopiér `boot-droidspaces.img` til telefonen.
2. Magisk → Install → Select and Patch a File → vælg imaget.
3. Flash den Magisk-patchede `magisk_patched_*.img` til `boot`.

Patch ikke rå `Image.gz`.

## dtbo

`dtbo-droidspaces.img` er bygget fra kerne-overlay’erne, men entry-`id` er 0
(ikke board-specifikke ID’er fra en fuld Android-device-tree-pack). Flash den
**kun**, hvis du ved, hvad du gør:

```sh
fastboot flash dtbo dtbo-droidspaces.img
```

Ellers behold ROM’ens eksisterende dtbo.

## Risici

- `CONFIG_CFS_BANDWIDTH` / `CONFIG_CGROUP_PIDS` kan få prebuilt Mali (m.m.) til ikke at loade.
- Ramdisk kommer fra ManshuTyagi LOS 23.2 (2026-04). Kører du en anden build, hent dens `boot.img`, erstat kun kernel+dtb med magiskboot, og brug den.

## Om-pak med din egen boot.img

```sh
magiskboot unpack din-boot.img
cp /sti/til/Image kernel
cp /sti/til/mt6893.dtb dtb
magiskboot repack din-boot.img boot-custom.img
```
