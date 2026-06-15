FROM httpd:2.4-alpine
# Construit à partir de httpd:latest
ARG SERVER_NAME=domatique.freeboxos.fr
LABEL vzwingma.domatic.httpd.image.authors="vincent.zwingmann@github.com"

# Génération du certificat TLS auto-signé au build, aligné sur le hostname public
RUN mkdir -p /usr/local/apache2/conf/ssl_conf/ && \
    apk add --no-cache openssl && \
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
      -keyout /usr/local/apache2/conf/ssl_conf/httpddomoticzserver.key \
      -out /usr/local/apache2/conf/ssl_conf/httpddomoticzserver.crt \
      -subj "/CN=${SERVER_NAME}/O=Home/C=FR" \
      -addext "subjectAltName=DNS:${SERVER_NAME}"
# Intégration de la conf HTTPD.conf
COPY httpd.conf /usr/local/apache2/conf/httpd.conf
