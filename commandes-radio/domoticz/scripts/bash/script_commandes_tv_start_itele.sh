#!/bin/bash

freeboxCode=$1
channel=$2
echo "[TV] Démarrage de la télécommande Freebox [$freeboxCode] sur la chaine $channel"

# Fonction d'appel à l'URL de la freebox
callUrlFreebox() {
	freeboxCode=$1
	key=$2
	appuilong=$3
	tempo=$4
  
	url="http://hd1.freebox.fr/pub/remote_control?code=$freeboxCode&key=$key"
	if [ "$appuilong" = true ] 
	then
		url="$url&bridgeEndpoint=true";
	fi
	
	echo "[TV] 	Appel de l'URL : [$url]"
	curl $url
	
	if [ "$tempo" > 0 ] 
	then
		echo "[TV]	Tempo de $tempo secondes";
		sleep $tempo;
	fi
}

# Démarrage
callUrlFreebox $freeboxCode "power" false 30
# CanalSat	
callUrlFreebox $freeboxCode "down" false 1
callUrlFreebox $freeboxCode "down" false 1
callUrlFreebox $freeboxCode "down" false 1
callUrlFreebox $freeboxCode "ok" false 1
# iTélé	
size=${#channel}
i=0
while [ "$i" -le "$size" ]
do
        touche=${channel:$i:1}
        i=$(($i+1))
	callUrlFreebox $freeboxCode $touche true 0.5
done
