# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

let
  variables = import ../variables.nix;
in
{ config, ... }:
{
  androidenv,
  ndkVersion ? variables.ndkVersion,
  cmakeVersion ? "latest",
  buildToolsVersion ? "latest",
  includeSources ? false,
  platformToolsVersion ? "latest",
  abi ? variables.abi,
  minPlatformVersion ? variables.minPlatformVersion,
  platformVersions ? [ "latest" ],
  ...
}:
let
  androidPkgs = androidenv.composeAndroidPackages {
    inherit minPlatformVersion includeSources platformToolsVersion platformVersions;
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
  androidsdk = androidPkgs.androidsdk;
in androidsdk.overrideAttrs (prev: {
  passthru = (prev.passthru or {}) // androidPkgs;
})
