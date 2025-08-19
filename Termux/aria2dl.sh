#!/usr/bin/bash

# --- Downloading latest aria2dl.sh file from GitHub ---
curl -o "$HOME/.aria2dl.sh" "https://raw.githubusercontent.com/arghya339/aria2dl/refs/heads/main/Termux/aria2dl.sh" > /dev/null 2>&1

if [ ! -f "$PREFIX/bin/aria2dl" ]; then
  ln -s $HOME/.aria2dl.sh $PREFIX/bin/aria2dl  # symlink (shortcut of aria2dl.sh)
fi
chmod +x $HOME/.aria2dl.sh  # give execute permission to aria2dl

# --- Colored log indicators ---
good="\033[92;1m[✔]\033[0m"
bad="\033[91;1m[✘]\033[0m"
info="\033[94;1m[i]\033[0m"
running="\033[37;1m[~]\033[0m"
notice="\033[93;1m[!]\033[0m"
question="\033[93;1m[?]\033[0m"

# --- ANSI Color ---
Green="\033[92m"
Red="\033[91m"
Blue="\033[94m"
TrueBlue='\033[38;5;021m'
skyBlue="\033[38;5;117m"
Cyan="\033[96m"
White="\033[37m"
Yellow="\033[93m"
Reset="\033[0m"

print_aria2dl() {
  FMT_RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
      $(printf '\033[36m')
      $(printf '\033[38;5;021m')
      $(printf '\033[38;5;093m')
    "
  FMT_RESET=$(printf '\033[0m')
  
  # Construct the aria2dl shape using string concatenation (ANSI Slant Font)
  echo -e "${TrueBlue}https://github.com/arghya339/aria2dl${Reset}"
  printf '%s        %s     %s _ %s    %s ___ %s      __%s__%s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s  ____ _%s_____%s(_)%s___ %s|__ \%s ____/ /%s /%s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s / __ `/%s ___/%s /%s __ `/%s_/ /%s/ __  /%s / %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s/ /_/ /%s /  %s/ /%s /_/ /%s __/%s/ /_/ /%s /  %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s\__,_/%s_/  %s/_/%s\__,_/%s____/%s\__,_/%s_/   %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s    %s    %s%s>_𝒟𝑒𝓋𝑒𝓁𝑜𝓅𝑒𝓇: @𝒶𝓇𝑔𝒽𝓎𝒶𝟥𝟥𝟫%s%s%s  %s\n'    $FMT_RAINBOW $FMT_RESET
  printf '\n'
  printf '\n'
}

# --- Storage Permission Check Logic ---
if [ ! -d "$HOME/storage/shared" ]; then
    # Attempt to list /storage/emulated/0 to trigger the error
    error=$(ls /storage/emulated/0 2>&1)
    expected_error="ls: cannot open directory '/storage/emulated/0': Permission denied"

    if echo "$error" | grep -qF "$expected_error" || ! echo "$error" | grep -q "^Android"; then
        echo -e "${notice} Storage permission not granted. Running ${Green}termux-setup-storage${Reset}.."
        termux-setup-storage
        exit 1  # Exit the script after handling the error
    else
        echo -e "${bad} Unknown error: ${Red}$error${Reset}"
        exit 1  # Exit on any other error
    fi
fi

# --- Checking Internet Connection ---
if ! ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1 ; then
  echo -e "${bad} ${Red} Oops! No Internet Connection available.\nConnect to the Internet and try again later."
  exit 1
fi

clear && echo -e "🚀 ${Yellow}Please wait! starting aria2dl...${Reset}"

# --- Global Variables ---
UA="Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Mobile Safari/537.36"  # HTML User Agent
cfIP="1.1.1.1,1.0.0.1"  # cloudflare pub-dns IP Address
cfDOH="https://cloudflare-dns.com/dns-query"  # cloudflare pub dns-over-https address
dl_dir="/sdcard/Download"  # Download dir
outdatedPKG=$(apt list --upgradable 2>/dev/null)  # get list of Termux outdated pkg
installedPKG=$(pkg list-installed 2>/dev/null)  # get list of Termux installed pkg
mkdir -p "$dl_dir"  # create $dl_dir if it doesn't exist
Android=$(getprop ro.build.version.release | cut -d. -f1)  # Get major Android version
apMode=$(getprop persist.radio.airplane_mode_on)  # Get AirPlane Mode Status (0=OFF; 1=ON)
networkType1=$(getprop gsm.network.type | cut -d',' -f1)  # Get SIM1 Network type (NR_SA/NR_NSA,LTE)
networkType2=$(getprop gsm.network.type | cut -d',' -f2)  # Get SIM2 Network type (NR_SA/NR_NSA,LTE)
networkName1=$(getprop gsm.operator.alpha | cut -d',' -f1)  # Get SIM1 Carrier name
networkName2=$(getprop gsm.operator.alpha | cut -d',' -f2)  # Get SIM2 Carrier name
simOperator1=$(getprop gsm.sim.operator.alpha | cut -d',' -f1)  # Get SIM1 Operator name
simOperator2=$(getprop gsm.sim.operator.alpha | cut -d',' -f2)  # Get SIM2 Operator name

# --- pkg upgrade function ---
pkgUpdate() {
  local pkg=$1
  if echo $outdatedPKG | grep -q "^$pkg/" 2>/dev/null; then
    echo -e "$running Upgrading $pkg pkg.."
    pkg upgrade "$pkg" -y > /dev/null 2>&1
  fi
}

# --- pkg install/update function ---
pkgInstall() {
  local pkg=$1
  if echo "$installedPKG" | grep -q "^$pkg/" 2>/dev/null; then
    pkgUpdate "$pkg"
  else
    echo -e "$running Installing $pkg pkg.."
    pkg install "$pkg" -y > /dev/null 2>&1
  fi
}

pkgInstall "bash"  # bash update
pkgInstall "curl"  # curl update
pkgInstall "aria2"  # aria2 install/update
pkgInstall "bsdtar"  # bsdtar install/update
pkgInstall "pv"  # pv install/update

# --- Shizuku Setup first time ---
if [ ! -f "$HOME/rish" ] || [ ! -f "$HOME/rish_shizuku.dex" ]; then
  termux-open-url "https://play.google.com/store/apps/details?id=moe.shizuku.privileged.api"
  curl -sL -o "$HOME/rish" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish" && chmod +x "$HOME/rish"
  sleep 0.5 && curl -sL -o "$HOME/rish_shizuku.dex" "https://raw.githubusercontent.com/arghya339/crdl/refs/heads/main/Termux/Shizuku/rish_shizuku.dex"
  if [ $Android -le 10 ]; then
    am start -n com.android.settings/.Settings\$DevelopmentSettingsDashboardActivity > /dev/null 2>&1  # Open Developer options
    termux-open-url "https://youtu.be/ZxjelegpTLA"  # YouTube/@MrPalash360: Start Shizuku using Computer
  else
    am start -n com.android.settings/.Settings\$WirelessDebuggingActivity > /dev/null 2>&1  # Open Wireless Debugging Settings
    termux-open-url "https://youtu.be/YRd0FBfdntQ"  # YouTube/@MrPalash360: Start Shizuku Android 11+
  fi
  exit 1
fi

# --- prompt user to enter download url ---
while true; do
  clear
  print_aria2dl  # Call the print aria2dl shape function
  read -p "Enter download Url: " dlUrl
  Referer=$(echo "$dlUrl" | awk -F/ '{print $1"//"$3"/"}')  # extract base domain from dlUrl
  http_status=$(curl -sL --head --silent --fail --doh-url "$cfDOH" -A "$UA" -H "Referer: $Referer" "$dlUrl" 2>/dev/null)  # Check HTTP status code
  if [ "$http_status" != "404" ] || [ "$http_status" == "302" ] || [ "$http_status" == "200" ] || [ "$http_status" == "403" ]; then
    echo && break
  else
    echo -e "$notice Given Url invalid! Please enter a valid Url." && sleep 3 && clear
  fi
done

# --- Variables ----
Referer=$(echo "$dlUrl" | awk -F/ '{print $1"//"$3"/"}')  # extract base domain from dlUrl
fileName=$(curl -sIL --doh-url "$cfDOH" -A "$UA" -H "Referer: $Referer" "$dlUrl" | grep -i '^location:\|content-disposition' | sed -n 's/.*filename=//p' | tail -1 | tr -d '\r"' | sed 's/.*\///')  # get fileName from dlUrl using curl
fileSize=$(curl -sIL $dlUrl 2>/dev/null | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }' 2>/dev/null)  # dl file size
if [ -z "$fileName" ]; then
  fileName=$(echo "$dlUrl" | awk -F'/' '{print $6}' | sed 's/%20/ /g; s/?.*//')  # seedr.cc dlUrl pattern
fi
# If File Has an Extension Extract it
if [[ $dlUrl == *"archive"* ]]; then
  while true; do
    > aria2dl_log.txt  # Clear previous log
    aria2c -x 16 -s 16 --continue=true --console-log-level=error --download-result=hide --summary-interval=0 -d "$HOME" -o "$fileName" -U "User-Agent: $UA" -U "Referer: $referUrl" --async-dns=true --async-dns-server="$cfIP" "$dlUrl" >> aria2dl_log.txt 2>&1 &
    aria2ProcessId=$!
    sleep 3  # Wait a moment for the log file to start being written
    if grep -q "[0-9]*%" aria2dl_log.txt; then
      kill $aria2ProcessId 2>/dev/null  # Stop aria2c process
      wait $aria2ProcessId 2>/dev/null  # Wait for it to terminate
      rm -rf "$fileName"
      rm -rf "$fileName.aria2"
      direct_url=$(grep -o 'URI=https://rd[0-9]*\.seedr\.cc/[^ ]*' aria2dl_log.txt | head -1 | sed 's/URI=//')
      rm -f aria2dl_log.txt
      encoded_fileName=$(echo "$direct_url" | sed 's/.*\///; s/?.*//')  # Extract everything after last / and before ?
      decoded_fileName=$(echo "$encoded_fileName" | sed 's/%20/ /g')  # replace %20 with space
      decoded_fileSize=$(echo "$encoded_fileName" | sed 's/%20/ /g' | awk -F' - ' '{print $NF}' | sed 's/\.[^.]*$//')  # Extract after last - and before .
      [ -z "$fileSize" ] && fileSize="$decoded_fileSize"
      break
    fi
  done
  fileName="$decoded_fileName"
  file_ext="zip"
elif [[ "$fileName" == *.* ]]; then
  file_ext="${fileName##*.}"
fi
output_path="$dl_dir/$fileName"  # save location of downloaded file



# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  clear  # clear aria2 multi error log from console
  print_aria2dl  # call the print_aria2dl function
  echo "Enter download Url: $dlUrl" && echo
  echo "[?] Do you want to download ${Red}$fileName${Reset} - $fileSize [Y/n]: $opt"
}

# --- Download file using aria2 ---
dl() {
  while true; do
    echo -e "$running Direct Downloading ${Red}$fileName${Reset} from ${Blue}$dlUrl${Reset} using aria2.."
    aria2c -x 16 -s 16 --continue=true --console-log-level=error --download-result=hide --summary-interval=0 -d "$dl_dir" -o "$fileName" -U "User-Agent: $UA" -U "Referer: $referUrl" --async-dns=true --async-dns-server="$cfIP" "$dlUrl"
    if [ $? == 0 ]; then
      echo  # space after aria2 progress-bar
      echo -e "$good Download complete with aria2c. Download file save to ${Cyan}$output_path${Reset}"
      break
    elif [ $? -eq "56" ] || [ $? -eq "1" ]; then
      aria2ConsoleLogHide  # call the aria2 console log hide function
      echo -e "$bad $networkName1 / $networkName2 signal are unstable!"
      echo -e "$info If Mobile data is turned on for SIM1, please switch Mobile data to SIM2: $simOperator2; else switch data to SIM1: $simOperator1"
      am start -a android.settings.MANAGE_ALL_SIM_PROFILES_SETTINGS > /dev/null 2>&1
      if [[ "$networkType1" == "GSM" || "$networkType1" == "WCDMA" || "$networkType1" == "UMTS" || "$networkType2" == "GSM" || "$networkType2" == "WCDMA" || "$networkType2" == "UMTS" ]]; then
        echo -e "$info Please select Network Type: LTE/NR"
        am start -n com.android.phone/.settings.RadioInfo > /dev/null 2>&1  # Open Redio Info
      fi
      if [ "$apMode" -eq 1 ]; then
        echo -e "$notice Please turn off Airplane mode!"
        am start -a android.settings.WIRELESS_SETTINGS > /dev/null 2>&1
      fi
      echo -e "$bad Download failed! Retrying in 5 seconds.." && sleep 5  # wait 5 sec
      #echo -e "$running fallback to curl.."
      #curl -L --progress-bar -C - -o "$output_path" --doh-url "$cfDOH" -A "$UA" -H "Referer: $Referer" "$dlUrl"
    elif [ $? != 0 ]; then
      aria2ConsoleLogHide  # call the aria2 console log hide function
      echo -e "$bad Download failed! Retrying in 5 seconds.." && sleep 5  # wait 5 sec
    fi
  done
}

apkInstall() {
  if su -c "id" >/dev/null 2>&1; then
    su -c "cp '$output_path' '/data/local/tmp/$fileName'"
    # Temporary Disable SELinux Enforcing during installation if it not in Permissive
    if [ "$(su -c 'getenforce 2>/dev/null')" = "Enforcing" ]; then
      su -c "setenforce 0"  # set SELinux to Permissive mode to unblock unauthorized operations
      su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
      su -c "setenforce 1"  # set SELinux to Enforcing mode to block unauthorized operations
     else
      su -c "pm install -i com.android.vending '/data/local/tmp/$fileName'"
    fi
    su -c "rm '/data/local/tmp/$fileName'"
  elif "$HOME/rish" -c "id" >/dev/null 2>&1; then
    ~/rish -c "cp '$output_path' '/data/local/tmp/$fileName'"
    ./rish -c "pm install -r -i com.android.vending '/data/local/tmp/$fileName'" > /dev/null 2>&1  # -r=reinstall --force-uplow=downgrade
    $HOME/rish -c "rm '/data/local/tmp/$fileName'"
  elif [ $Android -le 7 ]; then
    termux-open "$output_path"  # open file in pm
  else
    am start -a android.intent.action.VIEW -t application/vnd.android.package-archive -d "file://${output_path}"
  fi
}

# --- ask the user if they want to download ---
while true; do
  echo -e "[?] Do you want to download ${Red}$fileName${Reset} - $fileSize [Y/n]: \c" && read opt
  case $opt in
    y*|Y*|"")
      dl  # Call the download function
      if [ "$file_ext" == "apk" ]; then
        echo -e "Do you want to install ${Red}$fileName${Reset} [Y/n]: \c" && read options
        case $options in
          y*|Y*|"")
            apkInstall  # Call the apk Install function
            ;;
          n*|N*) 
            echo -e "$notice ${Red}$fileName${Reset} installation skiped by user!"
            ;;
          *) echo -e "$info Invalid choice! installation skiped!"
        esac
      elif [ "$file_ext" == "zip" ]; then
        echo -e "Do you want to extract archive ${Red}$fileName${Reset} [Y/n]: \c" && read options
        case $options in
          y*|Y*|"")
            #base_name="${fileName%.*}"
            #mkdir -p "$dl_dir/$base_name"
            pv "$output_path" | bsdtar -xf - -C "$dl_dir/"
            rm -f "$dl_dir/$base_name"
            ;;
            n*|N*) 
            echo -e "$notice ${Red}$fileName${Reset} archive extracting skiped by user!"
            ;;
          *) echo -e "$info Invalid choice! archive extracting skiped!"
        esac
      elif [ "$file_ext" == "iso" ]; then
        am start -n "eu.depau.etchdroid/.ui.MainActivity" >/dev/null 2>&1
        [ $? != 0 ] && termux-open-url "https://github.com/etchdroid/etchdroid/releases"
      else
        termux-open --send "$output_path"  # open & share dl file
      fi
      break
      ;;
    n*|N*)
      echo -e "$notice Download cancel by user!"
      break  # break the while loop
      ;;
    *) echo -e "$info Invalid choice! Please select valid options." && sleep 3 ;;
  esac
done
#################################################################################