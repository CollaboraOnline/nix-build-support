# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

{ config, ... }:
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
    "--with-system-lpsolve"
    "--without-doxygen"
  ];

  CCACHE_COMPRESS = "1";
  TMPDIR = "/tmp";
}
