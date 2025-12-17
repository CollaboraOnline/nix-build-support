# SPDX-FileCopyrightText: 2025 Collabora Productivity Limited
#
# SPDX-License-Identifier: MIT

{ config, ... }:
{ mkShell, reuse, ... }:
mkShell {
  packages = [
    reuse
  ];
}
