FROM domoticz/domoticz:latest
# Construit à partir de domoticz/domoticz:latest
MAINTAINER vincent.zwingmann@github.com

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y python3-dev

RUN mkdir -p /opt/domoticz/userdata/scripts/dzVents/generated_scripts
COPY *.lua /opt/domoticz/userdata/scripts/dzVents/generated_scripts

# Intégration du plugin Linky
RUN mkdir -p /opt/domoticz/userdata/plugins/DomoticzLinky
COPY linky/plugin.py /opt/domoticz/userdata/plugins/DomoticzLinky
RUN chmod +x /opt/domoticz/userdata/plugins/DomoticzLinky/plugin.py

# Intégration du plugin deCONZ
RUN mkdir -p /opt/domoticz/userdata/plugins/Domoticz-deCONZ
COPY deconz/plugin.py /opt/domoticz/userdata/plugins/Domoticz-deCONZ
COPY deconz/fonctions.py /opt/domoticz/userdata/plugins/Domoticz-deCONZ
COPY deconz/API_KEY.py /opt/domoticz/userdata/plugins/Domoticz-deCONZ
RUN chmod +x /opt/domoticz/userdata/plugins/Domoticz-deCONZ/plugin.py