#!/usr/bin/env bash

docker-compose up -d  
komiser start --port 3000 --redis localhost:6379  --duration 0  --multiple
echo -e "komiser started - http://localhost:3000"