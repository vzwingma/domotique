#/bin/bash
HOME_PATH=/home/pi/appli
DOCKER_PATH=$HOME_PATH/_docker

echo "Mise à jour des images Domoticz"
docker-compose -f $DOCKER_PATH/domotique-compose.yml pull
echo "Création des conteneurs Domoticz"
docker-compose -f $DOCKER_PATH/domotique-compose.yml up --force-recreate -d
