#!/bin/sh
set -e
docker container prune -f
docker image prune -f
docker network prune -f
docker volume prune -f
