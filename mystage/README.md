# mystage

Replaces pi-gen's `stage2` (Raspberry Pi OS Lite). Lite means "no desktop", not
"minimal" — it ships a C toolchain, a GPIO/Python stack, Bluetooth, a camera
stack and mkvtoolnix on a headless image. This stage keeps only what boots,
resizes, SSHes, and networks.

`config` sets `STAGE_LIST="stage0 stage1 mystage"`, and `../build` copies this
directory into `pi-gen/` before invoking the build (the Dockerfile does
`COPY . /pi-gen/`, so an external stage would not exist inside the container).

## Package choices

Removals use apt's trailing-`-` idiom, the same trick upstream uses for
`modemmanager-`. They run here rather than in `stage0` so the submodule stays
untouched and bumpable.

| Package | Why |
| --- | --- |
| `linux-image-rpi-2712-` | Pi 5 kernel. Target is a Pi 3/4 (`rpi-v8`). |
| `linux-headers-rpi-{v8,2712}-` | Only needed to build out-of-tree modules on-device. |
| `vim-tiny-` | Arrives via debootstrap's priority-important set, not a package list. |
| `ssh-import-id-` | A `Recommends` of `raspberrypi-sys-mods`, so it returns unless removed. |

All four kernel/header removals were checked with `apt-cache rdepends` against
the real `archive.raspberrypi.com` trixie/arm64 repo: no reverse dependencies,
so nothing cascades.

Kept despite looking cuttable:

- `raspberrypi-sys-mods` — ships `/usr/lib/systemd/system/rpi-resize.service`,
  which `00-sys-tweaks/01-run.sh` enables. Nothing in the pi-gen tree ships it.
  Without this the rootfs never expands past ~3 GB. Note the unit is only a
  trigger (`ExecStart=/usr/bin/true`); the real work is `systemd-growfs-root`
  plus an initramfs `local-premount/resize_early` script from the same package.
- `console-setup`, `keyboard-configuration` — `01-run.sh` calls `setupcon` and
  `dpkg-reconfigure keyboard-configuration console-setup` unconditionally. Drop
  the packages and the build dies under `bash -e`.
- `rpi-eeprom` — bootloader updates on Pi 4.

Deliberately *not* listed:

- `parted`, `fdisk`, `whiptail`, `uuid`, `raspi-config` — all hard `Depends` of
  `raspberrypi-sys-mods`, so apt installs them regardless.
- `rpi-loop-utils` — ships nothing resize-related (verified); only `rpi-swap`
  needs it, and that is cut.
- `userconf-pi` — unavoidable. `export-image/01-user-rename/00-packages`
  installs it unconditionally *after* this stage.

## Networking

netplan + systemd-networkd + wpa_supplicant, matching Ubuntu Server. netplan's
networkd renderer drives wifi through wpa_supplicant; iwd is only reachable via
the NetworkManager renderer, which would pull NetworkManager back in.

`01-net-tweaks/01-run.sh` templates `/etc/netplan/10-net.yaml` from `WIFI_SSID`
and `WIFI_PASS` in `../config`, replacing the `wpa_supplicant.conf` flow pi-gen
dropped. DHCP on `eth0` and `wlan0`; migrate to static post-install.

`WIFI_SSID` is the only wifi knob. Set it and you get the netplan `wifis:`
stanza *and* `wpasupplicant` (~4 MB, useless without an SSID). Leave it empty
and you get an ethernet-only image and a build warning.

`firmware-brcm80211` (~20 MB) installs either way, deliberately. It is the
Broadcom firmware blob: without it the kernel cannot bring up the radio and
there is no `wlan0` for netplan to match on. Keeping it means a future
`apt install wpasupplicant` + a `wifis:` stanza + `netplan apply` is enough to
get wifi on a board that has it — no need to source a non-free blob over a
network you do not yet have.

`WPA_COUNTRY` must stay set. `raspberrypi-sys-mods` sets `rfkill.default_state=0`,
soft-blocking the radio until a regulatory domain is set. `raspi-config nonint
do_wifi_country` clears it; in a chroot it writes `cfg80211.ieee80211_regdom=`
into `cmdline.txt` and zeroes `/var/lib/systemd/rfkill/*:wlan`. It needs no
wpasupplicant — its `wpa_cli` path is gated on an active `dhcpcd`, and `iw reg
set` on `! ischroot`.

## Known wart

`pi-gen/export-image/03-network/01-run.sh` runs after this stage and installs a
static `/etc/resolv.conf` containing `nameserver 8.8.8.8`. systemd-resolved will
not overwrite a real file, so DNS bypasses resolved and DHCP-provided nameservers
are ignored. To use LAN DNS, on the booted box:

    sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
