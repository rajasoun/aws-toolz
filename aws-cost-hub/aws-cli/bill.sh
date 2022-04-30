#!/usr/bin/env bash

NC=$'\e[0m' # No Color
RED=$'\e[31m'


function is_installed(){
    cmd=$1
    err_msg=$2
    command -v $cmd >/dev/null 2>&1 || {        \
        echo -e >&2 "\n$cmd is not installed."; \
        echo -e >&2 "$err_msg.  Aborting!!!\n"; \
        exit 1;
    }
}

function calculate_dates(){
    case "$OSTYPE" in
        # MacOS
        darwin*)
            is_installed "gdate" "brew install coreutils"
            START_DATE=$(gdate +"%Y-%m-01" -d "$DATE - 1month")
            END_DATE=$(gdate +"%Y-%m-01")
        ;;
        # Linux or Windows
        linux*|bsd*|*msys*|*cygwin*)
            START_DATE=$(date +"%Y-%m-01" -d "$DATE - 1month")
            END_DATE=$(date +"%Y-%m-01")
        ;;
        *);;
    esac
}

function get_bill(){
    CALLER_IDENTITY_CMD="aws sts get-caller-identity"
    LIST_ACCOUNT_ALIASES_CMD="aws iam list-account-aliases"
    GET_USER_CMD="aws iam get-user"

    BASIC_SUMMARY=$({ $CALLER_IDENTITY_CMD && $LIST_ACCOUNT_ALIASES_CMD && $GET_USER_CMD; } | jq -s ".|add")
    #BASIC_INFO=$(echo $BASIC_SUMMARY | jq '"Account : " + .Account + "\nUser Name : "+ .User.UserName + "\nAccount Alias : " + .AccountAliases[]')

    calculate_dates
    BILLING_SUMMARY=$(aws ce get-cost-and-usage                \
        --time-period "Start=$START_DATE,End=$END_DATE"        \
        --metrics     'UnblendedCost'                          \
        --granularity 'MONTHLY'                                \
        --query       'ResultsByTime[*].Total.[UnblendedCost]' \
        --output      'json')

    #BILLING_INFO=$(echo $BILLING_SUMMARY | jq '.[] | .[] | "Bill : " + .Amount + " " +.Unit')
    if [ $(echo $BASIC_SUMMARY | grep -c "AccountAliases") = 1 ];then
        echo "AccountAliases Available "
        BASIC_INFO=$(echo $BASIC_SUMMARY | jq '.Account + "," + .AccountAliases[] +  ","')
    else
        echo -e "${RED}Not authorized to perform: iam:ListAccountAliases${NC}"
        BASIC_INFO=$(echo $BASIC_SUMMARY | jq '.Account')
        BASIC_INFO="$(echo $BASIC_INFO,$AWS_VAULT,)"
    fi

    BILLING_INFO=$(echo $BILLING_SUMMARY | jq '.[] | .[] | .Amount + " " +.Unit')

    echo -e $BASIC_INFO $BILLING_INFO | tr -d '"'
    echo -e $BASIC_INFO $BILLING_INFO | tr -d '"' >> ${PWD}/aws-cost-hub/aws-cli/bill.csv
}

get_bill
