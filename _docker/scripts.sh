#/bin/bash
HOME_PATH=/home/pi/appli
DOCKER_PATH=$HOME_PATH/_docker
DOMOTICZ_PATH=$HOME_PATH/domoticz/

####################################
#	IMAGES DOCKER
####################################
function createImages {
	echo "Construction de l'image vzwingma/domoticz:arm"
	docker build -t vzwingma/domoticz:arm $DOCKER_PATH/domoticz/.
	echo "Chargement de l'image WiringPi"
	docker pull hypriot/wiringpi
}

####################################
#	CONTENEURS DOCKER
####################################
function createConteneurDomoticz {
	echo "Création du conteneur Domoticz"
	docker rm --force domoticz
	docker run --name=domoticz -d \
		--privileged \
		--restart=always \
		-p 8080:8080 \
		-p 443:443 \
		-e TZ=Europe/Paris \
		-v /etc/timezone:/etc/timezone:ro \
		-v /etc/localtime:/etc/localtime:ro \
		-v $DOMOTICZ_PATH/database:/config \
		-v $DOMOTICZ_PATH/www/images/floorplans:/src/domoticz/www/images/floorplans \
		-v $DOMOTICZ_PATH/scripts/python:/src/domoticz/scripts/python \
		-v $DOMOTICZ_PATH/scripts/lua:/src/domoticz/scripts/lua \
		-t vzwingma/domoticz:arm
}

# createImages
createConteneurDomoticz
