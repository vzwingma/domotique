FROM httpd:2.4-alpine
# Construit à partir de httpd:latest
LABEL vzwingma.domatic.httpd.image.authors="vincent.zwingmann@github.com"

# Création du répertoire SSL (certificat monté via volume Let's Encrypt)
RUN mkdir -p /usr/local/apache2/conf/ssl_conf/ && \
    mkdir -p /var/www/certbot
# Intégration de la conf HTTPD.conf
COPY httpd.conf /usr/local/apache2/conf/httpd.conf

