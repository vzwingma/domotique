# Image docker DomoticZ

## Téléchargement depuis Docker Hub
      docker pull vzwingmann/domoticz:arm

## Construction de l'image ( *sur une architecture ARM* )
      docker build -t vzwingmann/domoticz:arm .

## Exécution du conteneur 
      docker run --name=domoticz -d \
  		    --privileged \
  		    --restart=always \
  		    --link dht11 \
  		    -p 8080:8080 \
  		    -p 443:443 \
  		    -e TZ=Europe/Paris \
  		    -v /etc/timezone:/etc/timezone:ro \
  		    -v /etc/localtime:/etc/localtime:ro \
  		    -v $DOMOTICZ_PATH/database:/opt/domoticz/userdata \
  		    -v $DOMOTICZ_PATH/www/images/floorplans:/opt/domoticz/www/images/floorplans \
  		    -v $DOMOTICZ_PATH/scripts/lua:/opt/domoticz/scripts/lua \
  		    -t vzwingmann/domoticz:arm
    
où 
- `$DOMOTICZ_PATH/database` : Répertoire vers la BDD Domoticz
- `$DOMOTICZ_PATH/www/images/floorplans` : Répertoire vers les fonds de plans
- `$DOMOTICZ_PATH/scripts/lua` : Répertoire vers les scripts LUA

- `link dht11` : Lien vers le conteneur DHT11 
