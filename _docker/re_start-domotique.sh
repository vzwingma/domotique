#!/bin/bash
HOME_PATH=/home/pi/appli
DOCKER_PATH=$HOME_PATH/_docker
# Ce script est utilisé pour mettre à jour et (re)démarrer des conteneurs Docker pour une application domotique, hébergée sur un Raspberry Pi.
echo ""
echo "## Mise à jour des images docker ##"
docker-compose -f $DOCKER_PATH/domotique-compose.yml pull
echo ""
echo "## (Re)création des conteneurs ## "
docker-compose -f $DOCKER_PATH/domotique-compose.yml up --force-recreate -d
