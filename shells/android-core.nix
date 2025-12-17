# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

let
  variables = import ../variables.nix;
  inherit (variables) ndkVersion;
in
{ config, ... }:
{
  lib,
  clangStdenv,
  mkShell,
  ...
}:
let
  androidSdk = config.packages.android-sdk.result.x86_64-linux;
  sdkPath = "${androidSdk}/libexec/android-sdk";
  ndkPath = "${sdkPath}/ndk/${ndkVersion}";
  toolchainBinPath = "${ndkPath}/toolchains/llvm/prebuilt/linux-x86_64/bin";
in
mkShell.override
  {
    stdenv = clangStdenv;
    # Required as otherwise inner packages see that gcc is available, try to build with it, and fall flat on their faces
    # We want them to default to the first clang in our path while LO can build some stuff with the other clangs
    # This is the closest I can reasonably get to a "normal" setup where you add your ndk bin directory to your path before your regular cc ... but I think it's enough
  }
  {
    inputsFrom = [
      config.shells.core.result.x86_64-linux
    ];

    AUTOGEN_FLAGS = builtins.concatStringsSep " " [
      "--enable-dbgutil"
      "--with-parallelism=6"
      "--with-android-ndk=${ndkPath}"
      "--with-android-sdk=${sdkPath}"
      "--enable-sal-log"
      "--with-distro=CPAndroidAarch64"
    ];

    CCACHE_COMPRESS = "1";
    CCACHE_CPP2 = "1";
    TMPDIR = "/tmp";

    shellHook = ''
      export PKG_CONFIG_PATH_x86_64_unknown_linux_gnu="$PKG_CONFIG_PATH"
      unset CC CXX AR LD
      export STRIP=llvm-strip
      export PATH="$PATH:${toolchainBinPath}"
    '';
  }
