FROM node:26.13.0-bookworm-slim@sha256:add5c17c14752c54d2f3d519ec46a3815684d41c33f198bcb09fb998f7dcbf68
LABEL vzwingma.domatic.tydom.image.authors="vincent.zwingmann@github.com"

ENV NODE_ENV=production

WORKDIR /usr/app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY app.js ./

EXPOSE 9001

CMD ["node" , "app.js"]
