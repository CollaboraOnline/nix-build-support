# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

{ config, ... }:
{
  lib,
  pkgsCross,
  gcc,
  writeShellScriptBin,
  pkg-config,
  libreoffice-collabora,
  python3,
  ...
}: let
  pkgs-host = config.inputs.nixpkgs.result.aarch64-linux; # Some things fail to cross compile ... we can just download from Hydra anyway
  libreoffice-collabora-build = libreoffice-collabora;
  python3-build = python3;
in (pkgsCross.aarch64-multiplatform.callPackage ({
  mkShell,
  libreoffice-collabora,
  ccache,
  clang-tools,
  meson,
  ninja,
  python3,
  coreutils,
}: let
  libreoffice-collabora-target = libreoffice-collabora;
  python3-target = python3;

  pythonWithPackages = python: python.withPackages (pyPkgs: [
    pyPkgs.distutils
    pyPkgs.lxml
    pyPkgs.polib
  ]);
in mkShell {
  buildInputs = [
    pkgs-host.fast-float
  ]
  ++ pkgs-host.libreoffice-collabora.buildInputs;

  nativeBuildInputs = [
    ccache
    clang-tools
    meson
    ninja
    (pythonWithPackages python3-target)
    (writeShellScriptBin "pkg-config" ''
      $PKG_CONFIG "$@"
    '') # pkg-config is required to exist as pkg-config on PATH, no matter that the build will actually use $PKG_CONFIG, because ./autogen.sh has a hardcoded check for it. We use outer writeShellScriptBin or we will make a script that can't be run on --build
    (writeShellScriptBin "x86_64-pc-linux-gnu-ar" ''
      ${pkgsCross.gnu64.binutils}/bin/ar "$@"
    '')
  ] ++ libreoffice-collabora-target.nativeBuildInputs;

  AUTOGEN_FLAGS = builtins.concatStringsSep " " [
    "--enable-dbgutil"
    "--without-doxygen"
    "--with-parallelism=6"
    "--without-buildconfig-recorded"
    "--with-boost=${pkgs-host.boost.dev}"
    "--with-boost-libdir=${pkgs-host.boost}/lib"
    "--with-beanshell-jar=${pkgs-host.bsh}"
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
    "--with-system-lpsolve"
    "--without-doxygen"
  ];

  CCACHE_COMPRESS = "1";
  TMPDIR = "/tmp";

  shellHook = ''
    export PKG_CONFIG_FOR_BUILD="${pkg-config}/bin/pkg-config"
    export PKG_CONFIG_PATH_FOR_BUILD="${lib.makeSearchPathOutput "dev" "lib/pkgconfig" libreoffice-collabora-build.buildInputs}"
    export CC_FOR_BUILD="${gcc}/bin/cc"
    export CXX_FOR_BUILD="${gcc}/bin/c++"
    export PYTHON_FOR_BUILD="${pythonWithPackages python3-build}/bin/python"
  '';
}) {})
