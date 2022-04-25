#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

AWS_PROFILE=$1

if [ -z $AWS_PROFILE ];then
    #AWS_PROFILE Empty
    echo -e "\n${BOLD}${RED}AWS Profile parameter missing  ${NC}"
    echo -e "Usage: $0 <aws_profile>\n"
else
    #AWS_PROFILE Not Empty
    mkdir -p reports/$AWS_PROFILE
    		#AWS_PROFILE Not Empty
    AWS_CLOUDSPLAINING_CMD="cloudsplaining download --output reports/$AWS_PROFILE"
    AWS_VAULT_WRAPPER="$(git rev-parse --show-toplevel)/.devcontainer/.aws/aws_vault_env.sh"
    export AWS_PROFILE=$AWS_PROFILE && $AWS_VAULT_WRAPPER $AWS_CLOUDSPLAINING_CMD
    rm -fr "reports/$AWS_PROFILE/$AWS_PROFILE-exclusions.yml"
    cloudsplaining create-exclusions-file --output-file reports/$AWS_PROFILE/$AWS_PROFILE-exclusions.yml > /dev/null
    echo -e "Configure Exclusion Filter -> ${UNDERLINE}reports/$AWS_PROFILE/$AWS_PROFILE-exclusions.yml${NC}"
    AWS_CLOUDSPLAINING_CMD="cloudsplaining scan \
        --exclusions-file reports/$AWS_PROFILE/$AWS_PROFILE-exclusions.yml \
        --input-file reports/$AWS_PROFILE/default.json \
        --output reports/$AWS_PROFILE"
    export AWS_PROFILE=$AWS_PROFILE && $AWS_VAULT_WRAPPER $AWS_CLOUDSPLAINING_CMD
    echo -e "\n${GREEN}IAM Audit Done${NC}"
    echo -e "HTMl Report  : ${UNDERLINE}reports/$AWS_PROFILE/iam-report-default.html${NC}\n"
    echo -e "More Details : https://github.com/salesforce/cloudsplaining#cheatsheet\n"
fi
