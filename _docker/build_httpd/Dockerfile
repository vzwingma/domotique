FROM httpd:2.4-alpine
# Construit à partir de httpd:latest
ARG SERVER_NAME=domatique.freeboxos.fr
ENV SERVER_NAME=${SERVER_NAME}
LABEL vzwingma.domatic.httpd.image.authors="vincent.zwingmann@github.com"

# OpenSSL reste disponible pour l'initialisation du certificat au démarrage.
RUN apk add --no-cache openssl

COPY httpd-cert-init.sh /usr/local/bin/httpd-cert-init.sh
RUN chmod 755 /usr/local/bin/httpd-cert-init.sh

# Intégration de la conf HTTPD.conf
COPY httpd.conf /usr/local/apache2/conf/httpd.conf

ENTRYPOINT ["/usr/local/bin/httpd-cert-init.sh"]
