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
IMG_NAME=base
FIRST_USER_NAME=op
WPA_ESSID="Wifi name"
WPA_PASSWORD="Wifi Password"
```

5. You might have to run `prep` if you are running the script for the first time.

6. Then, run `dockerrun` from the root of the whole repository. This step
   starts the build and can take hours.

# Lazy?

Install Docker and paste this into your terminal:

```
git clone https://github.com/lkwilson/auto-pi-gen.git && \
cd auto-pi-gen && \
git submodule init && \
git submodule update && \
vim config && \
bash prep && \
bash dockerrun
```

# Script is failing?

- **On OS X, some commands might fail.** Install them with `homebrew`. Known requirements:

  - `realpath` from `coreutils` is required

- You can always delete the whole cloned repository and try again.
- On Windows, their bash isn't good enough, and Docker isn't well supported either.

# Don't want to use Docker?

You can use `run` instead of `dockerrun`, but you have to be on a Debian
based Linux system, e.g., Ubuntu. It's also messy and not well tested. I
don't recommend this.
