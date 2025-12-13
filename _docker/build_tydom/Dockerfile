FROM node:24.12.0-slim
# Construit à partir de Node
LABEL vzwingma.domatic.tydom.image.authors="vincent.zwingmann@github.com"

WORKDIR /usr/app

COPY package*.json ./
COPY ./ ./

RUN npm install --save

EXPOSE 9001

CMD ["node" , "app.js"]
