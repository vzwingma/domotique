FROM httpd:2.4-alpine
# Construit à partir de httpd:latest
LABEL vzwingma.domatic.httpd.image.authors="vincent.zwingmann@github.com"

# Génération du certificat TLS auto-signé au build
RUN mkdir -p /usr/local/apache2/conf/ssl_conf/ && \
    apk add --no-cache openssl && \
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
      -keyout /usr/local/apache2/conf/ssl_conf/httpddomoticzserver.key \
      -out /usr/local/apache2/conf/ssl_conf/httpddomoticzserver.crt \
      -subj "/CN=domoticz/O=Home/C=FR"
# Intégration de la conf HTTPD.conf
COPY httpd.conf /usr/local/apache2/conf/httpd.conf

