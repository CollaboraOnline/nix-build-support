# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

{ config }:
{
  kdePackages,
  stdenv,
  ...
}:
config.shells.online.result.x86_64-linux.overrideAttrs (old: {
   nativeBuildInputs = old.nativeBuildInputs ++ [
    kdePackages.qtbase.dev
    kdePackages.qttools
    (stdenv.mkDerivation {
      name = "qtlibexec";

      src = kdePackages.qtbase;

      buildPhase = ''
        mkdir -p $out
        ln -s ${kdePackages.qtbase}/libexec $out/bin
      '';
    })
    kdePackages.qtbase
    kdePackages.qtwebengine
    kdePackages.wrapQtAppsHook
  ];
})
