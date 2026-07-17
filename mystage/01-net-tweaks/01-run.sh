#!/bin/bash -e

# raspberrypi-sys-mods sets rfkill.default_state=0, which soft-blocks the radio
# until a WLAN regulatory domain is set. Without this the wifi is dead on boot.
if [ -v WPA_COUNTRY ]; then
	on_chroot <<- EOF
		SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_wifi_country "${WPA_COUNTRY}"
	EOF
fi

NETPLAN_FILE="${ROOTFS_DIR}/etc/netplan/10-net.yaml"
mkdir -p "$(dirname "${NETPLAN_FILE}")"

# SSIDs and passphrases may contain " or \, which would otherwise terminate the
# YAML scalar early and produce an unparseable file.
yaml_escape() {
	printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Unindented heredocs: YAML is whitespace-sensitive and <<- strips tabs.
cat > "${NETPLAN_FILE}" << EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: true
      optional: true
EOF

if [ -n "${WIFI_SSID:-}" ]; then
	cat >> "${NETPLAN_FILE}" << EOF
  wifis:
    wlan0:
      dhcp4: true
      optional: true
      access-points:
        "$(yaml_escape "${WIFI_SSID}")":
          password: "$(yaml_escape "${WIFI_PASS:-}")"
EOF

	# netplan's networkd renderer authenticates via wpa_supplicant, so this is
	# only worth its ~4MB once an SSID exists. firmware-brcm80211 ships either
	# way: without the blob there is no wlan0 to configure later.
	on_chroot <<- EOF
		apt-get -o Acquire::Retries=3 install -y wpasupplicant
	EOF
else
	echo "WARNING: WIFI_SSID unset, image will be ethernet-only (no wpasupplicant)"
fi

# netplan refuses to apply world-readable configs holding secrets.
chmod 600 "${NETPLAN_FILE}"

install -v -D -m 644 files/resolv-conf.conf "${ROOTFS_DIR}/etc/tmpfiles.d/resolv-conf.conf"

on_chroot <<- EOF
	systemctl enable systemd-networkd
	systemctl enable systemd-resolved
EOF
