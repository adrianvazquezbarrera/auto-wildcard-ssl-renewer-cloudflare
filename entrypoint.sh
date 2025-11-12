#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status

# Create a cloudflare.ini file with API token from environment variable
echo "dns_cloudflare_api_token=${CLOUDFLARE_API_TOKEN}" > /cloudflare.ini
chmod 600 /cloudflare.ini

# Obtain a wildcard SSL certificate using Certbot with Cloudflare DNS plugin
certbot certonly \
--dns-cloudflare \
--dns-cloudflare-credentials /cloudflare.ini \
--dns-cloudflare-propagation-seconds 60 \
-d "${DOMAIN}" \
--non-interactive \
--agree-tos \
-m apps@adrianvb.com

# Move the obtained certificates to a persistent location
mkdir -p /certificates/"${PRIMARY_DOMAIN}"

cp /etc/letsencrypt/live/"${PRIMARY_DOMAIN}"/fullchain.pem /certificates/"${PRIMARY_DOMAIN}"/chain.crt
cp /etc/letsencrypt/live/"${PRIMARY_DOMAIN}"/privkey.pem /certificates/"${PRIMARY_DOMAIN}"/privkey.key

# Create alsocertificate.yml file for use with traeffik
echo "tls:" > /certificates/"${PRIMARY_DOMAIN}"/certificate.yml
echo "  certificates:" >> /certificates/"${PRIMARY_DOMAIN}"/certificate.yml
echo "    - certFile: ${BASE_CERT_PATH}/chain.crt" >> /certificates/"${PRIMARY_DOMAIN}"/certificate.yml
echo "      keyFile: ${BASE_CERT_PATH}/privkey.key" >> /certificates/"${PRIMARY_DOMAIN}"/certificate.yml