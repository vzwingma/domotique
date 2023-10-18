FROM node:16.20.2-slim
# Construit à partir de Node
LABEL MAINTAINER="vincent.zwingmann@github.com"

WORKDIR /usr/app

COPY package*.json ./
COPY ./ ./

RUN npm install --save

EXPOSE 9001

CMD ["node" , "app.js"]
