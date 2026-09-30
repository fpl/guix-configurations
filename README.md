# Guix configurations for multiple boxes 

Multiple configurations for both VMs and my true laptops are included here.

## Overview

A collection of standalone Guix System `operating-system` configurations (Guile Scheme), one per machine. There is no build system or test suite.

- `configuration-mithrandir.scm`, `configuration-galadriel.scm`, `configuration-inspire.scm`: real laptops (inspire uses `grub-efi-bootloader`, the others BIOS `grub-bootloader`). `mithrandir` and `inspire` also pull in `(nongnu packages linux)`. All four host configs, and the generated `guix-config.scm`, set `%default-channels` to `guix` (Codeberg), `nonguix` and `guix-science`.
- `configuration-vm-std.scm`: standard VM configuration.
- `guix-config.scm`: **generated** by `make_config_scm.sh`. It is a Vagrant-style VM config (user `vagrant`, passwordless sudo, insecure vagrant SSH key). It gets the same channels, substitute servers and keys as the host configs, applied to `%base-services` as `%my-services`. Change the heredoc in `make_config_scm.sh` rather than editing the output, since `$`, backticks and `\n` are escaped for the shell there.
- `channels.scm`: channel list (nonguix, guix-science plus `%default-channels`) for `guix pull -C`.
- `keys/*.pub`: substitute-server signing keys (nonguix, inria, ladestem), referenced via `(local-file "keys/...")` in the configs. Paths are relative to the config file, so run `guix system` from the repo root. A stray copy of `ladestem-signing-key.pub` sits in the root.

## Common commands

```sh
guix pull -C channels.scm                                   # use nonguix channel
sudo guix system reconfigure configuration-<host>.scm       # apply on a machine
guix system build configuration-<host>.scm                  # dry check that a config evaluates/builds
sudo guix system init guix-config.scm /mnt                  # install onto the mounted disk (VM flow)
```

VM install flow: `create-vdi.sh` (creates a 100G VDI, attaches it via qemu-nbd, partitions, formats, mounts at `/mnt`) then `make_config_scm.sh` (reads the UUIDs of `/dev/nbd0p1` and `/dev/nbd0p2`, downloads the vagrant key and writes `guix-config.scm`). Both scripts use `sudo` and need the `nbd` module.

## Conventions

- All four host configs (`galadriel`, `inspire`, `mithrandir`, `vm-std`) define `%my-services` via `modify-services` on `%desktop-services` (the generated config uses `%base-services`), and use it in `(services ...)`. This adds the substitute URLs (`substitutes.lovergine.com`, nonguix, `guix.bordeaux.inria.fr` which also serves guix-science, hydra-guix-129) and the matching signing keys from `keys/`. `mithrandir` also disables lid-switch handling and GDM auto-suspend. Keep these blocks consistent across host configs, and in `make_config_scm.sh` and `guix-config.scm`, when changing one.
- Timezone is `Europe/Rome`, host configs use locale `it_IT.utf8` and keyboard `it`/`us`; the generated Vagrant VM config uses `en_US.utf8` and `us`/`intl`.
