#!/bin/bash

freeboxCode=$1
channel=$2

# Date
timestamp() {
  date +"%d/%m/%y %T"
}
echo ""
echo ""
echo ""
echo "$(timestamp) [TV] Démarrage de la FreeboxTV [$freeboxCode] sur la chaine chaine $channel"

# Fonction d'appel à l'URL de la freebox
callUrlFreebox() {
	freeboxCode=$1
	key=$2
	appuilong=$3
	tempo=$4
  
	url="http://hd1.freebox.fr/pub/remote_control?code=$freeboxCode&key=$key"
	if [ "$appuilong" = true ] 
	then
		url="$url&long=true";
	fi
	
	echo "$(timestamp) [TV] Appel de l'URL : [$url]"
#	curl $url
	
	if [ "$tempo" > 0 ] 
	then
		echo "$(timestamp) [TV]    Tempo de $tempo secondes";
#		sleep $tempo;
	fi
}

# Démarrage
callUrlFreebox $freeboxCode "power" false 30
# CanalSat	
callUrlFreebox $freeboxCode "down" false 1
callUrlFreebox $freeboxCode "down" false 1
callUrlFreebox $freeboxCode "down" false 1
callUrlFreebox $freeboxCode "ok" false 10
# iTélé	
size=${#channel}
i=1
echo "$(timestamp) [TV] Chaine $channel";
while [ "$i" -le "$size" ]
do
	touche=`echo $channel | cut -c$i-$i`
	i=$(($i+1))
	callUrlFreebox $freeboxCode $touche true 0.5
done
echo "$(timestamp) [TV] FIN";
