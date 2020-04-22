#!/usr/bin/env bashio
set -e
DOMAIN=$(bashio::config 'domain')
KEYFILE=$(bashio::config 'keyfile')
CERTFILE=$(bashio::config 'certfile')
HSTS=$(bashio::config 'hsts')

# Prepare config file
sed -i "s/%%FULLCHAIN%%/$CERTFILE/g" /etc/nginx.conf
sed -i "s/%%PRIVKEY%%/$KEYFILE/g" /etc/nginx.conf
sed -i "s/%%DOMAIN%%/$DOMAIN/g" /etc/nginx.conf

[ -n "$HSTS" ] && HSTS="add_header Strict-Transport-Security \"$HSTS\" always;"
sed -i "s/%%HSTS%%/$HSTS/g" /etc/nginx.conf

# start server
bashio::log.info "Running nginx..."
exec nginx -c /etc/nginx.conf < /dev/null
