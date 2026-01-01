#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

banner() {
    echo -e "${GREEN}"
    echo "  _    _ _ _ _ _      _   _      _   __  __ _             _ _ "
    echo " | |  | (_) (_) |    | | | |    | | |  \\/  (_)           | | |"
    echo " | |  | |_| |_| |_ __| |_| | ___| |_| \\  / |_ _ __   ___ | | |"
    echo " | |/\\| | | | | __/ _\\ __| |/ _ \\ __| |\\/| | | '_ \\ / _ \\| | |"
    echo " \\  /\\  / | | | | || (_| |_| |  __/ |_| |  | | | | | | (_) | | |"
    echo "  \\/  \\/|_|_|_|\\__\\___|\\__|_|\\___|\\__|_|  |_|_|_| |_|\\___/|_|_|"
    echo -e "${NC}"
    echo "              Auto-Installer for WiFi Toolkit"
    echo "        ALLReserved(c)2026 Adikoto IndoCreative.Ltd"
    echo "============================================================"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Please run as root (sudo).${NC}"
        exit 1
    fi
}

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        DISTRO="unknown"
    fi
}

install_debian() {
    echo -e "${YELLOW}[*] Updating package list...${NC}"
    apt update -y

    echo -e "${YELLOW}[*] Installing core tools...${NC}"
    apt install -y aircrack-ng reaver wash git

    echo -e "${YELLOW}[*] Installing Hashcat...${NC}"
    apt install -y hashcat

    echo -e "${YELLOW}[*] Installing wordlists (optional)...${NC}"
    apt install -y seclists

    echo -e "${GREEN}[+] All dependencies installed!${NC}"
}

install_arch() {
    echo -e "${YELLOW}[*] Installing via pacman...${NC}"
    pacman -Sy --noconfirm aircrack-ng reaver hashcat
    echo -e "${GREEN}[+] Done.${NC}"
}

install_fedora() {
    echo -e "${YELLOW}[*] Installing via dnf...${NC}"
    dnf install -y aircrack-ng reaver hashcat
    echo -e "${GREEN}[+] Done.${NC}"
}

main() {
    check_root
    banner
    detect_distro

    case "$DISTRO" in
        debian|ubuntu|kali|parrot|linuxmint)
            install_debian
            ;;
        arch|manjaro)
            install_arch
            ;;
        fedora)
            install_fedora
            ;;
        *)
            echo -e "${RED}[!] Unsupported distro: $DISTRO${NC}"
            echo "Please install manually:"
            echo "  sudo apt install aircrack-ng reaver wash hashcat"
            exit 1
            ;;
    esac

    echo ""
    echo -e "${GREEN}✅ Installation complete!${NC}"
    echo "Run the toolkit with:"
    echo "  sudo ./wifitoolkit.sh"
}

main "$@"
