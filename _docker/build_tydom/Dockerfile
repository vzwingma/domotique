FROM arm32v7/node:16-alpine
#FROM node:16-alpine
# Construit à partir de Node
LABEL MAINTAINER="vincent.zwingmann@github.com"

WORKDIR /usr/app

COPY package*.json ./
COPY ./ ./

RUN npm install --save

EXPOSE 9001

CMD ["node" , "app.js"]
