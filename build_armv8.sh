#!/bin/bash

git checkout armv8
git pull
docker build -t palfans/caddy:armv8-$1 .
docker push palfans/caddy:armv8-$1