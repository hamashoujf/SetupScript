#!/bin/sh

# version 1.1.0

# FUNCTIONS
check_ppa() {
    if grep -h "^deb.*$1" /etc/apt/sources.list.d/*; then
        return 0
    else
        return 1
    fi
}

# CHECK IF ROOT
if [[ $EUID -ne 0 ]]; then
    whiptail --title "Error" --msgbox "This script must be run as root" 0 0
    exit 1
fi

# INSTALL APT-FAST
if check_ppa "apt-fast/stable"; then
    :
else
    sudo add-apt-repository ppa:apt-fast/stable -y
fi

if ! command -v apt-fast &> /dev/null; then
        sudo debconf-set-selections <<< "apt-fast apt-fast/maxdownloads string $(nproc --all)"
        sudo debconf-set-selections <<< 'apt-fast apt-fast/dlflag boolean true'
        sudo debconf-set-selections <<< 'apt-fast apt-fast/aptmanager string apt'
        sudo apt-get install apt-fast -y
fi

# UPDATE AND UPGRADE PACKAGES
sudo apt-fast update
sudo apt-fast upgrade -y

# INSTALL PACKAGES
sudo apt-fast install tmux zsh -y
