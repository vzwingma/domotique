#!/bin/bash


freeboxCode=$1
appToken=Fj7sTpT/iLpNiB6kA9owGJ143ryRKz5U6ETWlEY9ofoTF0pB0OYv7QrRwwM1ufI/
appId=domotique.box

apiv3=http://mafreebox.freebox.fr/api/v3

# Date
timestamp() {
  date +"%d/%m/%y %T"
}

log() {
	echo "$(timestamp) [FREEBOX] $1";
}

jsonValue() {
	KEY=$1
	num=$2
	awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

sessionToken=""
connectToFreebox(){
log "Connexion à la Freebox"
# Appel de login pour charger le challenge
	DATA=`curl -s $apiv3/login`
#	log $DATA

	challenge=`echo $DATA | jsonValue challenge 1`
	challenge=${challenge//\\/}
	log "  Challenge : $challenge"

log "Calcul HMAC SHA1"
	log "  AppToken : $appToken"
	password=`echo -n $challenge | openssl dgst -sha1 -hmac $appToken | cut -c10-200`
	log "  Password : $password"

# Connect
	DATA=`curl -s -H "Content-Type: application/json" -X POST -d '{ "app_id": "'$appId'","password": "'$password'" }' $apiv3/login/session/`
#	log $DATA

	sessionToken=`echo $DATA | jsonValue session_token 1`
	sessionToken=${sessionToken//\\/}
	log "  Session Token : $sessionToken"
}


echo ""
echo ""
echo ""
log "Statuts des périphériques réseau Freebox";

# Connexion à la freebox
connectToFreebox
DATA=`curl -s -H "Content-Type: application/json" -H "X-Fbx-App-Auth: "$sessionToken -X GET $apiv3/lan/browser/pub/`
log $DATA
echo $DATA | jsonValue type 1

log "FIN";
