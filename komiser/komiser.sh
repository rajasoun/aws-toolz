#!/usr/bin/env sh

# Load environment variables from aws-vault tool
#export $(aws-vault exec secops-experiments --no-session -- env | grep AWS | xargs)

AWS_DEFAULT_REGION=${1:-"us-east-1"}

docker run -d --rm \
       -p 3000:3000 \
       --name komiser \
       --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
       --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
       --env AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
       mlabouardy/komiser:latest $*

echo -e "komiser started - http://localhost:3000"
