FROM node:26.13.0-bookworm-slim@sha256:add5c17c14752c54d2f3d519ec46a3815684d41c33f198bcb09fb998f7dcbf68
LABEL vzwingma.domatic.tydom.image.authors="vincent.zwingmann@github.com"

ENV NODE_ENV=production

# La box Tydom impose la renégociation TLS legacy, refusée par défaut par OpenSSL 3 (Node 26).
# Périmètre limité à ce conteneur.
RUN printf '%s\n' 'openssl_conf = openssl_init' '' '[openssl_init]' 'ssl_conf = ssl_sect' '' '[ssl_sect]' 'system_default = system_default_sect' '' '[system_default_sect]' 'Options = UnsafeLegacyRenegotiation' > /etc/ssl/tydom-openssl.cnf
ENV OPENSSL_CONF=/etc/ssl/tydom-openssl.cnf

WORKDIR /usr/app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY app.js ./

EXPOSE 9001

CMD ["node" , "app.js"]
