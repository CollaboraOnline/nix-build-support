# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

# Cannot merge with core, as lo builds with python3.11+distutils and co builds with python3.12 without distutils
# TODO: it feels theoretically possible to set up something that has priorities such that python3.12 is ignored - at which point maybe we can use the same env(?)
# I'm suspicious of being able to use android-core along with core though - especially as clang stdenv is required for it, so maybe we need multiple shells
# or maybe that is just better handled with separate shells and direnv anyway(?)
{ config }:
{
  lib,
  mkShell,
  ccache,
  collabora-online,
  cypress,
  typescript-language-server,
  xorg,
  ...
}:
mkShell {
  packages = [
    ccache
    typescript-language-server
    cypress
    xorg.xhost
  ];

  inputsFrom = [
    collabora-online
  ];

  SYSTEMPLATE_PATCH = ../patches/online/0001-build-add-nix-build-support.patch;

  CONFIGURE_FLAGS = builtins.concatStringsSep " " [
    "--enable-silent-rules"
    "--enable-debug"
    "--enable-cypress"
  ];

  CYPRESS_RUN_BINARY = "${cypress}/bin/Cypress";
  CYPRESS_SKIP_VERIFY = "1";

  CCACHE_COMPRESS = "1";
  TMPDIR = "/tmp";
}
