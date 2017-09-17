#/bin/bash
HOME_PATH=/home/pi/appli
DOCKER_PATH=$HOME_PATH/_docker
DOMOTICZ_PATH=$HOME_PATH/domoticz/

echo "Création des conteneurs Domoticz"
docker-compose -f $DOCKER_PATH/domotique-compose.yml up --force-recreate -d


function createConteneurDHT11TEST {
	echo "Création du conteneur DHT11"
	docker rm --force dht11-test
	docker run --name=dht11-test -d \
		--privileged \
		--restart always \
		-e "APP_NAME=DHT11-TEST" \
		-v ~/appli/receptionDHT11:/appli/receptionDHT11 \
		-p 9500:9100 \
		-p 9501:9000 \
		--device /dev/ttyAMA0:/dev/ttyAMA0 \
		--device /dev/mem:/dev/mem \
		-it vzwingmann/wiringpi:arm-dht11
}