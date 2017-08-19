#/bin/bash
HOME_PATH=/home/pi/appli
DOCKER_PATH=$HOME_PATH/_docker/domoticz
DOMOTICZ_PATH=$HOME_PATH/domoticz/

####################################
#	IMAGES DOCKER
####################################
function createImage {
echo "Construction de l'image vzwingma/domoticz:arm"
docker build -t vzwingma/domoticz:arm $DOCKER_PATH/.
}

####################################
#	CONTENEURS DOCKER
####################################
function createConteneur {
	echo "Création du conteneur "
	docker rm --force domoticz
	docker run --name=domoticz --privileged -d \
		-p 8080:8080 \
		-v $DOMOTICZ_PATH/database:/config \
		-v $DOMOTICZ_PATH/www/images/floorplans:/src/domoticz/www/images/floorplans \
		-v $DOMOTICZ_PATH/scripts/python:/src/domoticz/scripts/python \
		-v $DOMOTICZ_PATH/scripts/lua:/src/domoticz/scripts/lua \
		# -t joshuacox/mkdomoticz:arm
		-t vzwingma/domoticz:arm

}

# createImage
createConteneur