#!/bin/sh

APPLI_DIR=/home/pi/appli
DOMOTICZ_DIR=$APPLI_DIR/domoticz/scripts
RADIO_DIR=$APPLI_DIR/radioEmission
# N° Wiring du GPIO
pin=0
# Code de télécommande 
telecommande=16679162
# Bouton O à 2
bouton=$1
# on ou off
onoff=$2

# Fonction Date pour les logs
timestamp() {
  date +"%d/%m/%y %T"
}

echo  "">> $DOMOTICZ_DIR/logs/telecommandeChacon.log
echo  "$(timestamp) [DI/O] Ecriture sur le pin [$pin] " >> $DOMOTICZ_DIR/logs/telecommandeChacon.log
echo  "$(timestamp) [DI/O]  Commande $onoff" >> $DOMOTICZ_DIR/logs/telecommandeChacon.log 

for b in 1 2
do
   sudo $RADIO_DIR/radioEmission $pin $telecommande $bouton $onoff >> $DOMOTICZ_DIR/logs/telecommandeChacon.log
done
echo  "$(timestamp) [DI/O] Fin de la commande" >> $DOMOTICZ_DIR/logs/telecommandeChacon.log
