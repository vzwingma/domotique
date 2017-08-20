FROM hypriot/wiringpi
MAINTAINER vincent.zwingmann@github.com
RUN apt-get update
RUN apt-get install -y node npm
RUN npm install express --save
RUN npm install child_process --save

EXPOSE 9000
# ENTRYPOINT ["nodejs", "server"]