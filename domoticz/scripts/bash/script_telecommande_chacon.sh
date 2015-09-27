#!/bin/bash

APPLI_DIR=/home/pi/appli
DOMOTICZ_DIR=$APPLI_DIR/domoticz/scripts
RADIO_DIR=$APPLI_DIR/radioEmission
SCRIPT_LOG_DIR=$DOMOTICZ_DIR/logs/script_telecommande_chacon.log

# Fonction Date pour les logs
timestamp() {
  date +"%d/%m/%y %T"
}

# Fonction
function log {
	echo "$(timestamp) [DI/O] " $1 >> $SCRIPT_LOG_DIR
}  

# Vérification des paramètres
if [ $# -ne 3 ]
then                   
    log "ERREUR : le nombre d'arguments du script n'est pas correct."
    log "ERREUR Parametre 1 : Code télécommande"
	log "ERREUR Parametre 2 : N° du bouton [0 ; 2]"
    log "ERREUR Parametre 3 : Etat [on|off]"
    exit 1
fi


# N° Wiring du GPIO
pin=0
# Codes de télécommandes radio
telecommande1=16679162
telecommande2=17337810
telecommande=$1
# Bouton O à 2 pour la télécommande 1 et de 3 à 5 pour la télécommande 2
bouton=$2
# on ou off
onoff=$3


if [ "$bouton" -gt "2" ]||[ "$bouton" -lt "0" ] 
then
    log "ERREUR la valeur du bouton [$bouton] est incorrecte"
    exit 512
fi


log "Utilisation de la télécommande $telecommande" 
log "Ecriture sur le pin [$pin] "
log "Commande $onoff sur le bouton $bouton"

for b in 1 2 3 4 5
do
	log "radioEmission $pin $telecommande $bouton $onoff"
	sudo $RADIO_DIR/radioEmission $pin $telecommande $bouton $onoff >> $SCRIPT_LOG_DIR
done
log "Fin de la commande"
