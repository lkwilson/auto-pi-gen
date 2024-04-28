This is used for generating custom raspberry pi images.

# Instructions

1. If you are using Windows, boot into Ubuntu (maybe it works with wsl2).
2. Install deps: docker, coreutils (for realpath)
3. Clone the repository and initialize the submodules

```
git clone https://github.com/lkwilson/auto-pi-gen.git
cd auto-pi-gen
git submodule init
git submodule update
```

4. Modify the config file:

Change the following lines in the config file:

```
IMG_NAME=mypi
TARGET_HOSTNAME=mypi
FIRST_USER_NAME=pi
FIRST_USER_PASS=raspberry
PUBKEY_SSH_FIRST_USER='<contents of ~/.ssh/id_ed25519.pub>'
```

5. Set the wifi

Wifi comes from the wpa_supplicant, so use wpa_passphrase

```
wpa_passphrase <ssid> <pass> >> ./copy_in/wpa_supplicant.conf
```

6. Then, run `build` from the root of the whole repository. This step
   starts the build and can take hours.

# How to rerun / cleanup

Stop and remove any pi-gen containers (eg pigen_work)

```
docker ps -a
docker stop <pi-container-id>  # if not stopped
docker rm <pi-container-id>
```

Delete any existing pi images (eg pi-gen)

```
docker image ls
docker image rm -f <image-id>
```

Clean the pi-gen repo

```
cd pi-gen
git clean -xnfd  # dry run
git clean -xfd  # actually do clean
git checkout -- .  # good measure
```

# How to update this:

Checkout origin/arm64 since you're probably flashing an 64-bit pi

Verify the wpa_passphrase is in the same location, and verify that the config
variables haven't been updated.
