# Denniz DroidSpaces kernel package

Built from `kernel_denniz` (`droidspaces` / LineageOS 23.2) with DroidSpaces
non-GKI options. `boot-droidspaces.img` uses the same layout as ManshuTyagi
LineageOS 23.2 (header v2, gzip kernel, separate `mt6893.dtb`, same
ramdisk/cmdline).

## Files

| File | Use |
| --- | --- |
| `boot-droidspaces.img` | Flash to `boot` (primary deliverable) |
| `boot-ref.img` | Original LOS 23.2 boot (emergency rollback) |
| `dtbo-droidspaces.img` | **Optional** — only if you know your ROM expects new overlays |
| `Image` / `Image.gz` / `Image.gz-dtb` / `mt6893.dtb` | Raw artifacts |

## Recommended flash (fastboot)

1. Boot to fastboot (`adb reboot bootloader` or Vol− + power).
2. Keep a working recovery ready (TWRP/LOS).
3. Flash **boot only** first (leave `dtbo` as shipped by your ROM):

```sh
fastboot flash boot boot-droidspaces.img
fastboot reboot
```

4. If it does not boot: `fastboot flash boot boot-ref.img` and reboot.

## Magisk

Patch after (or before) flashing via the Magisk app:

1. Copy `boot-droidspaces.img` to the phone.
2. Magisk → Install → Select and Patch a File → pick the image.
3. Flash the Magisk-patched `magisk_patched_*.img` to `boot`.

Do not patch raw `Image.gz`.

## dtbo

`dtbo-droidspaces.img` is built from the kernel overlays, but entry `id` values
are 0 (not board-specific IDs from a full Android device-tree pack). Flash it
**only** if you know what you are doing:

```sh
fastboot flash dtbo dtbo-droidspaces.img
```

Otherwise keep the ROM’s existing dtbo.

## Risks

- `CONFIG_CFS_BANDWIDTH` / `CONFIG_CGROUP_PIDS` may prevent prebuilt Mali (and
  similar) from loading.
- The ramdisk comes from ManshuTyagi LOS 23.2 (2026-04). If you run a different
  build, take its `boot.img`, replace only kernel+dtb with magiskboot, and use
  that.

## Repack with your own boot.img

```sh
magiskboot unpack your-boot.img
cp /path/to/Image kernel
cp /path/to/mt6893.dtb dtb
magiskboot repack your-boot.img boot-custom.img
```
