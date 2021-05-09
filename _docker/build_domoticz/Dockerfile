FROM domoticz/domoticz:latest
# Construit à partir de domoticz/domoticz:latest
MAINTAINER vincent.zwingmann@github.com

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y python3-dev

COPY *.lua /opt/domoticz/userdata/scripts/dzVents/generated_scripts
COPY *.py /opt/domoticz/userdata/plugins/DomoticzLinky
RUN chmod ugo+x /opt/domoticz/userdata/plugins/DomoticzLinky/plugin.py