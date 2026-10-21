# Denniz DroidSpaces (LineageOS 23.2)

Meta-repo for docs and scripts. Kernel source and patches live in
`kernel_denniz` (separate git repo, branch `droidspaces`).

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
