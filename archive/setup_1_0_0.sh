# version 1.0.0

#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

PPAS=("apt-fast/stable")
PACKAGES=("build-essential" "curl" "file" "git" "zlib1g-dev" "wget" "zenity" "libffi-dev" "libbz2-dev" "liblzma-dev" "tk-dev" "autoconf" "bison" "gettext" "libgd-dev" "libcurl4-openssl-dev" "libedit-dev" "libicu-dev" "libjpeg-dev" "libmysqlclient-dev" "libonig-dev" "libpng-dev" "libpq-dev" "libreadline-dev" "libsqlite3-dev" "libssl-dev" "libxml2-dev" "libzip-dev" "openssl" "pkg-config" "re2c")

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

CODENAME=$(lsb_release -c -s)
USERNAME=$(logname)
PROFILE="/home/$USERNAME/.profile"

_user() {
    sudo -u $USERNAME env "PATH=$PATH" "$@"
}

for PPA in "${PPAS[@]}"; do
    echo -e "${GREEN}=== Processing repository: $PPA ===${NC}"
    if ! grep -q "^deb .*$PPA" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        echo "Adding $PPA repository..."
        sudo add-apt-repository ppa:$PPA -y
    else
        echo "Skipping $PPA installation - already installed"
    fi
    echo -e "${BLUE}=== Finished processing repository: $PPA ===${NC}"
done

echo -e "${GREEN}Updating package list...${NC}"
sudo apt-get update
echo -e "${BLUE}Finished Updating package list${NC}"

echo -e "${GREEN}=== Checking apt-fast installation ===${NC}"
if ! command -v apt-fast &> /dev/null; then
    sudo debconf-set-selections <<< 'apt-fast apt-fast/maxdownloads string 16'
    sudo debconf-set-selections <<< 'apt-fast apt-fast/dlflag boolean true'
    sudo debconf-set-selections <<< 'apt-fast apt-fast/aptmanager string apt'
    echo "Installing apt-fast..."
    sudo apt-get install apt-fast -y
else
    echo "Skipping apt-fast installation - already installed"
fi
echo -e "${BLUE}=== Finished checking apt-fast installation ===${NC}"

echo -e "${GREEN}Updating and upgrading packages...${NC}"
sudo apt-fast update
sudo apt-fast upgrade -y
echo -e "${BLUE}Finished update and upgrade packages${NC}"

source $PROFILE

for PACKAGE in "${PACKAGES[@]}"; do
    echo -e "${GREEN}=== Processing package: $PACKAGE ===${NC}"
    if ! dpkg -l | grep -q $PACKAGE; then
        echo "Installing $PACKAGE..."
        sudo apt-fast install $PACKAGE -y
    else
        echo "Skipping $PACKAGE installation - already installed"
    fi
    echo -e "${BLUE}=== Finished processing package: $PACKAGE ===${NC}"
done

source $PROFILE

echo -e "${GREEN}=== Checking wine installation ===${NC}"
if ! command -v wine &> /dev/null; then
    echo "Installing wine..."
    sudo dpkg --add-architecture i386
    sudo mkdir -pm755 /etc/apt/keyrings
    sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
    sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/$CODENAME/winehq-$CODENAME.sources
    sudo apt-fast update
    sudo apt-fast install winehq-stable winetricks -y
    source $PROFILE
else
    echo "Skipping wine installation - already installed"
fi
echo -e "${BLUE}=== Finished checking wine installation ===${NC}"

echo -e "${GREEN}=== Checking Homebrew installation ===${NC}"
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    sudo mkdir -p /home/linuxbrew/.linuxbrew
    sudo chown -R $USERNAME /home/linuxbrew/.linuxbrew
    sudo -u $USERNAME NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    test -d /home/$USERNAME/.linuxbrew && eval "$(/home/$USERNAME/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r /home/$USERNAME/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> /home/$USERNAME/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> /home/$USERNAME/.profile
    source $PROFILE
else
    echo "Skipping Homebrew installation - already installed"
fi
echo -e "${BLUE}=== Finished checking HomeBrew installation ===${NC}"

_brew() {
    _user brew "$@"
}

echo -e "${GREEN}=== Checking gcc installation ===${NC}"
if ! _brew list gcc &> /dev/null; then
    echo "Installing gcc..."
    _brew install gcc
    source $PROFILE
else
    echo "Skipping gcc installation - already installed"
fi
echo -e "${BLUE}=== Finished checking gcc installation ===${NC}"

echo -e "${GREEN}=== Checking asdf installation ===${NC}"
if ! _brew list asdf &> /dev/null; then
    echo "Installing asdf..."
    _brew install asdf
    echo ". /home/linuxbrew/.linuxbrew/opt/asdf/libexec/asdf.sh" >> /home/$USERNAME/.profile
    source $PROFILE
else
    echo "Skipping asdf installation - already installed"
fi
echo -e "${BLUE}=== Finished checking asdf installation ===${NC}"

echo -e "${GREEN}=== Checking apache2 installation ===${NC}"
if ! _brew list apache2 &> /dev/null; then
    echo "Installing apache2..."
    _brew install apache2
    source $PROFILE
    sudo useradd -m _www
    sudo groupadd _www
    sudo adduser _www _www
else
    echo "Skipping apache2 installation - already installed"
fi
echo -e "${BLUE}=== Finished checking apache2 installation ===${NC}"

echo -e "${GREEN}=== Checking mariadb installation ===${NC}"
if ! _brew list mariadb &> /dev/null; then
    echo "Installing mariadb..."
    _brew install mariadb
    source $PROFILE
else
    echo "Skipping mariadb installation - already installed"
fi
echo -e "${BLUE}=== Finished checking mariadb installation ===${NC}"

echo -e "${GREEN}=== Checking kubectl installation ===${NC}"
if ! _brew list kubectl &> /dev/null; then
    echo "Installing kubectl..."
    _brew install kubectl helm
    source $PROFILE
else
    echo "Skipping kubectl installation - already installed"
fi
echo -e "${BLUE}=== Finished checking kubectl installation ===${NC}"

echo -e "${GREEN}=== Checking docker installation ===${NC}"
if ! _brew list docker &> /dev/null; then
    echo "Installing docker..."
    _brew install docker docker-compose
    source $PROFILE
else
    echo "Skipping docker installation - already installed"
fi
echo -e "${BLUE}=== Finished checking docker installation ===${NC}"

echo -e "${GREEN}=== Checking poetry installation ===${NC}"
if ! _brew list poetry &> /dev/null; then
    echo "Installing poetry..."
    _brew install poetry
    source $PROFILE
else
    echo "Skipping poetry installation - already installed"
fi
echo -e "${BLUE}=== Finished checking poetry installation ===${NC}"

_asdf(){
    _user asdf "$@"
}

echo -e "${GREEN}=== Checking php installation ===${NC}"
if ! _asdf plugin list | grep -q "php"; then
    echo "Installing php..."
    _asdf plugin add php
    _asdf install php latest
    _asdf global php latest
    source $PROFILE
else
    echo "Skipping php installation - already installed"
fi
echo -e "${BLUE}=== Finished checking php installation ===${NC}"

echo -e "${GREEN}=== Checking python installation ===${NC}"
if ! _asdf plugin list | grep -q "python"; then
    echo "Installing python..."
    _asdf plugin add python
    _asdf install python latest
    _asdf global python latest
    source $PROFILE
else
    echo "Skipping python installation - already installed"
fi
echo -e "${BLUE}=== Finished checking python installation ===${NC}"

echo -e "${GREEN}=== Checking java installation ===${NC}"
if ! _asdf plugin list | grep -q "java"; then
    echo "Installing java..."
    _asdf plugin add java
    _asdf install java oracle-17
    _asdf global java oracle-17
    source $PROFILE
else
    echo "Skipping java installation - already installed"
fi
echo -e "${BLUE}=== Finished checking java installation ===${NC}"
