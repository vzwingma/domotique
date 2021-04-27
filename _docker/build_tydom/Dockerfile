FROM node:slim
# Construit à partir de Node
MAINTAINER vincent.zwingmann@github.com

WORKDIR /usr/app

RUN npm install -g npm@7.11.1
COPY ./ ./
RUN npm install
CMD ["node", "app.js"]
