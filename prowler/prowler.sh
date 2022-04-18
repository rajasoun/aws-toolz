#!/usr/bin/env sh

# Load environment variables from aws-vault tool
# export $(aws-vault exec secops-experiments --no-session -- env | grep AWS | xargs)

rm -fr "$(pwd)/report/*.csv"
rm -fr "$(pwd)/report/*.html"

docker run -ti --rm \
       --name prowler \
       --volume "$(pwd)/report":/prowler/output \
       --env AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
       --env AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
       toniblyx/prowler:latest -M csv,html $*
