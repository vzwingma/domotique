# Image docker DomoticZ

## Téléchargement depuis Docker Hub
      docker pull vzwingmadomatic/domoticz:latest

## Construction de l'image ( *sur une architecture ARM* )
      docker build -t vzwingmadomatic/domoticz:latest .

## Exécution du conteneur 
      docker run --name=domoticz -d \
  		    --privileged \
  		    --restart=always \
  		    -p 8080:8080 \
  		    -p 8443:443 \
  		    -e TZ=Europe/Paris \
  		    -v /etc/timezone:/etc/timezone:ro \
  		    -v /etc/localtime:/etc/localtime:ro \
  		    -v $DOMOTICZ_PATH/database:/opt/domoticz/userdata \
  		    -v $DOMOTICZ_PATH/scripts/dzVents:/opt/domoticz/userdata/scripts/dzVents/generated_scripts \
  		    -t vzwingmadomatic/domoticz:latest
    
où 
- `$DOMOTICZ_PATH/database` : Répertoire vers la BDD Domoticz
- `$DOMOTICZ_PATH/scripts/dzVents` : Répertoire vers les scripts LUA