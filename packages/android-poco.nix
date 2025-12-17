# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

let
  variables = import ../variables.nix;
  inherit (variables) minPlatformVersion abi ndkVersion;
in
{ config, ... }:
{
  stdenv,
  fetchFromGitHub,
  androidenv,
  nettools,
  ...
}:
let # nettools is for 'hostname'... weird but ok whatever
  version = "1.14.2";
  androidSdk = config.packages.android-sdk.result.x86_64-linux;
  sdkPath = "${androidSdk}/libexec/android-sdk";
  ndkPath = "${sdkPath}/ndk/${ndkVersion}";
  toolchainBinPath = "${ndkPath}/toolchains/llvm/prebuilt/linux-x86_64/bin";
in
stdenv.mkDerivation {
  pname = "android-poco";
  inherit version;

  src = config.inputs.poco.result;

  patches = [
    ../patches/android-poco/arm64-support.patch
  ];

  configureFlags = [
    "--config=Android"
    "--prefix=${placeholder "out"}"
    "--no-samples"
    "--no-tests"
    "--omit=ActiveRecord,Crypto,NetSSL_OpenSSL,Zip,Data,Data/SQLite,Data/ODBC,Data/MySQL,MongoDB,PDF,CppParser,PageCompiler,JWT,Prometheus,Redis"
  ];

  nativeBuildInputs = [
    nettools
  ];

  buildPhase = ''
    export PATH="$PATH:${toolchainBinPath}"
    export SYSLIBS=-static-libstdc++
    export ANDROID_ABI=${abi}

    echo $PATH
    make -sj12 \
      CC=aarch64-linux-android${minPlatformVersion}-clang \
      CXX=aarch64-linux-android${minPlatformVersion}-clang++ \
      LIB='llvm-ar -cr' \
      RANLIB=llvm-ranlib
  '';

  installPhase = ''
    mkdir -p $out
    make -sj12 ANDROID_ABI=${abi} install
  '';
}
