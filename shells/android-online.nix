# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

let
  variables = import ../variables.nix;
  inherit (variables) ndkVersion abi;
in
{ config }:
{
  lib,
  mkShell,
  androidenv,
  android-studio,
  jdk17,
  libgcc,
  jdt-language-server,
  kotlin,
  ...
}:
let
  androidSdk = config.packages.android-sdk.result.x86_64-linux.override {
    inherit ndkVersion;
    cmakeVersion = "3.22.1";
    buildToolsVersion = "30.0.3";
    platformToolsVersion = "34.0.5";
    includeSources = true;
  };
  sdkPath = "${androidSdk}/libexec/android-sdk";
  ndkPath = "${sdkPath}/ndk/${ndkVersion}";
  toolchainBinPath = "${ndkPath}/toolchains/llvm/prebuilt/linux-x86_64/bin";
in
mkShell {
  packages = [
    androidSdk.platform-tools
    (android-studio.overrideAttrs {
      preferLocalBuild = true; # android-studio is downloading/symlinking things - and quite a lot of things - so in my testing it takes *way* longer to do this remotely...
    })
    jdk17
    jdt-language-server
    config.packages.pidcat.result.x86_64-linux # TODO: again, pkgs.system/etc.
    kotlin
  ];

  inputsFrom = [
    config.shells.online.result.x86_64-linux
  ];

  CCACHE_COMPRESS = "1";
  CCACHE_CPP2 = "1";
  TMPDIR = "/tmp";
  STUDIO_GRADLE_JDK = "${jdk17}/lib/openjdk";
  ANDROID_HOME = sdkPath;
  ANDROID_NDK_ROOT = ndkPath;

  CONFIGURE_FLAGS = builtins.concatStringsSep " " [
    "--enable-androidapp"
    "--with-poco-includes=${config.packages.android-poco.result.x86_64-linux}/include" # TODO: should I be using pkgs.system or somesuch here(?)
    "--with-poco-libs=${config.packages.android-poco.result.x86_64-linux}/${abi}/lib"
    "--with-zstd-includes=${config.packages.android-zstd.result.x86_64-linux}/include"
    "--with-zstd-libs=${config.packages.android-zstd.result.x86_64-linux}/${abi}/lib"
    "--enable-silent-rules"
    "--enable-debug"
    "--with-android-abi=${abi}"
    "--disable-werror" # TODO: there are some warnings while building android about some redefined macros...
  ];

  shellHook = ''
    export PATH="$PATH:${toolchainBinPath}"
    export LD_LIBRARY_PATH="${libgcc}/lib:$LD_LIBRARY_PATH"
  '';
}
