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
    config = {
      inputs = builtins.mapAttrs (name: value: {
        src = value;
        settings = settings.${name} or config.lib.constants.undefined;
      }) (config.lib.attrs.filter (name: _: name != "__functor") pins);

      lib.constants.undefined = config.lib.modules.when false { };

      packages =
        let
          packageFiles = builtins.readDir ./packages;
          nixFiles = builtins.filter (f: (builtins.match ''.*\.nix'' f) != null) (
            builtins.attrNames packageFiles
          );
          packages = builtins.map (f: {
            name = config.lib.strings.removeSuffix ".nix" f;
            value = {
              systems = [ "x86_64-linux" ];
              package = import "${./.}/packages/${f}" { inherit config; };
            };
          }) nixFiles;
        in
        builtins.listToAttrs packages;

      shells =
        let
          shellFiles = builtins.readDir ./shells;
          nixFiles = builtins.filter (f: (builtins.match ''.*\.nix'' f) != null) (
            builtins.attrNames shellFiles
          );
          shells = builtins.map (f: {
            name = config.lib.strings.removeSuffix ".nix" f;
            value = {
              systems = [ "x86_64-linux" ];
              shell = import "${./.}/shells/${f}" { inherit config; };
            };
          }) nixFiles;
        in
        builtins.listToAttrs shells;
    };
  }
)
