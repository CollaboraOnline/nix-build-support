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
  cmake,
  ...
}:
let
  androidSdk = config.packages.android-sdk.result.x86_64-linux;
  sdkPath = "${androidSdk}/libexec/android-sdk";
  ndkPath = "${sdkPath}/ndk/${ndkVersion}";
  toolchainBinPath = "${ndkPath}/toolchains/llvm/prebuilt/linux-x86_64/bin";
in
stdenv.mkDerivation {
  pname = "android-zstd";
  version = "unstable-2025-05-12";

  src = config.inputs.zstd.result;

  nativeBuildInputs = [
    cmake
  ];

  dontConfigure = true;

  buildPhase = ''
    mkdir -p install/${abi}
    cd install/${abi}

    cmake ../../build/cmake \
      -DCMAKE_TOOLCHAIN_FILE=${ndkPath}/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=${abi} \
      -DCMAKE_ANDROID_ARCH_ABI=${abi} \
      -DANDROID_NDK=${ndkPath} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_SYSTEM_NAME=Android \
      -DCMAKE_SYSTEM_VERSION=${minPlatformVersion} \
      -DZSTD_BUILD_PROGRAMS:BOOL=OFF \
      -DZSTD_BUILD_SHARED:BOOL=OFF || exit 1;

    make

    cd ../..
  '';

  installPhase = ''
    mkdir -p $out
    mv lib $out/include
    mv install/${abi} $out
  '';
}
