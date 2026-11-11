FROM node:26.13.1-bookworm-slim@sha256:5df79989ed685e09f0a98019db4cebfb22fb9df1a53c0161664a011f7ff6b0f1
LABEL vzwingma.domatic.tydom.image.authors="vincent.zwingmann@github.com"

ENV NODE_ENV=production

# La box Tydom impose la renégociation TLS legacy et un certificat à clé faible (< 1024 bits),
# refusés par défaut par OpenSSL 3 (Node 26).
# Périmètre limité à ce conteneur.
RUN mkdir -p /usr/local/etc && printf '%s\n' 'nodejs_conf = openssl_init' '' '[openssl_init]' 'ssl_conf = ssl_sect' '' '[ssl_sect]' 'system_default = system_default_sect' '' '[system_default_sect]' 'Options = UnsafeLegacyRenegotiation' 'CipherString = DEFAULT:@SECLEVEL=0' > /usr/local/etc/tydom-openssl.cnf
ENV OPENSSL_CONF=/usr/local/etc/tydom-openssl.cnf

WORKDIR /usr/app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY app.js ./

EXPOSE 9001

CMD ["node" , "app.js"]
