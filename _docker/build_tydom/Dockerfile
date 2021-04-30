FROM node:16-alpine
# Construit à partir de Node
LABEL MAINTAINER="vincent.zwingmann@github.com"

WORKDIR /usr/app

COPY package*.json ./
RUN npm install

COPY ./ ./

EXPOSE 9001

CMD ["node", "app.js"]
