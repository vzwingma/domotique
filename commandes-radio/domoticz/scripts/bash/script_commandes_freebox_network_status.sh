#!/bin/bash


# Fonction Date pour les logs
timestamp() {
  date +"%d/%m/%y %T"
}

if [ $# -lt 7 ]
then
    echo "$(timestamp) [FREEBOX] Le script requiert 6 paramètres dans les UserVariables de Domoticz : "
	echo "$(timestamp) [FREEBOX] - freebox_appid		: id applicatif défini lors de l'enregistrement de l'application dans FreeboxOS"
	echo "$(timestamp) [FREEBOX] - freebox_apptoken		: token applicatif créé lors de l'enregistrement de l'application dans FreeboxOS"
	echo "$(timestamp) [FREEBOX] - freebox_id_Smartphone_V	: id du périphérique Smartphone V" 
	echo "$(timestamp) [FREEBOX] - interrupteur_id_Smartphone_V : id de l'interrupteur correspondant dans Domoticz "
	echo "$(timestamp) [FREEBOX] - freebox_id_Smartphone_S		: id du périphérique Smartphone S" 
	echo "$(timestamp) [FREEBOX] - interrupteur_id_Smartphone_S : id de l'interrupteur correspondant dnas Domoticz"
	echo "$(timestamp) [FREEBOX] - domoticz_basic_auth : login/mdp en Basic Authentication pour les appels vers Domoticz"
    exit 1
fi

freebox_appid=$1
freebox_apptoken=$2
# Hook car Domoticz ajoute index.html dans la variable freebox_apptoken 
freebox_apptoken=${freebox_apptoken//index.html/}
freebox_id_Smartphone_V=$3
freebox_id_Smartphone_V=${freebox_id_Smartphone_V//\"/}
interrupteur_id_Smartphone_V=$4
freebox_id_Smartphone_S=$5
freebox_id_Smartphone_S=${freebox_id_Smartphone_S//\"/}
interrupteur_id_Smartphone_S=$6
domoticz_basic_auth=$7

# Init des variables
statut_smartphone_V="Off"
statut_smartphone_S="Off"

sessionToken=""
apiFreeboxv3=http://mafreebox.freebox.fr/api/v3
apiDomoticz="http://localhost:8080/json.htm?" # switchlight&level=0&idx=16&switchcmd=On


# Fonction log
log() {
	echo "$(timestamp) [FREEBOX] $1";
}


# Fonction de connexion à la Freebox pour récupérer le sessionToken
connectToFreebox(){
	log "Connexion à la Freebox"
		# Appel de login pour charger le challenge
		DATA=`curl -s $apiFreeboxv3/login`
		# Résultat de l'appel Login
		# log $DATA

		challenge=`echo $DATA | jq '.result.challenge'`
		challenge=${challenge//\\/}
		challenge=${challenge//\"/}
	log "  Challenge : $challenge"

	log "Calcul HMAC SHA1"
	log "  AppToken : $freebox_apptoken"
		password=`echo -n $challenge | openssl dgst -sha1 -hmac $freebox_apptoken | cut -c10-200`
	log "  Password : $password"

	# Connect
	DATA=`curl -s -H "Content-Type: application/json" -X POST -d '{ "app_id": "'$freebox_appid'","password": "'$password'" }' $apiFreeboxv3/login/session/`
	#	connexion à la session
	#	log $DATA

		sessionToken=`echo $DATA | jq '.result.session_token'`
		sessionToken=${sessionToken//\\/}
		sessionToken=${sessionToken//\"/}
	log "  Session Token : $sessionToken"
}


echo ""
echo ""
echo ""
log "Statuts des périphériques réseau Freebox";

# Connexion à la freebox
connectToFreebox
# Appel sur la liste des périphériques
log "Recherche des périphériques connus de la Freebox"
DATA=`curl -s -H "Content-Type: application/json" -H "X-Fbx-App-Auth: "$sessionToken -X GET $apiFreeboxv3/lan/browser/pub/`

# Simplification des résultats sous forme d'un arbre JSON {nom/type/reachable/active} pour chaque resultat
DATA=`echo $DATA | jq '[.result | .[] | {active : .active, reachable : .reachable, type : .host_type, nom : .names[0].name, id : .id}]'`
# log $DATA
# Liste des résultats
size=`echo $DATA | jq '. | length'`

log "  Nombre de périphériques :  $size"

i=1
while [ "$i" -le "$size" ]
do
	type=`echo $DATA | jq '.['$i'].type'`
	type=${type//\"/}
	reachable=`echo $DATA | jq '.['$i'].reachable'`
  	active=`echo $DATA | jq '.['$i'].active'`
	id=`echo $DATA | jq '.['$i'].id'`
	id=${id//\"/}

	if [[ "$reachable" = true && "$active" = true && "$type" == "smartphone" ]]
	then
		if [ "$id" == "$freebox_id_Smartphone_V" ] 
		then
			log "	> Le smartphone V est connecté"
			statut_smartphone_V="On"
		elif [ "$id" == "$freebox_id_Smartphone_S" ]
		then
			log "	> Le smartphone S est connecté"
			statut_smartphone_S="On"
		fi
fi
	i=$(($i+1))
done

log " Recherche des statuts actuels des interrupteurs"

	url=$apiDomoticz"type=devices&rid="$interrupteur_id_Smartphone_V
	log "  Appel de $url"
	DATA=`curl -s -H "Authorization: $domoticz_basic_auth" -X GET $url`
	statut_actuel_V=`echo $DATA | jq '.result[0].Status'`
	statut_actuel_V=${statut_actuel_V//\"/}
	log "  > $statut_actuel_V"

	url=$apiDomoticz"type=devices&rid="$interrupteur_id_Smartphone_S
	log "  Appel de $url"
	resultat=`curl -s -H "Authorization: $domoticz_basic_auth" -X GET $url`
	statut_actuel_S=`echo $DATA | jq '.result[0].Status'`
	statut_actuel_S=${statut_actuel_S//\"/}
	log "  > $statut_actuel_S"
	
	
log " Envoi des statuts des smartphones dans Domoticz"
	if [ "$statut_smartphone_V" != "$statut_actuel_V" ] 
	then
		url=$apiDomoticz"type=command&param=switchlight&level=0&idx="$interrupteur_id_Smartphone_V"&switchcmd="$statut_smartphone_V
		log "  Appel de $url"
		resultat=`curl -s -H "Authorization: $domoticz_basic_auth" -X GET $url`
		log "  > $resultat"
	fi
	if [ "$statut_smartphone_V" != "$statut_actuel_S" ] 
	then
		url=$apiDomoticz"type=command&param=switchlight&level=0&idx="$interrupteur_id_Smartphone_S"&switchcmd="$statut_smartphone_S
		log "  Appel de $url"
		resultat=`curl -s -H "Authorization: $domoticz_basic_auth" -X GET $url`
		log "  > $resultat"
	fi
	
log "FIN"
