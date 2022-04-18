#!/usr/bin/env bash

EMAIL=$(gpg2 --list-keys | grep uid | awk '{print $5}' | tr -d '<>')
STORE_GPG_ID=$(cat $HOME/.password-store/.gpg-id)
if [ $EMAIL != $STORE_GPG_ID ];then
    pass init $EMAIL
fi
