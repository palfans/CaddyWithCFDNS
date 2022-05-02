#!/bin/bash

git checkout master
git pull
docker build -t palfans/caddy:latest .
docker tag palfans/caddy:latest palfans/caddy:$1
docker push palfans/caddy:$1
docker push palfans/caddy:latest