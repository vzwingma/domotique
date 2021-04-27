#!/bin/bash
if [ -z ${TZ+x} ]; then export TZ=Europe/Paris; fi
rm /etc/localtime
cd /etc; ln -s /usr/share/zoneinfo/$TZ localtime
/src/domoticz/domoticz -dbase /config/domoticz.db -log /config/domoticz.log -www 8080 -sslwww 8443 -sslcert /src/domoticz/server_cert.pem
