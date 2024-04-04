This is used for generating custom raspberry pi images.

# Instructions

1. If you are using Windows, boot into Ubuntu.
1. Install Docker.
1. Clone the repository and initialize the submodules

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
PUBKEY_SSH_FIRST_USER=$(cat ~/.ssh/id_ed25519.pub)
```

5. Set the wifi

Wifi comes from the wpa_supplicant, so use wpa_pass

```
wpa_passphrase <ssid> <pass> >> ./copy_in/wpa_supplicant.conf
```

6. Then, run `dockerrun` from the root of the whole repository. This step
   starts the build and can take hours.

# Lazy?

Install Docker and paste this into your terminal:

```
git clone https://github.com/lkwilson/auto-pi-gen.git && \
cd auto-pi-gen && \
git submodule init && \
git submodule update && \
vim copy_in/config && \
bash dockerrun
```

# Script is failing?

- Restart it with `export CONTINUE=1; bash dockerrun`
- See the pi-gen documentation (it'll have tips like how to connect to the docker container)
- **On OS X, some commands might fail.** Install them with `homebrew`. Known requirements:

  - `realpath` from `coreutils` is required

- You can always delete the whole cloned repository and try again.
- On Windows, their bash isn't good enough, and Docker isn't well supported either.

# Don't want to use Docker?

You can use `run` instead of `dockerrun`, but you have to be on a Debian
based Linux system, e.g., Ubuntu. It's also messy and not well tested. I
don't recommend this.

# How to rerun / cleanup

Stop and remove any running containers

```
docker ps -a
docker stop <pi-container-id>  # if not stopped
docker rm <pi-container-id>
```

Delete any existing pi images
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
