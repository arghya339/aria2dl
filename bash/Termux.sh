#!/usr/bin/bash

if [ -f "$BingWallpaperJson" ]; then
  AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$aria2Json" 2>/dev/null)
  AutoUpdatesTermux=$(jq -r '.AutoUpdatesTermux' "$aria2Json" 2>/dev/null)
else
  AutoUpdatesDependencies=true
  AutoUpdatesTermux=true
fi

su -c "id" &>/dev/null && su=true || su=false

Android=$(getprop ro.build.version.release | cut -d. -f1)  # Get major Android version

# --- Storage Permission Check Logic ---
if ! ls /sdcard/ 2>/dev/null | grep -qE "^(Android|Download)"; then
  echo -e "$notice ${Yellow}Storage permission not granted!${Reset}\n$running ${Green}termux-setup-storage${Reset}.."
  if [ $Android -gt 5 ]; then  # for Android 5 storage permissions grant during app installation time, so Termux API termux-setup-storage command not required
    count=0
    while true; do
      if [ $count -ge 2 ]; then
        echo -e "$bad Failed to get storage permissions after $count attempts!"
        echo -e "$notice Please grant permissions manually in Termux App info > Permissions > Files > File permission → Allow."
        am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:com.termux &> /dev/null
        exit 0
      fi
      termux-setup-storage  # ask Termux Storage permissions
      sleep 3  # wait 3 seconds
      if ls /sdcard/ 2>/dev/null | grep -q "^Android" || ls "$HOME/storage/shared/" 2>/dev/null | grep -q "^Android"; then
        [ $Android -lt 8 ] && exit 0  # Exit the script
        break
      fi
      ((count++))
    done
  fi
fi

# --- enabled allow-external-apps ---
isOverwriteTermuxProp=0
if [ $Android -eq 6 ] && [ ! -f "$HOME/.termux/termux.properties" ]; then
  mkdir -p "$HOME/.termux" && echo "allow-external-apps = true" > "$HOME/.termux/termux.properties"
  isOverwriteTermuxProp=1
  echo -e "$notice 'termux.properties' file has been created successfully & 'allow-external-apps = true' line has been add (enabled) in Termux \$HOME/.termux/termux.properties."
  termux-reload-settings
elif [ $Android -eq 6 ] && [ -f "$HOME/.termux/termux.properties" ]; then
  if grep -q "^# allow-external-apps" "$HOME/.termux/termux.properties"; then
    sed -i '/allow-external-apps/s/# //' "$HOME/.termux/termux.properties"  # uncomment 'allow-external-apps = true' line
    isOverwriteTermuxProp=1
    echo -e "$notice 'allow-external-apps = true' line has been uncommented (enabled) in Termux \$HOME/.termux/termux.properties."
    termux-reload-settings
  fi
fi
if [ $Android -ge 6 ]; then
  if grep -q "^# allow-external-apps" "$HOME/.termux/termux.properties"; then
    # other Android applications can send commands into Termux.
    # termux-open utility can send an Android Intent from Termux to Android system to open apk package file in pm.
    # other Android applications also can be Access Termux app data (files).
    sed -i '/allow-external-apps/s/# //' "$HOME/.termux/termux.properties"  # uncomment 'allow-external-apps = true' line
    isOverwriteTermuxProp=1
    echo -e "$notice 'allow-external-apps = true' line has been uncommented (enabled) in Termux \$HOME/.termux/termux.properties."
    #if [ "$Android" -eq 7 ] || [ "$Android" -eq 6 ]; then
      termux-reload-settings  # reload (restart) Termux settings required for Android 6 after enabled allow-external-apps, also required for Android 7 due to 'Package installer has stopped' err
    #fi
  fi
fi

# --- Shizuku Setup first time ---
if [ $su == false ] && { [ ! -f "$HOME/rish" ] || [ ! -f "$HOME/rish_shizuku.dex" ]; }; then
  #echo -e "$info Please manually install Shizuku from Google Play Store." && sleep 1
  #termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  echo -e "$info Please manually install Shizuku from GitHub." && sleep 1
  termux-open-url "https://github.com/RikkaApps/Shizuku/releases/latest"
  am start -n com.android.settings/.Settings\$MyDeviceInfoActivity > /dev/null 2>&1  # Open Device Info

  curl -sL -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Shizuku/rish" && chmod +x "$HOME/rish"
  sleep 0.5 && curl -sL -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Shizuku/rish_shizuku.dex"
  
  if [ "$Android" -lt 11 ]; then
    url="https://youtu.be/ZxjelegpTLA"  # YouTube/@MrPalash360: Start Shizuku using Computer
    activityClass="com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity"  # Open Developer options
  else
    activityClass="com.android.settings/.Settings\$WirelessDebuggingActivity"  # Open Wireless Debugging Settings
    url="https://youtu.be/YRd0FBfdntQ"  # YouTube/@MrPalash360: Start Shizuku Android 11+
  fi
  echo -e "$info Please start Shizuku by following guide: $url" && sleep 1
  am start -n "$activityClass" &>/dev/null
  termux-open-url "$url"
fi
if ! "$HOME/rish" -c "id" &>/dev/null && [ -f "$HOME/rish_shizuku.dex" ]; then
  if ~/rish -c "id" 2>&1 | grep -q 'java.lang.UnsatisfiedLinkError'; then
    rm -f "$HOME/rish_shizuku.dex" && curl -sL -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Shizuku/Play/rish_shizuku.dex"
  fi
fi

# Only for Genymotion (Android Emulator)
if [ "$(getprop ro.product.manufacturer)" == "Genymobile" ] && [ ! -f "$HOME/adb" ]; then
  curl -sL -o "$HOME/adb" "https://raw.githubusercontent.com/rendiix/termux-adb-fastboot/refs/heads/master/binary/$(getprop ro.product.cpu.abi)/bin/adb" && chmod +x ~/adb
fi

pkgUpdate() {
  pkg=$1
  if echo "$outdatedPkg" | grep -q "^$pkg/" 2>/dev/null; then
    echo -e "$running Upgrading $pkg pkg.."
    output=$(yes "N" | apt install --only-upgrade "$pkg" -y 2>/dev/null)
    echo "$output" | grep -q "dpkg was interrupted" 2>/dev/null && { yes "N" | dpkg --configure -a; yes "N" | apt install --only-upgrade "$pkg" -y > /dev/null 2>&1; }
  fi
}

pkgInstall() {
  pkg=$1
  if echo "$installedPkg" | grep -q "^$pkg/" 2>/dev/null; then
    pkgUpdate "$pkg"
  else
    echo -e "$running Installing $pkg pkg.."
    pkg install "$pkg" -y > /dev/null 2>&1
  fi
}

pkgUninstall() {
  installedPkg=$(pkg list-installed 2>/dev/null)
  pkg=$1
  if echo "$installedPkg" | grep -q "^$pkg/" 2>/dev/null; then
    echo -e "$running Uninstalling $pkg pkg.."
    pkg uninstall "$pkg" -y > /dev/null 2>&1
  fi
}

dependencies() {
  installedPkg=$(pkg list-installed 2>/dev/null)  # list of installed pkg
  pkg update > /dev/null 2>&1 || apt update >/dev/null 2>&1  # It downloads latest package list with versions from Termux remote repository, then compares them to local (installed) pkg versions, and shows a list of what can be upgraded if they are different.
  outdatedPkg=$(apt list --upgradable 2>/dev/null)  # list of outdated pkg
  echo "$outdatedPkg" | grep -q "dpkg was interrupted" 2>/dev/null && { yes "N" | dpkg --configure -a; outdatedPkg=$(apt list --upgradable 2>/dev/null); }
  
  pkgInstall "apt"  # apt update
  pkgInstall "dpkg"  # dpkg update
  pkgInstall "bash"  # bash update
  pkgInstall "libgnutls"  # pm apt & dpkg use it to securely download packages from repositories over HTTPS
  pkgInstall "coreutils"  # It provides basic file, shell, & text manipulation utilities. such as: ls, cp, mv, rm, mkdir, cat, echo, etc.
  pkgInstall "termux-core"  # it's contains basic essential cli utilities, such as: ls, cp, mv, rm, mkdir, cat, echo, etc.
  pkgInstall "termux-tools"  # it's provide essential commands, sush as: termux-change-repo, termux-setup-storage, termux-open, termux-share, etc.
  pkgInstall "termux-keyring"  # it's use during pkg install/update to verify digital signature of the pkg and remote repository
  pkgInstall "termux-am"  # termux am (activity manager) update
  pkgInstall "termux-am-socket"  # termux am socket (when run: am start -n activity ,termux-am take & send to termux-am-stcket and it's send to Termux Core to execute am command) update
  pkgInstall "inetutils"  # ping utils is provided by inetutils
  pkgInstall "util-linux"  # it provides: kill, killall, uptime, uname, chsh, lscpu
  pkgInstall "libsmartcols"  # a library from the util-linux pkg
  pkgInstall "grep"  # grep update
  pkgInstall "gawk"  # gnu awk update
  pkgInstall "sed"  # sed update
  pkgInstall "curl"  # curl update
  pkgInstall "libcurl"  # curl lib update
  pkgInstall "openssl"  # openssl install/update
  pkgInstall "aria2"  # aria2 install/update
  pkgInstall "bsdtar"  # bsdtar install/update
  pkgInstall "pv"  # pv install/update
}
[ "$AutoUpdatesDependencies" == true ] && checkInternet && dependencies

apkInstall() {
  filePath=${1}
  fileName=$(basename $filePath)
  if [ $su == true ]; then
    su -c "cp '$filePath' '/data/local/tmp/$fileName'"
    # Temporary Disable SELinux Enforcing during installation if it not in Permissive
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c "pm install -r -i com.android.vending '/data/local/tmp/$fileName'"
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
     else
      su -c "pm install -r -i com.android.vending '/data/local/tmp/$fileName'"
    fi
    su -c "rm -f '/data/local/tmp/$fileName'"
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c "cp '$filePath' '/data/local/tmp/$fileName'"
    ./rish -c "pm install -r -i com.android.vending '/data/local/tmp/$fileName'" > /dev/null 2>&1  # -r=reinstall
    $HOME/rish -c "rm -f '/data/local/tmp/$fileName'"
  elif "$HOME/adb" -s $(~/adb devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell "id" >/dev/null 2>&1; then
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cp $filePath /data/local/tmp/$fileName
    ~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell pm install -r -i com.android.vending "/data/local/tmp/$fileName" > /dev/null 2>&1
    #~/adb -s $("$HOME/adb" devices 2>/dev/null | grep "device$" | awk '{print $1}' | tail -1) shell cmd package install -r -i com.android.vending "$output_path" > /dev/null 2>&1
  elif [ $Android -le 6 ]; then
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file://${filePath}"
  else
    termux-open --view "$filPath"
  fi
}

# --- Create aria2dl shortcut on Laucher Home ---
if [ ! -f "$HOME/.shortcuts/aria2dl" ] || [ ! -f "$HOME/.termux/widget/dynamic_shortcuts/aria2dl" ]; then
  echo -e "$notice Please wait few seconds! Creating aria2dl shortcut to access aria2dl from Launcher Widget."
  mkdir -p ~/.shortcuts  # create $HOME/.shortcuts dir if it not exist
  echo -e "#!/usr/bin/bash\nbash \$PREFIX/bin/aria2dl" > ~/.shortcuts/aria2dl  # create aria2dl shortcut script
  mkdir -p ~/.termux/widget/dynamic_shortcuts
  echo -e "#!/usr/bin/bash\nbash \$PREFIX/bin/aria2dl" > ~/.termux/widget/dynamic_shortcuts/aria2dl  # create aria2dl dynamic shortcut script
  chmod +x ~/.termux/widget/dynamic_shortcuts/aria2dl  # give execute (--x) permissions to aria2dl script
  if ! am start -n com.termux.widget/com.termux.widget.TermuxLaunchShortcutActivity > /dev/null 2>&1; then
    # Download Termux:Widget app from GitHub
    tag=$(curl -s https://api.github.com/repos/termux/termux-widget/releases/latest | jq -r '.tag_name | sub("^v"; "")')
    fileName="termux-widget-app_v$tag+github.debug.apk"
    dlURL="https://github.com/termux/termux-widget/releases/download/v$tag/$fileName"
    filePath="$Download/$fileName"
    while true; do
      curl -L --progress-bar -C - -o "$filePath" "$dlURL"
      [ $? -eq 0 ] && break || { echo -e "$notice Download failed! Retrying in 5 seconds.."; sleep 5; }
    done
    apkInstall "$filePath"  # Install Termux:Widget app using apkInstall functions
  else
    filePath=$(find "$Download" -type f -name "termux-widget-app_v*+github.debug.apk" -print -quit)
    [ -f "$filePath" ] && rm -f "$filePath"  # if Termux:Widget app package exist then remove it 
  fi
  if [ $su == true ]; then
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
      su -c "cmd deviceidle whitelist +com.termux"
      su -c "cmd appops set com.termux SYSTEM_ALERT_WINDOW allow"
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
    else
      su -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
      su -c "cmd deviceidle whitelist +com.termux"
      su -c "cmd appops set com.termux SYSTEM_ALERT_WINDOW allow"
    fi
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c 'pm grant com.termux android.permission.POST_NOTIFICATIONS'
    ~/rish -c "cmd deviceidle whitelist +com.termux"
    $HOME/rish -c "cmd appops set com.termux REQUEST_INSTALL_PACKAGES allow"
    $HOME/rish -c "cmd appops set com.termux.widget REQUEST_INSTALL_PACKAGES allow"
    $HOME/rish -c "cmd appops set com.termux SYSTEM_ALERT_WINDOW allow"
  else
    echo -e "$info Please manually turn on: ${Green}Display over other apps → Termux → Allow display over other apps${Reset}" && sleep 6
    am start -a android.settings.action.MANAGE_OVERLAY_PERMISSION &> /dev/null  # open manage overlay permission settings
  fi
  echo -e "$info Please Disabled: ${Green}Battery optimization → Not optimized → All apps → Termux → Don't optiomize → DONE${Reset}" && sleep 6
  am start -n com.android.settings/.Settings\$HighPowerApplicationsActivity &> /dev/null
  echo -e "$info From Termux:Widget app tap on ${Green}aria2dl → Add to home screen${Reset}. Opening Termux:Widget app in 6 seconds.." && sleep 6
  am start -n com.termux.widget/com.termux.widget.TermuxCreateShortcutActivity > /dev/null 2>&1  # open Termux:Widget app shortcut create activity (screen/view) to add shortcut on Launcher Home
fi
