# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

{ config, ... }:
{ python3 }:
python3.pkgs.buildPythonPackage {
  pname = "pidcat";
  version = "unstable-2025-05-29";

  src = config.inputs.pidcat.result;

  patches = [
    ../patches/pidcat/fix-encoding.patch
  ];

  preBuild = ''
    cat > setup.py << EOF
    from setuptools import setup

    setup(
      name='pidcat',
      scripts=[
        'pidcat.py',
      ],
    )
    EOF
  '';

  postInstall = ''
    mv -v $out/bin/pidcat.py $out/bin/pidcat
  '';

  pyproject = true;
  build-system = [ python3.pkgs.setuptools ];
}
