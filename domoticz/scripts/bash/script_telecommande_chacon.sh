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
	echo "$(timestamp) [DI/O] " $1  >> $SCRIPT_LOG_DIR
}  

# Vérification des paramètres
if [ $# -ne 2 ]        
then                   
    log "ERREUR : le nombre d'arguments du script n'est pas correct."
    log "ERREUR Parametre 1 : N° du bouton [0 ; 2] ou [3 ; 5]"
    log "ERREUR Parametre 2 : Etat [on|off] \n "
    exit 1
fi


# N° Wiring du GPIO
pin=0
# Code de télécommande 
telecommande=16679162
# Bouton O à 2 pour la télécommande 1 et de 3 à 5 pour la télécommande 2
bouton=$1
# on ou off
onoff=$2


if [ "$bouton" -gt "5" ]||[ "$bouton" -lt "0" ] 
then
    log "ERREUR le bouton $bouton est incorrect"
    return 512
fi
notelecommande=$(($bouton/2))



log "Ecriture sur le pin [$pin] "
log "Commande $onoff"

for b in 1 2 3 4 5
do
 #  sudo $RADIO_DIR/radioEmission $pin $telecommande $bouton $onoff >> $SCRIPT_LOG_DIR
done
log "Fin de la commande"
