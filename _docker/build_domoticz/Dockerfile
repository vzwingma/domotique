FROM domoticz/domoticz:latest
# Construit à partir de domoticz/domoticz:latest
MAINTAINER vincent.zwingmann@github.com

RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y python3-dev && \
	apt-get install -y curl

RUN mkdir -p /opt/domoticz/userdata/scripts/dzVents/generated_scripts
COPY *.lua /opt/domoticz/userdata/scripts/dzVents/generated_scripts

RUN mkdir -p /opt/domoticz/userdata/plugins/DomoticzLinky
COPY plugin.py /opt/domoticz/userdata/plugins/DomoticzLinky
RUN chmod +x /opt/domoticz/userdata/plugins/DomoticzLinky/plugin.py