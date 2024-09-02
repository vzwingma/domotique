#/bin/bash
HOME_PATH=/home/pi/appli
DOCKER_PATH=$HOME_PATH/_docker

echo ""
echo "## Mise à jour des images docker ##"
docker-compose -f $DOCKER_PATH/domotique-compose.yml pull
echo ""
echo "## (Re)création des conteneurs ## "

docker-compose -f $DOCKER_PATH/domotique-compose.yml down
docker-compose -f $DOCKER_PATH/domotique-compose.yml up -d
