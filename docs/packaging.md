# Pakning — denniz DroidSpaces

## Resultat

Pakke: `/home/tbn/android/out/droidspaces-denniz/`

- `boot-droidspaces.img` — flashbar boot (header v2, vores `Image` + `mt6893.dtb`, ramdisk fra ManshuTyagi LOS 23.2 `boot.img` 20261004)
- `dtbo-droidspaces.img` — 21 overlays (valgfri; IDs er 0)
- `boot-ref.img` — rollback
- Se `README.md` i pakkemappen for Magisk/fastboot

## Metode

1. `make Image.gz-dtb` (appended findes, men denne LOS-boot bruger **separat** dtb).
2. `magiskboot unpack` på reference-`boot.img`.
3. Erstat `kernel` med `arch/arm64/boot/Image`, `dtb` med `mt6893.dtb`.
4. `magiskboot repack` → `boot-droidspaces.img`.
5. `mkdtboimg.py create` for overlays.

## Verifikation

Efter unpack af `boot-droidspaces.img`: kernel == vores `Image`, dtb == vores `mt6893.dtb`.
