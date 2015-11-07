#!/bin/sh
SCRIPT_LOG_DIR=/home/pi/appli/domoticz/scripts/logs/script_detecteur_presence.log

API_DOMOTICZ="http://localhost:8080/json.htm?"
valeur_courante=0
EXPIRATION_DATE=0
# Fonction Date pour les logs
timestamp() {
  date +"%d/%m/%y %T"
}

# Fonction
log() {
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


# Envoi du statut de l'alarme
sendNotificationPresence() {
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

	dateCapteurs=`date +"%Y%m%d%H%M%S"`
			
	# Présence
	if [ $a -eq "1" ]
	then
		# Mise à jour de la date d'expiration
		EXPIRATION_DATE=$(date -d "+3 minutes" +"%Y%m%d%H%M%S")
		#log "[ $dateCapteurs ] Mise à jour de la date d'expiration du statut de présence $EXPIRATION_DATE"
		# Changement de la valeur
		if [ $a -ne $valeur_courante ] 
		then 
			# Envoi de la notificationd de présence
			valeur_courante=$a
			log "Changement du statut de présence : $a"
			sendNotificationPresence
		fi
	# Absence
	elif [ $a -ne $valeur_courante ]
	then
		# Absence => On mets à jour seulement au bout de 30 secondes
		if [ $dateCapteurs -ge $EXPIRATION_DATE ] 
		then
			log "Changement du statut de présence : $a"
			valeur_courante=$a
			EXPIRATION_DATE=$(date +"%Y%m%d%H%M%S")
			# Envoi de la notification de présence
			sendNotificationPresence
		#else
		#	log "Le statut On expire seulement à $EXPIRATION_DATE."
		fi
	fi   
done
