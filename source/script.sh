#!/bin/bash

mkdir -p html apache-config

echo "<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"UTF-8\"><title>Hello World</title></head><body><h1>Hello World</h1></body></html>" > html/index.html

cat <<EOL > apache-config/000-default.conf
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /usr/local/apache2/htdocs/
   
    <Directory />
        Order Deny,Allow
        Deny from all
        Allow from 172.18.0.0/16 # Default Dockernetz
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL


cat <<EOL > docker-compose.yaml
version: '3'

services:
  apache:
    image: httpd:latest
    container_name: apache_container
    networks:
      private_network:
        aliases:
          - lab.eggerts.it
 
    volumes:
      - ./html:/usr/local/apache2/htdocs/
      - ./apache-config:/usr/local/apache2/conf/sites-available
 
  zpa_connector:
    image: zscaler/zpa-connector:latest.amd64
    container_name: zpa_connector_container
    networks:
      - private_network
      - external_network
    cap_add:
      - NET_ADMIN
      - NET_BIND_SERVICE
      - NET_RAW
      - SYS_NICE
      - SYS_TIME
    environment:
      - ZPA_PROVISION_KEY=4|api.private.zscaler.com|UbnBU..........
    restart: always
    init: true

networks:
  private_network:
  external_network:
 
EOL

docker compose up -d
