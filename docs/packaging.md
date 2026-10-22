# Packaging — denniz DroidSpaces

## Output

Package directory: `out/droidspaces-denniz/` (next to this meta-repo root)

- `boot-droidspaces.img` — flashable boot (header v2, our `Image` +
  `mt6893.dtb`, ramdisk from ManshuTyagi LOS 23.2 `boot.img` 20261004)
- `dtbo-droidspaces.img` — 21 overlays (optional; entry IDs are 0)
- `boot-ref.img` — rollback
- See `README.md` in the package directory for Magisk/fastboot (English)

Or run: `scripts/pack.sh`

## Method

1. `make Image.gz-dtb` (appended image exists, but this LOS boot uses a
   **separate** dtb).
2. `magiskboot unpack` on the reference `boot.img`.
3. Replace `kernel` with `arch/arm64/boot/Image`, `dtb` with `mt6893.dtb`.
4. `magiskboot repack` → `boot-droidspaces.img`.
5. `mkdtboimg.py create` for overlays.

## Verification

After unpacking `boot-droidspaces.img`: kernel == our `Image`, dtb == our
`mt6893.dtb`.
