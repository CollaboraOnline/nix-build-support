# SPDX-FileCopyrightText: 2025 the Collabora Online contributors
#
# SPDX-License-Identifier: MIT

let
  pins = import ./npins;

  nilla = import pins.nilla;

  settings = {
    nixpkgs.configuration = {
      android_sdk.accept_license = true;
      allowUnfree = true;
      allowBroken = true;
    };
  };
in
nilla.create (
  { config }:
  {
    config =
      let
        coreNdkVersion = "27.2.12479018";
        onlineNdkVersion = "27.2.12479018";
        pocoNdkVersion = "27.2.12479018";
        zstdNdkVersion = "27.2.12479018";
        minPlatformVersion = "33"; # https://endoflife.date/android
        abi = "arm64-v8a";
        mkAndroidSdk =
          {
            androidenv,
            ndkVersion,
            cmakeVersion ? "latest",
            buildToolsVersion ? "latest",
            includeSources ? false,
            platformToolsVersion ? "latest",
          }:
          androidenv.composeAndroidPackages {
            inherit minPlatformVersion includeSources platformToolsVersion;
            abiVersions = [ abi ];
            includeNDK = true;
            ndkVersions = [
              ndkVersion
            ];
            cmakeVersions = [
              cmakeVersion
            ];
            buildToolsVersions = [
              buildToolsVersion
            ];
          };
      in
      {
        inputs = builtins.mapAttrs (name: value: {
          src = value;
          settings = settings.${name} or config.lib.constants.undefined;
        }) pins;

        lib.constants.undefined = config.lib.modules.when false { };

        shells.default = {
          systems = [ "x86_64-linux" ];

          shell =
            { mkShell, reuse, ... }:
            mkShell {
              packages = [
                reuse
              ];
            };
        };

        shells.core = {
          systems = [ "x86_64-linux" ];

          # Define our shell environment.
          shell =
            {
              lib,
              mkShell,
              ccache,
              clang-tools,
              libreoffice-collabora,
              boost,
              bsh,
              ...
            }:
            mkShell {
              packages = [
                ccache
                clang-tools
              ];

              inputsFrom = [
                libreoffice-collabora
              ];

              AUTOGEN_FLAGS = builtins.concatStringsSep " " [
                "--enable-dbgutil"
                "--without-doxygen"
                "--with-external-tar=../../core-tarballs"
                "--with-parallelism=6"
                "--without-buildconfig-recorded"
                "--with-boost=${boost.dev}"
                "--with-boost-libdir=${boost}/lib"
                "--with-beanshell-jar=${bsh}"
                "--disable-report-builder"
                "--disable-online-update"
                "--enable-python=system"
                "--enable-dbus"
                "--enable-epm"
                "--without-junit"
                "--without-export-validation"
                "--enable-build-opensymbol"
                "--disable-odk"
                "--disable-firebird-sdbc"
                "--with-fonts"
                "--without-doxygen"
                "--with-system-beanshell"
                "--with-system-cairo"
                "--with-system-coinmp"
                "--with-system-headers"
                "--with-system-libabw"
                "--with-system-libepubgen"
                "--with-system-libetonyek"
                "--with-system-liblangtag"
                "--with-system-lpsolve"
                "--with-system-mdds"
                "--with-system-openldap"
                "--with-system-openssl"
                "--with-system-postgresql"
                "--with-system-xmlsec"
                "--without-system-altlinuxhyph"
                "--without-system-frozen"
                "--without-system-libfreehand"
                "--without-system-libmspub"
                "--without-system-libnumbertext"
                "--without-system-libpagemaker"
                "--without-system-libstaroffice"
                "--without-system-libqxp"
                "--without-system-dragonbox"
                "--without-system-libfixmath"
                "--without-system-hsqldb"
                "--without-system-zxing"
                "--without-system-zxcvbn"
                "--without-system-rhino"
              ];

              CCACHE_COMPRESS = "1";
              TMPDIR = "/tmp";
            };
        };

        packages.android-poco = {
          systems = [ "x86_64-linux" ];

          package =
            {
              stdenv,
              fetchFromGitHub,
              androidenv,
              nettools,
            }:
            let # nettools is for 'hostname'... weird but ok whatever
              version = "1.14.2";
              androidSdk = (
                mkAndroidSdk {
                  inherit androidenv;
                  ndkVersion = pocoNdkVersion;
                }
              );
              sdkPath = "${androidSdk.androidsdk}/libexec/android-sdk";
              ndkPath = "${sdkPath}/ndk/${pocoNdkVersion}";
              toolchainBinPath = "${ndkPath}/toolchains/llvm/prebuilt/linux-x86_64/bin";
            in
            stdenv.mkDerivation {
              pname = "android-poco";
              inherit version;

              src = config.inputs.poco.result;

              patches = [
                ./patches/android-poco/arm64-support.patch
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
            };
        };

        packages.android-zstd = {
          systems = [ "x86_64-linux" ];

          package =
            {
              stdenv,
              fetchFromGitHub,
              androidenv,
              cmake,
            }:
            let
              androidSdk = (
                mkAndroidSdk {
                  inherit androidenv;
                  ndkVersion = zstdNdkVersion;
                }
              );
              sdkPath = "${androidSdk.androidsdk}/libexec/android-sdk";
              ndkPath = "${sdkPath}/ndk/${zstdNdkVersion}";
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
            };
        };

        shells.android-core = {
          systems = [ "x86_64-linux" ];

          # Define our shell environment.
          shell =
            {
              lib,
              clangStdenv,
              clang-tools,
              mkShell,
              androidenv,
              libreoffice-collabora,
              ccache,
              ...
            }:
            let
              androidSdk = (
                mkAndroidSdk {
                  inherit androidenv;
                  ndkVersion = coreNdkVersion;
                }
              );
              sdkPath = "${androidSdk.androidsdk}/libexec/android-sdk";
              ndkPath = "${sdkPath}/ndk/${coreNdkVersion}";
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
                packages = [
                  ccache
                  clang-tools
                ];

                inputsFrom = [
                  libreoffice-collabora
                ];

                AUTOGEN_FLAGS = builtins.concatStringsSep " " [
                  "--enable-dbgutil"
                  "--with-external-tar=../../core-tarballs"
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
              };
        };

        shells.online = {
          # Cannot merge with core, as lo builds with python3.11+distutils and co builds with python3.12 without distutils
          # TODO: it feels theoretically possible to set up something that has priorities such that python3.12 is ignored - at which point maybe we can use the same env(?)
          # I'm suspicious of being able to use android-core along with core though - especially as clang stdenv is required for it, so maybe we need multiple shells
          # or maybe that is just better handled with separate shells and direnv anyway(?)
          systems = [ "x86_64-linux" ];

          # Define our shell environment.
          shell =
            {
              lib,
              mkShell,
              ccache,
              collabora-online,
              typescript-language-server,
              ...
            }:
            mkShell {
              packages = [
                ccache
                typescript-language-server
              ];

              inputsFrom = [
                collabora-online
              ];

              SYSTEMPLATE_PATCH = ./patches/online/0001-build-add-nix-build-support.patch;

              CONFIGURE_FLAGS = builtins.concatStringsSep " " [
                "--enable-silent-rules"
                "--with-lokit-path=../core/include" # Relative paths are OK here, as they are realpathed by the script
                "--with-lo-path=../core/instdir" # Relative paths are OK here, as they are realpathed by the script
                "--enable-debug"
                "--enable-cypress"
              ];

              CCACHE_COMPRESS = "1";
              TMPDIR = "/tmp";
            };
        };

        shells.android-online = {
          systems = [ "x86_64-linux" ];

          # Define our shell environment.
          shell =
            {
              lib,
              mkShell,
              ccache,
              collabora-online,
              android-studio,
              androidenv,
              jdk17,
              libgcc,
              jdt-language-server,
              typescript-language-server,
              chromium,
              ...
            }:
            let
              androidSdk = (
                mkAndroidSdk {
                  inherit androidenv;
                  ndkVersion = onlineNdkVersion;
                  cmakeVersion = "3.22.1";
                  buildToolsVersion = "30.0.3";
                  platformToolsVersion = "34.0.5";
                  includeSources = true;
                }
              );
              sdkPath = "${androidSdk.androidsdk}/libexec/android-sdk";
              ndkPath = "${sdkPath}/ndk/${onlineNdkVersion}";
              toolchainBinPath = "${ndkPath}/toolchains/llvm/prebuilt/linux-x86_64/bin";
            in
            mkShell {
              packages = [
                ccache
                androidSdk.platform-tools
                android-studio
                jdk17
                jdt-language-server
                typescript-language-server
                chromium
              ];

              inputsFrom = [
                collabora-online
              ];

              CCACHE_COMPRESS = "1";
              CCACHE_CPP2 = "1";
              TMPDIR = "/tmp";
              STUDIO_GRADLE_JDK = "${jdk17}/lib/openjdk";
              ANDROID_HOME = sdkPath;
              ANDROID_NDK_ROOT = ndkPath;

              CONFIGURE_FLAGS = builtins.concatStringsSep " " [
                "--enable-androidapp"
                "--with-lo-builddir=../core" # Relative paths are OK here, as they are realpathed by the script
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
            };
        };
      };
  }
)
