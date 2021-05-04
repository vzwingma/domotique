FROM domoticz/domoticz:latest
# Construit à partir de domoticz/domoticz:latest
MAINTAINER vincent.zwingmann@github.com

COPY start.sh /
COPY *.lua /opt/domoticz/userdata/scripts/dzVents/generated_scripts
COPY *.py /opt/domoticz/plugins

RUN chmod +x /start.sh
