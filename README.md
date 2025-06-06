# Collabora Online nix-build-support

This repository contains community-supported nix build support for
developing Collabora Online. We do not support, and recommend you do not
use, this in a production environment

# General usage

The following I know to work
- building Core and Collabora Online for Android on NixOS
- building Core and Collabora Online on NixOS
- running Core and Collabora Online on NixOS, provided you also use this
  patch on Collabora Online sources (without it, you will fail to find
  fonts/etc.)

```diff
diff --git a/coolwsd-systemplate-setup b/coolwsd-systemplate-setup
index 8d60157d23..f4b9fc26bb 100755
--- a/coolwsd-systemplate-setup
+++ b/coolwsd-systemplate-setup
@@ -20,9 +20,9 @@
 # while INSTDIR is the physical one. Both will most likely be the same,
 # except on systems that have symlinks in the path. We must create
 # both paths (if they are different) inside the jail, hence we need both.
-CHROOT=`cd $CHROOT && /bin/pwd`
-INSTDIR_LOGICAL=`cd $INSTDIR && /bin/pwd -L`
-INSTDIR=`cd $INSTDIR && /bin/pwd -P`
+CHROOT=`cd $CHROOT && pwd`
+INSTDIR_LOGICAL=`cd $INSTDIR && pwd -L`
+INSTDIR=`cd $INSTDIR && pwd -P`

 if [ ! `uname -s` = "FreeBSD" ]; then
     CP=cp
@@ -157,4 +157,9 @@
     test -d $HOME/.fonts && ${CP} -r -p -L $HOME/.fonts $CHROOT/$HOME
 fi

+if test -d /nix; then
+    mkdir -p $CHROOT/nix
+    sudo mount --bind /nix $CHROOT/nix
+fi
+
 exit 0
```

You likely want to use this with [Nilla's cli](https://github.com/nilla-nix/cli)
as, while you can manually use the shells, it will provide a much more
sugared experience. You can follow [Nilla's quickstart guide](https://nilla.dev/guides/quickstart/)
to install it

You will probably want to keep this directory *alongside* your nix
rather than cloning into it. That's because nilla *will copy everything
to your store if you use it to enter a shell, leading to a very long
delay*. LibreOffice translations/etc. are gigabytes big in a full clone.
You do not want that.

# Copy/pasteable commands

(You will need to [install the Nilla cli](https://nilla.dev/guides/quickstart/)
to follow these instructions)

## To build core

```
nilla shell core --project /path/to/nilla
git clone https://gerrit.libreoffice.org/core
cd core
git checkout distro/collabora/co-25.04
./autogen.sh $AUTOGEN_FLAGS
make
```

## To build online

```
nilla shell online --project /path/to/nilla
git clone https://github.com/CollaboraOnline/online
cd online
git apply "$SYSTEMPLATE_PATCH"
./autogen.sh
./configure $CONFIGURE_FLAGS
make run
```

## To build Android core

```
nilla shell android-core --project /path/to/nilla
git clone https://gerrit.libreoffice.org/core
cd core
git checkout distro/collabora/co-25.04
./autogen.sh $AUTOGEN_FLAGS
make
```

## To build Android online


```
nilla shell android-online --project /path/to/nilla
git clone https://github.com/CollaboraOnline/online
cd online
./autogen.sh
./configure $CONFIGURE_FLAGS
make
android-studio
# Follow the prompts in Android studio to build. If you're asked whether to use project NDK or Android Studio NDK choose Android Studio NDK
```

# Usage with direnv

The .envrc.template assumes that you have kept this directory alongside
your rather than cloning libreoffice into it, and further that the
folder you have is called 'nilla'. To do that, you'll need to clone this
repository with the following

    git clone git@github.com:Minion3665/collabora--nix-build-support nilla

The .envrc.template also assumes you have some nested directory
structure, such as

    - nilla/
    - android/
      - core/
      - online/
    - standard/
      - core/
      - online/

and are placing it in your clone directories (here 'core' and 'online')

This is a reasonable assumption as you will need separate shells for
core and online, so you can't just place the .envrc directly above your
clone of this repository.

If you decide to change either of these assumptions, the path should be
trivial to modify. You'll need to change the envrc anyway to fill in the
shell name you want. Again, this should be fairly self explanatory

