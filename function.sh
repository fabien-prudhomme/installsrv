#!/usr/bin/env bash

function displaybegin() {
  echo  -e "[\033[34;1m..\033[0m] $1\r\c"
}

function displayEnd() {
  echo  -e "[\033[32;1mOK\033[0m] $1"
}


function configureEnv() {
    local key=$1
    local value=$2

    if [ ! -f .env ] || [ "$(cat .env | grep -Ec "^${key}=(.*)$")" -eq 0 ]; then
        echo "${key}=${value}" >> .env
    else
        sed "s/^${key}=.*$/${key}=${value}/" -i .env
    fi
}

function getEnvValue() {
    local key=$1
    local defaultValue=$(cat ./.env.dist | grep -E "^${key}=(.*)$" | awk -F "${key} *= *" '{print $2}')

    case ${key} in
        DOCKER_UID)
            value=$(id -u)
        ;;
        *)
            if [ ! -f .env ] || [ "$(cat .env | grep -Ec "^${key}=(.*)$")" -eq 0 ]; then
                read -p "define the value of ${key} (default: ${defaultValue}): " value
            else
                value=$(cat .env | grep -E "^${key}=(.*)$" | awk -F "${key} *= *" '{print $2}')
            fi
        ;;
    esac

    if [ "${value}" == "" ]; then
        value=${defaultValue}
    fi

    echo ${value}
}