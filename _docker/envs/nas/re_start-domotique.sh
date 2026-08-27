#/bin/bash
HOME_PATH=/volume1/home/vinz/
DOCKER_PATH=$HOME_PATH/docker

echo ""
echo "## Mise à jour des images docker ##"
docker compose -f $DOCKER_PATH/domotique-compose.yml pull
echo ""
echo "## (Re)création des conteneurs ## "

docker compose -f $DOCKER_PATH/domotique-compose.yml down --remove-orphans
docker compose -f $DOCKER_PATH/domotique-compose.yml up -d
