#!/bin/bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

[ -f "$BingWallpaperJson" ] && AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$aria2Json" 2>/dev/null) || AutoUpdatesDependencies=true

pkgUpdate() {
  dnf=${1}
  if grep -q "^$dnf" <<< "$dnfUpgradesList" 2>/dev/null; then
    echo -e "$running Upgrading $dnf package.."
    sudo dnf update "$dnf" -y >/dev/null 2>&1
  fi
}

pkgInstall() {
  dnf=${1}
  if grep -q "^$dnf" <<< "$dnfList" 2>/dev/null; then
    pkgUpdate "$dnf"
  else
    echo -e "$running Installing $dnf package.."
    sudo dnf install "$dnf" -y >/dev/null 2>&1
  fi
}

pkgUninstall() {
  dnf=${1}
  dnfList=$(dnf list --installed 2>/dev/null)
  if grep -q "^$dnf" <<< "$dnfList" 2>/dev/null; then
    echo -e "$running Uninstalling $dnf package.."
    sudo dnf remove "$dnf" -y >/dev/null 2>&1
  fi
}

dependencies() {
  dnfList=$(dnf list --installed 2>/dev/null)
  dnfUpgradesList=$(dnf --refresh list --upgrades 2>/dev/null)
  pkgInstall "bash"
  pkgInstall "grep"
  pkgInstall "gawk"
  pkgInstall "sed"
  pkgInstall "curl"
  pkgInstall "aria2"
  pkgInstall "jq"
  pkgInstall "bsdtar"
  pkgInstall "pv"
}
[ $AutoUpdatesDependencies == true ] && checkInternet && dependencies