#/bin/bash
HOME_PATH=/home/pi/appli
DOCKER_PATH=$HOME_PATH/_docker
DOMOTICZ_PATH=$HOME_PATH/domoticz/

####################################
#	IMAGES DOCKER
####################################
function createImages {
	echo "Pull de l'image vzwingma/domoticz:arm"
	docker pull vzwingmann/domoticz:arm
	echo "Pull de l'image GPIO DHT11"
	docker pull vzwingmann/wiringpi:arm-dht11
	echo "Pull de l'image GPIO Radio"
	docker pull vzwingmann/wiringpi:arm-radio
}

####################################
#	CONTENEURS DOCKER
####################################
function createConteneurDomoticz {
	echo "Création du conteneur Domoticz"
	docker rm --force domoticz
	docker run --name=domoticz -d \
		--restart always \
		--privileged \
		--restart=always \
		--link dht11 \
		--link radio \
		-p 8080:8080 \
		-p 443:443 \
		-e TZ=Europe/Paris \
		-e LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/vc/lib/ \
		-v /opt/vc/:/opt/vc/ \
		-v /etc/timezone:/etc/timezone:ro \
		-v /etc/localtime:/etc/localtime:ro \
		-v $DOMOTICZ_PATH/database:/config \
		-v $DOMOTICZ_PATH/www/images/floorplans:/src/domoticz/www/images/floorplans \
		-v $DOMOTICZ_PATH/scripts/lua:/src/domoticz/scripts/lua \
		-t vzwingmann/domoticz:arm
}

function createConteneurDHT11 {
	echo "Création du conteneur DHT11"
	docker rm --force dht11
	docker run --name=dht11 -d \
		--privileged \
		--restart always \
		-e "APP_NAME=DHT11" \
		-p 9100:9100 \
		--device /dev/ttyAMA0:/dev/ttyAMA0 \
		--device /dev/mem:/dev/mem \
		-it vzwingmann/wiringpi:arm-dht11
}

function createConteneurRadio {
	echo "Création du conteneur Radio"
	docker rm --force radio
	docker run --name=radio -d \
		--privileged \
		--restart always \
		-e "APP_NAME=Radio" \
		-p 9101:9100 \
		--device /dev/ttyAMA0:/dev/ttyAMA0 \
		--device /dev/mem:/dev/mem \
		-it vzwingmann/wiringpi:arm-radio
}

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

function main-test {
	createConteneurDHT11TEST
}


function main {
	createImages
	createConteneurDHT11
	createConteneurRadio
	createConteneurDomoticz
}

main
# main-test