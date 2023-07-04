#!/bin/bash

##
## https://www.golinuxcloud.com/openssl-create-certificate-chain-linux/
##

D=./cacerts
R=${D}/openssl_root.cnf
I=${D}/openssl_intermediate.cnf

SC='ZZ'
SST='FantasyLand'
SL='Paradise'
SO='Acme Corp.'
SOU='Acme Baas Private Certificate Authority'
SRCN='Acme Baas Private Root CA'
SICN='Acme BaaS Private Intermediate CA'
SEA='acme@example.com'

R_START="$( date -u                 '+%y%m%d' )000000Z"
R_END="$(   date -u -d '+12 months' '+%y%m%d' )000000Z"

I_START="$( date -u                 '+%y%m%d' )000000Z"
I_END="$(   date -u -d '+12 months' '+%y%m%d' )000000Z"

##
## Step 1: Create OpenSSL Root CA directory structure
##

function startup()
{

# Each directory in your Certificate Authority (CA) folder structure serves a specific purpose:
#
# certs: This directory contains the certificates generated and signed by the CA. For the root CA, this includes the root CA certificate itself. For the intermediate CA, this includes the intermediate CA certificate and any server or client certificates signed by the intermediate CA.
# crl: The Certificate Revocation List (CRL) directory contains the CRLs generated by the CA. A CRL is a list of certificates that have been revoked by the CA before their expiration date.
# newcerts: This directory stores a copy of each certificate signed by the CA, with the certificate's serial number as the file name. It helps maintain a backup of all issued certificates.
# private: This directory contains the private keys for the CA, including the root CA and intermediate CA private keys. These keys are used to sign certificates and CRLs. The private keys should be kept secure and not shared.
#
  mkdir -p ${D}/rootCA/{certs,crl,newcerts,private,csr,passw}
  mkdir -p ${D}/intermediateCA/{certs,crl,newcerts,private,csr,passw}

# A serial file is used to keep track of the last serial number that was used to issue a certificate.
# It’s important that no two certificates ever be issued with the same serial number from the same CA.
# OpenSSL is somewhat quirky about how it handles this file.
# It expects the value to be in hex, and it must contain at least two digits.
# By setting the initial value to 1000, we ensure that the serial numbers start from 1000 and increment for each subsequent certificate issued.
#
  echo 'F100' > ${D}/rootCA/serial
  echo 'F200' > ${D}/intermediateCA/serial

# A crlnumber is a configuration directive specifying the file that contains the current CRL number.
# The CRL number is a unique integer that is incremented each time a new Certificate Revocation List (CRL) is generated.
# This helps in tracking the latest CRL issued by the CA and ensuring that CRLs are issued in a proper sequence.
# We have given a random digit in our crlnumber file which will be used to keep track of all certs which are revocated.
  echo 0100 > ${D}/rootCA/crlnumber
  echo 0100 > ${D}/intermediateCA/crlnumber

# 'index.txt' file is a database of sorts that keeps track of the certificates that have been issued by the CA.
# Each line in the index.txt file represents a certificate and contains information such as the certificate's status (e.g., valid, revoked), the certificate's expiration date, the certificate's serial number, and the certificate subject's distinguished name (DN).
# Since no certificates have been issued at this point and OpenSSL requires that the file exist, we’ll simply create an empty file.
  touch ${D}/rootCA/index.txt
  touch ${D}/intermediateCA/index.txt

}

##
## Step 2: Configure openssl.cnf for Root and Intermediate CA Certificate
##

function mount_openssl_root_cnf()
{
  touch ${R}; cat<<EOF >> ${R}
[ ca ] # The default CA section
default_ca = CA_default                                  # The default CA name

[ CA_default ] # Default settings for the CA
dir               = ${D}/rootCA                     # CA directory
certs             = \$dir/certs                           # Certificates directory
crl_dir           = \$dir/crl                             # CRL directory
new_certs_dir     = \$dir/newcerts                        # New certificates directory
database          = \$dir/index.txt                       # Certificate index file
serial            = \$dir/serial                          # Serial number file
RANDFILE          = \$dir/private/.rand                   # Random number file
private_key       = \$dir/private/root.key.pem            # Root CA private key
certificate       = \$dir/certs/root.cert.pem             # Root CA certificte
crl               = \$dir/crl/root.crl.pem                # Root CA CRL
crlnumber         = \$dir/crlnumber                       # Root CA CRL number
crl_extensions    = crl_ext                              # CRL extensions
default_crl_days  = 30                                   # Default CRL validity days
default_days      = 365                                  # Default Certificate validity days
default_md        = sha256                               # Default message digest
rand_serial       = 0
preserve          = no                                   # Preserve existing extensions
email_in_dn       = yes                                  # Preserve email from the DN
name_opt          = ca_default                           # Formatting options for names
cert_opt          = ca_default                           # Certificate output options
policy            = policy_strict                        # Certificate policy
unique_subject    = yes                                  # Deny multiple certs with the same DN

[ policy_strict ] # Policy for stricter validation
countryName             = match
stateOrProvinceName     = match
localityName            = match
organizationName        = match
organizationalUnitName  = supplied
commonName              = supplied
emailAddress            = supplied

[ req ] # Request settings
default_bits        = 4096                               # Default key size
distinguished_name  = req_distinguished_name             # Default DN template
string_mask         = utf8only                           # UTF-8 encoding
default_md          = sha256                             # Default message digest
prompt              = no                                 # Non-interactive mode

[ req_distinguished_name ] # Template for the DN in the CSR
countryName             = ${SC}
stateOrProvinceName     = ${SST}
localityName            = ${SL}
0.organizationName      = ${SO}
organizationalUnitName  = ${SOU}
commonName              = ${SRCN}
emailAddress            = ${SEA}

[ v3_ca ] # Root CA certificate extensions
subjectKeyIdentifier    = hash                            # Subject key identifier
authorityKeyIdentifier  = keyid:always,issuer             # Authority key identifier
basicConstraints        = critical, CA:true               # Basic constraints for a CA
keyUsage                = critical, keyCertSign, cRLSign  # Key usage for a CA

[ crl_ext ] # CRL extensions
authorityKeyIdentifier = keyid:always,issuer        # Authority key identifier

[ v3_intermediate_ca ] # Intermediate CA certificate extensions
subjectKeyIdentifier    = hash                                              # Subject key identifier
authorityKeyIdentifier  = keyid:always,issuer                               # Authority key identifier
basicConstraints        = critical, CA:true, pathlen:0                      # Basic constraints for a CA
keyUsage                = critical, digitalSignature, cRLSign, keyCertSign  # Key usage for a CA

EOF
}

function mount_openssl_intermediate_cnf()
{
  touch ${I}; cat<<EOF >> ${I}
[ ca ]                                                   # The default CA section
default_ca = CA_default                                  # The default CA name

[ CA_default ]                                           # Default settings for the intermediate CA
dir               = ${D}/intermediateCA             # Intermediate CA directory
certs             = \$dir/certs                           # Certificates directory
crl_dir           = \$dir/crl                             # CRL directory
new_certs_dir     = \$dir/newcerts                        # New certificates directory
database          = \$dir/index.txt                       # Certificate index file
serial            = \$dir/serial                          # Serial number file
RANDFILE          = \$dir/private/.rand                   # Random number file
private_key       = \$dir/private/intermediate.key.pem    # Intermediate CA private key
certificate       = \$dir/certs/intermediate.cert.pem     # Intermediate CA certificate
crl               = \$dir/crl/intermediate.crl.pem        # Intermediate CA CRL
crlnumber         = \$dir/crlnumber                       # Intermediate CA CRL number
crl_extensions    = crl_ext                              # CRL extensions
default_crl_days  = 30                                   # Default CRL validity days
default_days      = 365                                  # Default Certificate validity days
default_md        = sha256                               # Default message digest
rand_serial       = 0
preserve          = no                                   # Preserve existing extensions
email_in_dn       = yes                                  # Preserve email from the DN
name_opt          = ca_default                           # Formatting options for names
cert_opt          = ca_default                           # Certificate output options
policy            = policy_strict                        # Certificate policy

[ policy_strict ]                                         # Policy for less strict validation
countryName             = match
stateOrProvinceName     = supplied
localityName            = optional
organizationName        = supplied
organizationalUnitName  = supplied
commonName              = supplied
emailAddress            = supplied
businessCategory        = optional

[ req ]                                                  # Request settings
default_bits        = 4096                               # Default key size
distinguished_name  = req_distinguished_name             # Default DN template
string_mask         = utf8only                           # UTF-8 encoding
default_md          = sha256                             # Default message digest
x509_extensions     = v3_intermediate_ca                 # Extensions for intermediate CA certificate

[ req_distinguished_name ]                               # Template for the DN in the CSR
countryName             = ${SC}
stateOrProvinceName     = ${SST}
localityName            = ${SL}
0.organizationName      = ${SO}
organizationalUnitName  = ${SOU}
commonName              = ${SICN}
emailAddress            = ${SEA}

[ v3_intermediate_ca ]  # Intermediate CA certificate extensions
subjectKeyIdentifier    = hash                                             # Subject key identifier
authorityKeyIdentifier  = keyid:always,issuer                              # Authority key identifier
basicConstraints        = critical, CA:true, pathlen:0                     # Basic constraints for a CA
keyUsage                = critical, digitalSignature, cRLSign, keyCertSign # Key usage for a CA

[ crl_ext ]                                                 # CRL extensions
authorityKeyIdentifier=keyid:always                         # Authority key identifier

[ server_cert ]                                             # Server certificate extensions
basicConstraints = CA:FALSE                                 # Not a CA certificate
nsCertType = server                                         # Server certificate type
keyUsage = critical, digitalSignature, keyEncipherment      # Key usage for a server cert
extendedKeyUsage = serverAuth                               # Extended key usage for server authentication purposes (e.g., TLS/SSL servers).
authorityKeyIdentifier = keyid,issuer                       # Authority key identifier linking the certificate to the issuer's public key.

EOF
}

##
## Step 3: Generate the root CA key pair and certificate
##

function generate_encrypted_plain_root_keypair()
{
  RKEY_ENC=${D}/rootCA/private/root-enc.key.pem
  RKEY_PLAIN=${D}/rootCA/private/root.key.pem

  RPASS="pass:$(openssl rand -base64 32 | base64 -d | base64 -w 0)"
  echo $RPASS > ${D}/rootCA/passw/key

  openssl genrsa -aes256 -out ${RKEY_ENC} -passout ${RPASS} 4096
  openssl rsa -in ${RKEY_ENC} -out ${RKEY_PLAIN} --passin ${RPASS}

  RPASS=
}

function generate_plain_root_keypair()
{
  RKEY_PLAIN=${D}/rootCA/private/root.key.pem

  openssl genrsa -out ${RKEY_PLAIN} 4096
}

# Create an RSA key pair for the root CA without a password
function generate_root_ca_keypair()
{
  generate_encrypted_plain_root_keypair
  #generate_plain_root_keypair

  chmod 400 ${RKEY_PLAIN}

  ## View the content of private key:
  # openssl rsa -noout -text -in ${D}/rootCA/private/root.key.pem
}

# OPTIONAL (choose one): Create Dated Root Certificate Authority Certificate
function create_root_ca_dated_certificate()
{
  openssl req -x509 \
   -config ${R} \
   -key ${D}/rootCA/private/root.key.pem \
   -new \
   -days 365 \
   -sha256 \
   -extensions v3_ca \
   -subj "/C=${SC}/ST=${SST}/L=${SL}/O=${SO}/OU=${SOU}/CN=${SRCN}/emailAddress=${SEA}" \
   -out ${D}/rootCA/certs/root.cert.pem

  chmod 444 ${D}/rootCA/certs/root.cert.pem

  ## openssl verify root CA certificate
  # openssl x509 -noout -text -in ${D}/rootCA/certs/root.cert.pem
}

# OPTIONAL (choose one): Create Timed Root Certificate Authority Certificate
function create_root_ca_timed_certificate()
{
  openssl req \
   -config ${R} \
   -key ${RKEY_PLAIN} \
   -new \
   -sha256 \
   -subj "/C=${SC}/ST=${SST}/L=${SL}/O=${SO}/OU=${SOU}/CN=${SRCN}/emailAddress=${SEA}" \
   -out ${D}/rootCA/certs/root.csr.pem

  openssl ca \
   -selfsign \
   -config ${R} \
   -extensions v3_ca \
   -keyfile ${RKEY_PLAIN} \
   -startdate ${R_START} -enddate ${R_END} \
   -notext \
   -in ${D}/rootCA/certs/root.csr.pem \
   -out ${D}/rootCA/certs/root.cert.pem \
   -batch

  rm -f ${D}/rootCA/certs/root.csr.pem

  chmod 444 ${D}/rootCA/certs/root.cert.pem

 ## openssl verify root CA certificate
 # openssl x509 -noout -text -in ${D}/rootCA/certs/root.cert.pem
}

##
## Step 4: Generate the intermediate CA key pair and certificate
##

# (Choose one) create an encrypted and plain RSA key pair for the intermediate CA
function generate_encrypted_plain_intermediate_keypair()
{
  IKEY_ENC=${D}/intermediateCA/private/intermediate-enc.key.pem
  IKEY_PLAIN=${D}/intermediateCA/private/intermediate.key.pem

  IPASS="pass:$(openssl rand -base64 32 | base64 -d | base64 -w 0)"
  echo $IPASS > ${D}/intermediateCA/passw/key

  openssl genrsa -aes256 -out ${IKEY_ENC} -passout ${IPASS} 4096
  openssl rsa -in ${IKEY_ENC} -out ${IKEY_PLAIN} --passin ${IPASS}

  KEYPASS=
}

# (Choose one) create a plain RSA key pair for the intermediate CA
function generate_plain_intermediate_keypair()
{
  IKEY_PLAIN=${D}/intermediateCA/private/intermediate.key.pem

  openssl genrsa -out ${IKEY_PLAIN} 4096
}

# Create an RSA key pair for the intermediate CA
function generate_intermediate_ca_keypair()
{
  generate_encrypted_plain_intermediate_keypair
  # generate_plain_intermediate_keypair

  chmod 400 ${IKEY_PLAIN}
}

# Create the intermediate CA certificate signing request (CSR)
function create_intermediate_ca_csr()
{
  openssl req \
   -config ${I} \
   -key ${D}/intermediateCA/private/intermediate.key.pem \
   -new \
   -sha256 \
   -subj "/C=${SC}/ST=${SST}/L=${SL}/O=${SO}/OU=${SOU}/CN=${SICN}/emailAddress=${SEA}" \
   -out ${D}/intermediateCA/certs/intermediate.csr.pem
}

# Sign the intermediate CSR with the root CA key
## For period of validity, use one of:
## -startdate and -enddate: format 'YYMMDDHHMMSSZ'
## -days: <number>
function sign_intermediate_csr_with_root_ca_key()
{
  openssl ca \
   -config ${R} \
   -keyfile ${D}/rootCA/private/root.key.pem \
   -extensions v3_intermediate_ca \
   -startdate ${I_START} -enddate ${I_END} \
   -notext \
   -md sha256 \
   -in ${D}/intermediateCA/certs/intermediate.csr.pem \
   -out ${D}/intermediateCA/certs/intermediate.cert.pem \
   -batch

  rm -f ${D}/intermediateCA/certs/intermediate.csr.pem

  chmod 444 ${D}/intermediateCA/certs/intermediate.cert.pem

  ## Verify the Intermediate CA Certificate content
  # openssl x509 -noout -text -in ${D}/intermediateCA/certs/intermediate.cert.pem
}

# verify intermediate certificate against the root certificate
function verify_certificate_chain()
{
  openssl verify -CAfile ${D}/rootCA/certs/root.cert.pem ${D}/intermediateCA/certs/intermediate.cert.pem
}

##
## Step 5: Generate OpenSSL Create Certificate Chain (Certificate Bundle)
##

# create certificate chain (certificate bundle)
function create_certificate_chain_bundle()
{
  cat ${D}/intermediateCA/certs/intermediate.cert.pem ${D}/rootCA/certs/root.cert.pem > ${D}/intermediateCA/certs/ca-chain.cert.pem

  echo "${D}/intermediateCA/certs/ca-chain.cert.pem created sucessfully"
}


#--------------------------------------------

function main()
{

rm -fr ${D}

startup

mount_openssl_root_cnf; mount_openssl_intermediate_cnf

generate_root_ca_keypair
#create_root_ca_dated_certificate
create_root_ca_timed_certificate

generate_intermediate_ca_keypair; create_intermediate_ca_csr; sign_intermediate_csr_with_root_ca_key

verify_certificate_chain
create_certificate_chain_bundle
}

main