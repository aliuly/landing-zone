#!/bin/bash

# Exit on error
set -e

# Define URLs for Let's Encrypt Staging Certificates
# These are the certificates used in the ACME v2 staging environment
STAGING_ROOT_URL="https://letsencrypt.org/certs/staging/letsencrypt-stg-root-x1.pem"
STAGING_INT_URL="https://letsencrypt.org/certs/staging/letsencrypt-stg-int-r3.pem"

# Target directory for user-added CA certificates on Ubuntu
CA_DIR="/usr/local/share/ca-certificates"

echo "Checking for sudo privileges..."
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root or with sudo."
  exit 1
fi

echo "Downloading Let's Encrypt Staging Certificates..."

# Download and rename to .crt (required by update-ca-certificates)
curl -sL $STAGING_ROOT_URL -o "${CA_DIR}/letsencrypt-stg-root-x1.crt"
curl -sL $STAGING_INT_URL -o "${CA_DIR}/letsencrypt-stg-int-r3.crt"

echo "Updating system CA store..."
update-ca-certificates

echo "------------------------------------------------"
echo "Success! The staging CA is now trusted."
echo "You can verify this by running:"
echo "openssl s_client -showcerts -verify_return_error -connect <your-elb-domain>:443"
echo "------------------------------------------------"
