#!/usr/bin/env bash

# Copyright (C) 2025, Arghyadeep Mondal <github.com/arghya339>

good="\033[92;1m[✔]\033[0m"
bad="\033[91;1m[✘]\033[0m"
info="\033[94;1m[i]\033[0m"
running="\033[37;1m[~]\033[0m"
notice="\033[93;1m[!]\033[0m"
question="\033[93;1m[?]\033[0m"

Green="\033[92m"
Red="\033[91m"
Blue="\033[94m"
TrueBlue='\033[38;5;021m'
skyBlue="\033[38;5;117m"
Cyan="\033[96m"
White="\033[37m"
whiteBG="\e[47m\e[30m"
Yellow="\033[93m"
Reset="\033[0m"

checkInternet() {
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    return
  else
    echo -e "$bad ${Red}No Internet Connection available!${Reset}"
    return 1
  fi
}

isMacOS=false; isAndroid=false; isFedora=false
if [[ "$(uname)" == "Darwin" ]]; then
  isMacOS=true; scripts=(macOS)
elif [[ -d "/sdcard" ]] && [[ -d "/system" ]]; then
  isAndroid=true; scripts=(Termux)
elif [[ -f "/etc/os-release" ]]; then
  if grep -qi "fedora" /etc/os-release 2>/dev/null; then
    isFedora=true; scripts=(Fedora)
  fi
fi
scripts+=(menu confirmPrompt)

aria2dl="$HOME/.aria2dl"
mkdir -p $aria2dl
aria2Json="$aria2dl/aria2dl.json"
[ $isAndroid == true ] && Download="/sdcard/Download" || Download="$HOME/Downloads"
read rows cols < <(stty size)
eButtons=("<Select>" "<Exit>")
bButtons=("<Select>" "<Back>")
ynButtons=("<Yes>" "<No>")
tfButtons=("<true>" "<false>")

run() { for ((c=0; c<${#scripts[@]}; c++)); do source $aria2dl/${scripts[c]}.sh; done; }

[ -f "$aria2dl/.version" ] && localVersion=$(cat "$aria2dl/.version") || localVersion=
checkInternet &>/dev/null && remoteVersion=$(curl -sL "https://raw.githubusercontent.com/arghya339/aria2dl/refs/heads/main/bash/.version") || remoteVersion="$localVersion"
updates() {
  curl -sL -o "$aria2dl/.version" "https://raw.githubusercontent.com/arghya339/aria2dl/refs/heads/main/bash/.version"
  curl -sL -o "$HOME/.aria2dl.sh" "https://raw.githubusercontent.com/arghya339/aria2dl/refs/heads/main/bash/aria2dl.sh"
  if [ $isAndroid == true ]; then
    [ ! -f "$PREFIX/bin/aria2dl" ] && ln -s ~/.aria2dl.sh $PREFIX/bin/aria2dl
  elif [ $isMacOS == true ]; then
    [ ! -f "/usr/local/bin/aria2dl" ] && ln -s $HOME/.aria2dl.sh /usr/local/bin/aria2dl
  else
    [ ! -f "/usr/local/bin/aria2dl" ] && sudo ln -s $HOME/.aria2dl.sh /usr/local/bin/aria2dl
  fi
  [ ! -x $HOME/.aria2dl.sh ] && chmod +x $HOME/.aria2dl.sh
  curl -sL -o $aria2dl/menu.sh https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/next/bash/menu.sh
  curl -sL -o $aria2dl/confirmPrompt.sh https://raw.githubusercontent.com/arghya339/Simplify/refs/heads/next/bash/confirmPrompt.sh
  curl -sL -o "$aria2dl/${scripts[0]}.sh" "https://raw.githubusercontent.com/arghya339/aria2dl/refs/heads/main/bash/${scripts[0]}.sh"
  for ((c=0; c<${#scripts[@]}; c++)); do
    source $aria2dl/${scripts[c]}.sh
  done
}
[ -f "$aria2Json" ] && AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$aria2Json" 2>/dev/null) || AutoUpdatesScript=true
if [ $AutoUpdatesScript == true ]; then
  [ "$remoteVersion" != "$localVersion" ] && { checkInternet && updates && localVersion="$remoteVersion"; } || run
else
  run
fi

config() {
  key="$1"
  value="$2"
  
  [ ! -f "$aria2Json" ] && jq -n "{}" > "$aria2Json"
  jq --arg key "$key" --arg value "$value" '.[$key] = $value' "$aria2Json" > temp.json && mv temp.json "$aria2Json"
}

all_key=(AutoUpdatesScript AutoUpdatesDependencies)
all_value=(true true)
[ $isAndroid == true ] && { all_key+=(AutoUpdatesTermux); all_value+=(true); }
for i in "${!all_key[@]}"; do
  ! jq -e --arg key "${all_key[i]}" 'has($key)' "$aria2Json" &>/dev/null && config "${all_key[i]}" "${all_value[i]}"
done

reloadConfig() {
  AutoUpdatesScript=$(jq -r '.AutoUpdatesScript' "$aria2Json" 2>/dev/null)
  AutoUpdatesDependencies=$(jq -r '.AutoUpdatesDependencies' "$aria2Json" 2>/dev/null)
  AutoUpdatesTermux=$(jq -r '.AutoUpdatesTermux' "$aria2Json" 2>/dev/null)
}; reloadConfig

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
  
  printf '%s        %s     %s _ %s    %s ___ %s      __%s__%s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s  ____ _%s_____%s(_)%s___ %s|__ \%s ____/ /%s /%s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s / __ `/%s ___/%s /%s __ `/%s_/ /%s/ __  /%s / %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s/ /_/ /%s /  %s/ /%s /_/ /%s __/%s/ /_/ /%s /  %s\n' $FMT_RAINBOW $FMT_RESET
  printf '%s\__,_/%s_/  %s/_/%s\__,_/%s____/%s\__,_/%s_/   %s\n' $FMT_RAINBOW $FMT_RESET
  printf '\n'
}

rm_aria2dl() {
  if [ $isAndroid == true ]; then
    [ -f "$PREFIX/bin/aria2dl" ] && rm -f $PREFIX/bin/aria2dl
    [ -f "$HOME/.shortcuts/aria2dl" ] && rm -f ~/.shortcuts/aria2dl
    [ -f "$HOME/.termux/widget/dynamic_shortcuts/aria2dl" ] && rm -f ~/.termux/widget/dynamic_shortcuts/aria2dl
  elif [ $isMacOS == true ]; then
    [ -f "/usr/local/bin/aria2dl" ] && rm -f /usr/local/bin/aria2dl
  else
    [ -f "/usr/local/bin/aria2dl" ] && sudo rm -f /usr/local/bin/aria2dl
  fi
  [ -d "$aria2dl" ] && rm -rf $aria2dl
  [ -f $HOME/.aria2dl.sh ] && rm -f ~/.aria2dl.sh
  #printf '\033[2J\033[3J\033[H'
  echo -e "$good ${Yellow}aria2dl has been uninstalled successfully :(${Reset}"
  echo -e "💔 ${Yellow}We're sorry to see you go. Feel free to reinstall anytime!${Reset}"
  if [ $isAndroid == true ]; then termux-open "https://github.com/arghya339/aria2dl"; elif [ $isMacOS == true ]; then open "https://github.com/arghya339/aria2dl"; else xdg-open "https://github.com/arghya339/aria2dl" &>/dev/null; fi
}

if [ $isAndroid == true ]; then
  ut="
  -U -t, --update -t  Update only termux-app."
  at="
  -A -t, --auto -t    Config only termux-app auto update behaviour on script launch.
                      Default: true"
else
  ut=; at=
fi

h_msg="Usage:	aria2dl [long option] [option] ...
options:
  -h, --help          Show this help message.
  -V, --version       Print version information.
  -U, --update        Update both script and dependencies.
  -U -d, --update -d  Update only dependencies.
  -U -s, --update -s  Update only script.$ut
  -A, --auto          Config both dependencies and script auto update behaviour on script launch.
                      Default: true
  -A -d, --auto -d    Config only dependencies auto update behaviour on script launch.
                      Default: true
  -A -s, --auto -s    Config only script auto update behaviour on script launch.
                      Default: true$at
  -R, --remove        Remove this aria2dl script.
  -R -f, --remove -f  Forcefully remove this aria2dl script.

aria2dl home page: <https://github.com/arghya339/aria2dl>"
print_err_msg() {
  err_msg="aria2dl: $1: invalid option
$h_msg"
  echo "$err_msg"
  return 1
}
if [ -n "$1" ]; then
  case "$1" in
    -h|--help) echo "aria2dl version $localVersion"; echo "$h_msg" ;;
    -V|--version) aria2c --version | head -1; echo "aria2dl version $localVersion" ;;
    -U|--update)
      if [ -n "$2" ]; then
        case "$2" in
          -d) checkInternet && dependencies ;;
          -s) checkInternet && updates ;;
          -t) [ $isAndroid == true ] && { checkInternet && updateTermuxApp; } || { echo "This option unavailable on desktop."; echo "$h_msg"; } ;;
          *) print_err_msg "$2" ;;
        esac
      else
        checkInternet && dependencies && updates
      fi
      ;;
    -A*|--auto*)
      if [ -n "$2" ]; then
        case "$2" in
          -d*)
            case "$2" in
              -d=false) config AutoUpdatesDependencies false ;;
              -d|-d=true) config AutoUpdatesDependencies true ;;
              *) print_err_msg "$2" ;;
            esac
            ;;
          -s*)
            case "$2" in
              -s=false) config AutoUpdatesScript false ;;
              -s|-s=true) config AutoUpdatesScript true ;;
              *) print_err_msg "$2" ;;
            esac
            ;;
          -t*)
            if [ $isAndroid == true ]; then
              case "$2" in
                -t=false) config AutoUpdatesTermux false ;;
                -t|-t=true) config AutoUpdatesTermux true ;;
                *) print_err_msg "$2" ;;
              esac
            else
              echo "This option unavailable on desktop."; echo "$h_msg"
            fi
            ;;
          *) print_err_msg "$2" ;;
        esac
      else
        case "$1" in
          -A=false|--auto=false) config AutoUpdatesScript false; config AutoUpdatesDependencies false ;;
          -A|--auto|-A=true|--auto=true) config AutoUpdatesScript true; config AutoUpdatesDependencies true ;;
          *) print_err_msg "$1" ;;
        esac
      fi
      ;;
    -R*|--remove*)
      if [ -n "$2" ]; then
        case "$2" in
          -f) rm_aria2dl ;;
          *) print_err_msg "$2" ;;
        esac
      else
        confirmPrompt "Are you sure you want to uninstall aria2dl?" "ynButtons" "1" && response=Yes || response=No
        case "$response" in
          Yes)
            echo -ne "${Red}Type 'yes' in capital to continue: ${Reset}" && read -r userInput
            case "$userInput" in
              YES) rm_aria2dl ;;
            esac
            ;;
        esac
      fi
      ;;
    *) print_err_msg "$1" ;;
  esac
  exit
fi

checkInternet && milestone=$(curl -sL "https://chromiumdash.appspot.com/fetch_releases?channel=Stable&platform=Android&num=1" | jq -r '.[0].milestone') || milestone="149"
UA="Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${milestone}.0.0.0 Mobile Safari/537.36"  # HTML User Agent
cfIP="1.1.1.1,1.0.0.1"  # cloudflare pub-dns IP Address
cfDoH="https://cloudflare-dns.com/dns-query"  # cloudflare pub dns-over-https address

# --- Get File Metadata ----
getFileMetadata() {
  Referer=$(awk -F/ '{print $1"//"$3"/"}' <<< "$dlURL")  # Extract base domain from dlURL
  fileName=$(curl -sIL --doh-url "$cfDoH" -A "$UA" -H "Referer: $Referer" "$dlURL" | grep -i '^location:\|content-disposition' | sed -n 's/.*filename=//p' | tail -1 | tr -d '\r"' | sed 's/.*\///')  # Get fileName from dlURL using curl
  fileSize=$(curl -sIL $dlURL 2>/dev/null | grep -i Content-Length | tail -n 1 | awk '{ printf "Content Size: %.2f MB\n", $2 / 1024 / 1024 }' 2>/dev/null)  # dl fileSize
  if [ -z "$fileName" ]; then
    fileName=$(awk -F'/' '{print $6}' <<< "$dlURL" | sed 's/%20/ /g; s/?.*//')  # seedr.cc dlURL pattern
  fi
  # If File Has an Extension Extract it
  if [[ "$dlURL" == *"archive"* ]]; then
    while true; do
      > aria2dl_log.txt  # Clear previous log
      aria2c -x 16 -s 16 --continue=true --console-log-level=error --download-result=hide --summary-interval=0 -d "$HOME" -o "$fileName" -U "User-Agent: $UA" -U "Referer: $referUrl" --async-dns=true --async-dns-server="$cfIP" "$dlUrl" >> aria2dl_log.txt 2>&1 &
      aria2ProcessId=$!
      sleep 3  # Wait a moment for the log file to start being written
      if grep -q "[0-9]*%" aria2dl_log.txt; then
        kill $aria2ProcessId 2>/dev/null  # Stop aria2c process
        wait $aria2ProcessId 2>/dev/null  # Wait for it to terminate
        rm -f "$HOME/$fileName" "$HOME/${fileName}.aria2"
        redirectURL=$(grep -o 'URI=https://[^ ]*\.seedr\.cc/[^ ]*%[^ ]*' aria2dl_log.txt | head -1 | sed 's/URI=//')
        dlURL="$redirectURL"
        [ -z "$fileSize" ] && fileSize=$(awk '/\[#.*GiB\([0-9]*%\)/ {match($0, /[0-9.]+GiB/); print substr($0, RSTART, RLENGTH); exit}' aria2dl_log.txt)  # Extract fileSize from aria2c progress-bar
        rm -f aria2dl_log.txt
        encodedFileName=$(echo "$redirectURL" | sed 's/.*\///; s/?.*//')  # Extract everything after last / and before ?
        decodedFileName=$(echo "$encodedFileName" | sed 's/%20/ /g')  # replace %20 with space
        break
      fi
    done
    fileName="$decodedFileName"
    file_ext="zip"
  elif [[ "$fileName" == *.* ]]; then
    file_ext="${fileName##*.}"
  fi
  filePath="$Download/$fileName"  # save location of downloaded file
}

# for aria2 due to this cl tool doesn't support --console-log-level=hide flag
aria2ConsoleLogHide() {
  printf '\033[2J\033[3J\033[H'  # clear aria2 multi error log from console
  print_aria2dl  # call the print_aria2dl function
  echo "Enter download URL: $dlURL" && echo
  echo -e "Do you want to download ${Red}$fileName${Reset} - $fileSize ? ${whiteBG}➤ <Yes> $Reset   <No>"
}

# --- Download file using aria2 ---
dl() {
  while true; do
    echo -e "$running Downloading ${Red}$fileName${Reset} from ${Blue}$dlURL${Reset} using aria2.."
    aria2c -x 16 -s 16 --continue=true --console-log-level=error --download-result=hide --summary-interval=0 -d "$Download" -o "$fileName" -U "User-Agent: $UA" -U "Referer: $referURL" --async-dns=true --async-dns-server="$cfIP" "$dlURL"
    if [ $? -eq 0 ]; then
      echo  # Space after aria2 progress-bar
      echo -e "$good Download complete with aria2c. Download file save to ${Cyan}$filePath${Reset}"
      break
    else
      aria2ConsoleLogHide  # Call the aria2 console log hide function
      echo -e "$bad Download failed! Retrying in 5 seconds.." && sleep 5  # Wait 5 sec
    fi
  done
}

# --- Ask the user if they want to download ---
prompt() {
  getFileMetadata  # Call the get file metadata function
  while true; do
    confirmPrompt "Do you want to download ${Red}$fileName${Reset} - $fileSize ?" ynButtons && opt=Yes || opt=No
    case $opt in
      Yes)
        dl  # Call the download function
        if [ "$file_ext" == "apk" ] && [ $isAndroid == true ]; then
          confirmPrompt "Do you want to install ${Red}$fileName${Reset} ?" ynButtons && options=Yes || options=No
          case $options in
            Yes) apkInstall ;;  # Call the apk Install function
            No) echo -e "$notice ${Red}$fileName${Reset} installation skiped by user!" ;;
          esac
        elif [ "$file_ext" == "zip" ]; then
          confirmPrompt "Do you want to extract archive ${Red}$fileName${Reset} ?" ynButtons && options=Yes || options=No
          case $options in
            Yes)
              #baseName="${fileName%.*}"
              #mkdir -p "$Download/$baseName"
              termux-wake-lock
              pv "$filePath" | bsdtar -xf - -C "$Download/"
              termux-wake-unlock
              rm -f "$filePath"  # remove zip file
              #rm -f "$Download/$baseName"
              ;;
            No) echo -e "$notice ${Red}$fileName${Reset} archive extracting skiped by user!" ;;
          esac
        elif [ "$file_ext" == "iso" ]; then
          if [ $isAndroid == true ]; then
            am start -n "eu.depau.etchdroid/.ui.MainActivity" &>/dev/null || termux-open-url "https://github.com/etchdroid/etchdroid/releases"
          elif [ $isMacOS == true ]; then
            # https://github.com/pbatard/rufus/releases
            open -a balenaEtcher || open "https://github.com/balena-io/etcher/releases"
          else
            gtk-launch balena-etcher || xdg-open "https://github.com/balena-io/etcher/releases"
          fi
        else
          if [ $isAndroid == true ]; then
            confirmPrompt "Do you want to share ${Red}$fileName${Reset}?" ynButtons && termux-open --send "$filePath" || termux-open "$filePath"
          elif [ $isMacOS == true ]; then
            open "$filePath"
          else
            xdg-open "$filePath"
          fi
        fi
        sleep 3 && break
        ;;
      No)
        echo -e "$notice Download cancel by user!"
        break  # break the while loop
        ;;
    esac
  done
}

# --- Prompt user to enter download URL ---
while true; do
  printf '\033[2J\033[3J\033[H'
  print_aria2dl  # Call the print aria2dl shape function
  read -p "Enter download URL: " dlURL
  Referer=$(awk -F/ '{print $1"//"$3"/"}' <<< "$dlURL")  # extract base domain from dlURL
  httpStatus=$(curl -sL --head --silent --fail --doh-url "$cfDoH" -A "$UA" -H "Referer: $Referer" "$dlURL" 2>/dev/null)  # Check HTTP status code
  while true; do
    if [[ "$dlURL" =~ ^[Qq] ]]; then
      if [ $isOverwriteTermuxProp -eq 1 ]; then sed -i '/allow-external-apps/s/^/# /' "$HOME/.termux/termux.properties";fi && printf '\033[2J\033[3J\033[H' && exit 0
    elif [ $httpStatus -ne 404 ] || [ $httpStatus -eq 302 ] || [ $httpStatus -eq 200 ] || [ $httpStatus -eq 403 ]; then
      echo && break
    else
      echo -e "$notice Given URL invalid! Please enter a valid URL." && sleep 3 && printf '\033[2J\033[3J\033[H'
    fi
  done
  prompt  # Call the prompt function
  continue
done
#####################################################################################################################################################################