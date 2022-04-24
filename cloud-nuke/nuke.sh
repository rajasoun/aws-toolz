#!/usr/bin/env bash

echo -e "Dry Run\n"
cloud-nuke aws --region us-east-1 --config nuke.yml 

echo -e "Run : cloud-nuke aws --region us-east-1 --config nuke.yml"