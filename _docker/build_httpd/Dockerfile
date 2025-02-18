FROM httpd:latest
# Construit à partir de httpd:latest
LABEL maintainer="vincent.zwingmann@github.com"

# Intégration du certificat
RUN mkdir -p /usr/local/apache2/conf/ssl_conf/
COPY httpddomoticzserver.crt /usr/local/apache2/conf/ssl_conf/
COPY httpddomoticzserver.key /usr/local/apache2/conf/ssl_conf/
# Intégration de la conf HTTPD.conf
COPY httpd.conf /usr/local/apache2/conf/httpd.conf

