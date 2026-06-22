#!/bin/bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

[ -f "$BingWallpaperJson" ] && AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$aria2Json" 2>/dev/null) || AutoUpdatesDependencies=true

pkgUpdate() {
  formulae=$1
  if echo "$outdatedFormulae" | grep -q "^$formulae" 2>/dev/null; then
    echo -e "$running Upgrading $formulae formulae.."
    brew upgrade "$formulae" > /dev/null 2>&1
  fi
}

pkgInstall() {
  formulae=$1
  if echo "$formulaeList" | grep -q "$formulae" 2>/dev/null; then
    pkgUpdate "$formulae"
  else
    echo -e "$running Installing $formulae formulae.."
    brew install "$formulae" > /dev/null 2>&1
  fi
}

pkgUninstall() {
  formulaeList=$(brew list 2>/dev/null)
  formulae=$1
  if echo "$formulaeList" | grep -q "$formulae" 2>/dev/null; then
    echo -e "$running Uninstalling $formulae formulae.."
    brew uninstall "$formulae" > /dev/null 2>&1
  fi
}

dependencies() {
  formulaeList=$(brew list 2>/dev/null)
  outdatedFormulae=$(brew outdated 2>/dev/null)
  
  brew --version &>/dev/null && brew update &> /dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  pkgInstall "bash"
  pkgInstall "grep"
  pkgInstall "curl"
  pkgInstall "aria2"
  pkgInstall "jq"
  pkgInstall "pv"
}
[ $AutoUpdatesDependencies == true ] && checkInternet && dependencies