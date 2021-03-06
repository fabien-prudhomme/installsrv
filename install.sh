#!/usr/bin/env bash

set -e

originalPath=$(pwd)

. $originalPath/function.sh


# configure .env
for line in $(cat ./.env.dist | grep -vE '^#')
do
    key=$(echo ${line} | awk -F "=" '{print $1}')
    configureEnv ${key} $(getEnvValue ${key})
done

XRDP_USER=$(getEnvValue 'XRDP_USER')
XRDP_INSTALL=$(getEnvValue 'XRDP_INSTALL')
XRDP_PASS=$(getEnvValue 'XRDP_PASS')
XRDP_USER_MAIL=$(getEnvValue 'XRDP_USER_MAIL')
OS=$(getEnvValue 'OS')

displaybegin "Update du système"
sudo apt-get update > log 2>&1
displayEnd "Update du système"

displaybegin "Install common tools"
sudo apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    perl \
    wget \
    gnupg-agent \
    fonts-liberation \
    software-properties-common  > log 2>&1
displayEnd "Install common tools"

if [ "${XRDP_INSTALL}" == yes ]; then
    displaybegin "Install LXDE and xrdp"
        apt install -y lubuntu-desktop
        apt install xrdp -y > log 2>&1
        adduser xrdp ssl-cert > log 2>&1
        systemctl restart xrdp > log 2>&1
        systemctl enable xrdp > log 2>&1
        cp ./02-allow-colord.conf /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf > log 2>&1
    displayEnd "Install LXDE and xrdp"
fi

displaybegin "Add user ${XRDP_USER}"
pass=$(perl -e 'print crypt($ARGV[0], "password")' ${XRDP_PASS})
useradd -m -p "$pass" "${XRDP_USER}" > log 2>&1
displayEnd "${XRDP_USER} has been added to system!"


displaybegin "Add user ${XRDP_USER} to sudoer"
usermod -aG sudo ${XRDP_USER} > log 2>&1
displayEnd "Add user ${XRDP_USER} to sudoer"

if [ "${XRDP_INSTALL}" == yes ]; then
displaybegin "google chrome install"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb > log 2>&1
dpkg -i google-chrome-stable_current_amd64.deb > log 2>&1
displayEnd "google chrome install"
fi

displaybegin "Install lang"
sudo apt-get -y install \
    language-pack-gnome-fr \
    thunderbird-locale-fr \
    gnome-user-docs-fr \
    wfrench \
    firefox-locale-fr \
    language-pack-gnome-fr \
    language-pack-fr \
    language-pack-fr-base > log 2>&1
displayEnd "Install lang"

chown -R ${XRDP_USER}:${XRDP_USER} ${originalPath}

runuser -l  ${XRDP_USER} -c "${originalPath}/installUser.sh ${originalPath}"


