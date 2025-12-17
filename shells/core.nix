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
}
