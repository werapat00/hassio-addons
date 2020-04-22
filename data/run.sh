#!/usr/bin/env bashio
set -e
CLOUDFLARE_CONF=/data/cloudflare.conf

DOMAIN=$(bashio::config 'domain')
KEYFILE=$(bashio::config 'keyfile')
CERTFILE=$(bashio::config 'certfile')
HSTS=$(bashio::config 'hsts')

if bashio::config.true 'cloudflare'; then
    sed -i "s|#include /data/cloudflare.conf;|include /data/cloudflare.conf;|" /etc/nginx.conf
    # Generate cloudflare.conf
    if ! bashio::fs.file_exists "${CLOUDFLARE_CONF}"; then
        bashio::log.info "Creating 'cloudflare.conf' for real visitor IP address..."
        echo "# Cloudflare IP addresses" > $CLOUDFLARE_CONF;
        echo "" >> $CLOUDFLARE_CONF;

        echo "# - IPv4" >> $CLOUDFLARE_CONF;
        for i in $(curl https://www.cloudflare.com/ips-v4); do
            echo "set_real_ip_from ${i};" >> $CLOUDFLARE_CONF;
        done

        echo "" >> $CLOUDFLARE_CONF;
        echo "# - IPv6" >> $CLOUDFLARE_CONF;
        for i in $(curl https://www.cloudflare.com/ips-v6); do
            echo "set_real_ip_from ${i};" >> $CLOUDFLARE_CONF;
        done

        echo "" >> $CLOUDFLARE_CONF;
        echo "real_ip_header CF-Connecting-IP;" >> $CLOUDFLARE_CONF;
    fi
fi

# Prepare config file
sed -i "s/%%DOMAIN%%/$DOMAIN/g" /etc/nginx.conf

# Allow customize configs from share
if bashio::config.true 'customize.active'; then
    CUSTOMIZE_DEFAULT=$(bashio::config 'customize.default')
    sed -i "s|#include /share/nginx_proxy_default.*|include /share/$CUSTOMIZE_DEFAULT;|" /etc/nginx.conf
    CUSTOMIZE_SERVERS=$(bashio::config 'customize.servers')
    sed -i "s|#include /share/nginx_proxy/.*|include /share/$CUSTOMIZE_SERVERS;|" /etc/nginx.conf
fi

# start server
bashio::log.info "Running nginx..."
exec nginx -c /etc/nginx.conf < /dev/null
