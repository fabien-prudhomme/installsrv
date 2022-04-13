#!/usr/bin/env bash

set -e
cd $1

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
pass=$(perl -e 'print crypt($ARGV[0], "password")' ${XRDP_PASS})
OS=$(getEnvValue 'OS')


displaybegin "Create ssh key"
ssh-keygen -t ed25519 -C "${XRDP_USER_MAIL}" -f /home/${XRDP_USER}/.ssh/id_ed25519 -q -P ""  > log 2>&1
displayEnd "Create ssh key"

echo "${XRDP_PASS}" | sudo -S ls -la > log 2>&1

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
sed "s/^XRDP_PASS=.*$/XRDP_PASS=$pass/" -i .env > log 2>&1
displayEnd "post config"

echo "################     SSH KEY     #############################"
cat /home/${XRDP_USER}/.ssh/id_ed25519.pub
echo "################     SSH KEY     #############################"
