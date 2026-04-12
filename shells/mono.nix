# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT
{ config }:
{
  lib,
  mkShell,
  boost,
  bsh,
  ccache,
  collabora-online,
  cypress,
  libreoffice-collabora,
  meson,
  ninja,
  python3,
  typescript-language-server,
  vscode-langservers-extracted,
  xorg,
  bear,
  chromium,
  ...
}:
mkShell {
  packages = [
    ccache
    typescript-language-server
    cypress
    xorg.xhost
    bear
    chromium
    vscode-langservers-extracted
    (python3.withPackages (pyPkgs: [
      pyPkgs.distutils
      pyPkgs.lxml
      pyPkgs.polib
    ]))
    meson
    ninja
  ];

  inputsFrom = [
    collabora-online
    libreoffice-collabora
  ];

  SYSTEMPLATE_PATCH = ../patches/online/0001-build-add-nix-build-support.patch;

  ONLINE_CONFIGURE_FLAGS = builtins.concatStringsSep " " [
    "--enable-silent-rules"
    "--enable-debug"
    "--enable-cypress"
  ];

  ENGINE_AUTOGEN_FLAGS = builtins.concatStringsSep " " [
    "--enable-dbgutil"
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
    "--disable-firebird-sdbc"
    "--with-fonts"
    "--with-system-lpsolve"
  ];

  CYPRESS_RUN_BINARY = "${cypress}/bin/Cypress";
  CYPRESS_SKIP_VERIFY = "1";

  CCACHE_COMPRESS = "1";
  TMPDIR = "/tmp";
}
