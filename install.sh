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
    software-properties-common > log 2>&1
displayEnd "Install common tools"

displaybegin "Add user ${XRDP_USER}"

egrep "^${XRDP_USER}" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
  displayEnd "${XRDP_USER} already exists!"
else
  pass=$(perl -e 'print crypt($ARGV[0], "password")' ${XRDP_PASS})
  useradd -m -p "$pass" "${XRDP_USER}" > log 2>&1
  sed "s/^XRDP_PASS=.*$/XRDP_PASS=$pass/" -i .env > log 2>&1
  [ $? -eq 0 ] && displayEnd "${XRDP_USER} has been added to system!" || displayEnd "Failed to add a user!"
fi

displaybegin "Add user ${XRDP_USER} to sudoer"
usermod -aG sudo ${XRDP_USER} > log 2>&1
displayEnd "Add user ${XRDP_USER} to sudoer"

if [ "${XRDP_INSTALL}" == yes ]; then
    displaybegin "Install LXDE and xrdp"
        apt install -y lxde
        apt install xrdp -y > log 2>&1
        adduser xrdp ssl-cert > log 2>&1
        systemctl restart xrdp > log 2>&1
        systemctl enable xrdp > log 2>&1
        cp ./02-allow-colord.conf /etc/polkit-1/localauthority.conf.d/02-allow-colord.conf > log 2>&1
    displayEnd "Install LXDE and xrdp"
fi


displaybegin "Change user"
su - ${XRDP_USER}
displayEnd "Change user"

displaybegin "Create ssh key"
ssh-keygen -t ed25519 -C "${XRDP_USER_MAIL}" -f /home/${XRDP_USER}/.ssh/id_ed25519 -q -P ""  > log 2>&1
displayEnd "Create ssh key"

echo "################     SSH KEY     #############################"
cat ~/.ssh/id_ed25519.pub
echo "################     SSH KEY     #############################"

echo "${XRDP_PASS}" | sudo -S ls -la > log 2>&1

displaybegin "google chrome install"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb > log 2>&1
sudo dpkg -i google-chrome-stable_current_amd64.deb > log 2>&1
displayEnd "google chrome install"


displaybegin "Ajout du repository docker"
curl -fsSL https://download.docker.com/linux/${OS}/gpg | sudo apt-key add - > log 2>&1

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/${OS} \
   $(lsb_release -cs) \
   stable" > log 2>&1
displayEnd "Ajout du repository docker"

if [ $(getEnvValue 'FRESH_INSTALL') != "yes" ]
then
    displaybegin "Remove old package"
    sudo apt-get -y remove docker docker-engine docker.io containerd runc > log 2>&1
    sudo apt-get -y remove docker-ce docker-ce-cli containerd.io > log 2>&1
    displayEnd "Remove old package"
fi

displaybegin "Install docker"
sudo apt-get -y update > log 2>&1
sudo apt-get -y install docker-ce docker-ce-cli containerd.io > log 2>&1
displayEnd "Install docker"

COMPOSE_INSTALL=$(getEnvValue 'COMPOSE_INSTALL')
COMPOSE_VERSION=$(getEnvValue 'COMPOSE_VERSION')


if [ "${COMPOSE_INSTALL}" == yes ]; then
    displaybegin "Install docker compose"
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose  > log 2>&1
    sudo chmod +x /usr/local/bin/docker-compose  > log 2>&1
    displayEnd "Install docker compose"
fi

displaybegin "post config"
sed "s/^FRESH_INSTALL=.*$/FRESH_INSTALL=no/" -i .env
sed "s/^COMPOSE_INSTALL=.*$//" -i .env
displayEnd "post config"
