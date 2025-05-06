#!/bin/bash

# https://documentation.ubuntu.com/server/how-to/openldap/ldap-and-tls/
# requries gnutls-bin ssl-cert
# only for ubuntu and you should probably double check the script before running

ORG=''
CN=''

# Define directories and filenames
CA_DIR="/etc/ssl"
CA_INFO="${CA_DIR}/ldap-ca.info"
CA_KEY="${CA_DIR}/private/ldap-ca-key.pem"
CA_CERT_TEMP="/usr/local/share/ca-certificates/ldap-ca-cert.crt"
CA_CERT="${CA_DIR}/certs/ldap-ca-cert.pem"
SERVER_INFO="${CA_DIR}/ldap-server.info"
LDAP_DIR="/etc/ldap"
SERVER_KEY="${LDAP_DIR}/ldap-server-key.pem"
SERVER_CERT="${LDAP_DIR}/ldap-server-cert.pem"

# read in organization and host cn (FQDN)
read -p "Organization: " ORG
read -p "CA CN (FQDN): " CN

# write CA template info
cat > $CA_INFO <<EOF
cn = ${ORG}
ca
cert_signing_key
expiration_days = 3652
EOF

# write Server template info
cat > $SERVER_INFO << EOF
organization = ${ORG}
cn = ${CN}
tls_www_server
encryption_key
signing_key
expiration_days = 3652
EOF

# generate CA private key
certtool --generate-privkey \
    --bits 4096 \
    --outfile $CA_KEY

# generate CA certificate
certtool --generate-self-signed \
    --load-privkey $CA_KEY \
    --template $CA_INFO \
    --outfile $CA_CERT_TEMP

# update CA certificates
update-ca-certificates

# generate server private key
certtool --generate-privkey \
    --bits 4096 \
    --outfile $SERVER_KEY

# generate server certificate and sign certificate using CA
certtool --generate-certificate \
    --load-privkey $SERVER_KEY \
    --load-ca-certificate $CA_CERT \
    --load-ca-privkey $CA_KEY \
    --template $SERVER_INFO \
    --outfile $SERVER_CERT 

# make sure that openldap has access to the server key
chgrp openldap $SERVER_KEY
chmod 0640 $SERVER_KEY

# report the relevant files made (this is useful for running setup.sh after)
echo "
Generated TLS Certificates
+==============================+
CA Cert:     ${CA_CERT}
Server Cert: ${SERVER_CERT}
Server Key:  ${SERVER_KEY}
"