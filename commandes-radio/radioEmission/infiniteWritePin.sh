#!/bin/sh


pin=$1
onoff=$2

echo "Ecriture sur le pin [$pin] : $onoff" 

while [ true ]
do
   echo $a
   a=`sudo ./radioEmission $pin 16679162 0 $onoff`
done
