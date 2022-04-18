#!/usr/bin/env bash

printf "User Name : "
read -r "CN"
printf "Email : "
read -r "EMAIL"

# Set GNUPGHOME to create gpg keys in temp foleder 
function configure_to_create_in_temp_folder(){
    GNUPGHOME="$(mktemp -d)"
    export GNUPGHOME
    echo "GNUPGHOME=$GNUPGHOME"
}

function create_keys(){
    gpg2 --full-generate-key --batch  <<EOF
%echo Generating a GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: encrypt
Name-Real: $CN
Name-Email: $EMAIL
Expire-Date: 1y
%no-protection
%commit
%echo Done
EOF
}

function store_keys(){
    gpg2 --export -a "$EMAIL" > .devcontainer/.gpg2/public.key
    gpg2 --export-secret-keys --armor > .devcontainer/.gpg2/private.key
}

function list_gpg2_keys(){
    gpg2 --list-keys
}

#configure_to_create_in_temp_folder
rm -fr $HOME/.gnupg
create_keys
list_gpg2_keys
store_keys

