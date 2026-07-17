#!/bin/bash -e

if [ -n "${PUBKEY_SSH_FIRST_USER}" ]; then
	install -v -m 0700 -o 1000 -g 1000 -d "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh
	echo "${PUBKEY_SSH_FIRST_USER}" >"${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chown 1000:1000 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
	chmod 0600 "${ROOTFS_DIR}"/home/"${FIRST_USER_NAME}"/.ssh/authorized_keys
fi

if [ "${PUBKEY_ONLY_SSH}" = "1" ]; then
	sed -i -Ee 's/^#?[[:blank:]]*PubkeyAuthentication[[:blank:]]*no[[:blank:]]*$/PubkeyAuthentication yes/
s/^#?[[:blank:]]*PasswordAuthentication[[:blank:]]*yes[[:blank:]]*$/PasswordAuthentication no/' "${ROOTFS_DIR}"/etc/ssh/sshd_config
fi

on_chroot << EOF
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
EOF

on_chroot <<- EOF
	systemctl enable rpi-resize

	# netdev is created by network-manager's postinst upstream; this image drops
	# NetworkManager, so nothing else makes it.
	groupadd -f -r netdev

	for GRP in adm dialout sudo users netdev; do
		adduser $FIRST_USER_NAME \$GRP
	done
EOF

if [ "${PASSWORDLESS_SUDO}" = "1" ]; then
	on_chroot <<- EOF
		SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_sudo_pass 1
	EOF
fi

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

# Force per-device host keys; otherwise every flash shares one SSH identity.
rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*

sed -i 's/^FONTFACE=.*/FONTFACE=""/;s/^FONTSIZE=.*/FONTSIZE=""/' "${ROOTFS_DIR}/etc/default/console-setup"
sed -i "s/PLACEHOLDER//" "${ROOTFS_DIR}/etc/default/keyboard"
on_chroot << EOF
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration console-setup
EOF
