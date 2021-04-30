FROM node:slim
# Construit à partir de Node
LABEL MAINTAINER="vincent.zwingmann@github.com"

WORKDIR /usr/app

RUN npm install -g npm@7.11.1

RUN ls
COPY ./node_modules ./
COPY ./apps.js ./
RUN ls
RUN npm install
RUN ls
CMD ["node", "app.js"]
