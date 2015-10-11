#!/bin/bash
SCRIPT_LOG_DIR=/home/pi/appli/domoticz/scripts/logs/script_detecteur_presence.log

API_DOMOTICZ="http://localhost:8080/json.htm?"
valeur_courante=0

# Fonction Date pour les logs
timestamp() {
  date +"%d/%m/%y %T"
}

# Fonction
function log {
	echo "$(timestamp) [PIR] " $1 >> $SCRIPT_LOG_DIR
}  


# Vérification des paramètres
if [ $# -ne 3 ]
then                   
    log "ERREUR : le nombre d'arguments du script n'est pas correct."
    log "ERREUR : Parametre 1 : N° WiringPi de l'entrée du capteur PIR"
	log "ERREUR : Parametre 2 : capteur_id_presence : Id du capteur 'visibilté' dans Domoticz utilisée pour stocker la présence de qqu'un"
	log "ERREUR : Parametre 3 : Basic Authenticatio pour l'accès à l'API Domoticz"
    exit 1
fi
pin=$1
capteur_id_presence=$2
domoticz_basic_auth="Basic "$3
# Envoi du statut de présence,
function getValeurCourantePresence {
	presence=$#
	# Appel de la valeur courante
	urlStatut=$API_DOMOTICZ"type=devices&rid=$capteur_id_presence"
	# log "  Appel de $urlStatut pour la présence $presence"
	DATA=`curl -s -H "Authorization: $domoticz_basic_auth" -X GET $urlStatut`
	# log " $DATA"
	statut_actuel_presence=`echo $DATA | jq '.result[0].Visibility'`
	log "Valeur courante : $statut_actuel_presence"
}


# Envoi du statut de l'alarme
function sendNotificationPresence {
	log " Envoi du statut de présence [$valeur_courante] dans Domoticz"	
	statut_capteur="Off"
	if [ $valeur_courante -eq "1" ]
	then
		statut_capteur="On"
	fi
	url=$API_DOMOTICZ"type=command&param=switchlight&idx="$capteur_id_presence"&switchcmd="$statut_capteur
	log "  Appel de  $url"
	resultat=`curl -s -H "Authorization: $domoticz_basic_auth" -X GET $url`
	log "  > $resultat"	
}


# Boucle principale
log "Lecture du pin [$pin]" 


while [ true ]
do
   # printf %s $a
   a=`gpio read $pin`
   
   if [ $a -ne $valeur_courante ]
	then                   
		log "Changement du statut de présence : $a"
		valeur_courante=$a
		# Envoi de la notificationd de présence
		sendNotificationPresence $a
		
	fi
   
done
