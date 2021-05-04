FROM domoticz/domoticz:latest
# Construit à partir de domoticz/domoticz:latest
MAINTAINER vincent.zwingmann@github.com

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y python3-dev

COPY start.sh /
COPY *.lua /opt/domoticz/userdata/scripts/dzVents/generated_scripts
COPY *.py /opt/domoticz/plugins/DomoticzLinky/
RUN chmod ugo+x /opt/domoticz/plugins/DomoticzLinky/plugin.py

RUN chmod +x /start.sh
