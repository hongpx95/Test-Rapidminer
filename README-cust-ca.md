# Customer Internal CA

- [Customer Internal CA](#customer-internal-ca)
  - [Into](#into)
    - [Prerequisites](#prerequisites)
    - [Install on Debian/Ubuntu](#install-on-debianubuntu)
    - [Install on Fedora/Centos/RedHat](#install-on-fedoracentosredhat)
    - [Install on OpenSuse/SLES](#install-on-opensusesles)
    - [Install on Alpine](#install-on-alpine)
  - [Create the PKI infrastructure](#create-the-pki-infrastructure)
    - [Creating directory to start the process](#creating-directory-to-start-the-process)
    - [Customize the _vars_ file](#customize-the-vars-file)
    - [Create new CA](#create-new-ca)
    - [Create new Server certificate](#create-new-server-certificate)
    - [Sign server certificate with CA](#sign-server-certificate-with-ca)
    - [Copy the created certificates](#copy-the-created-certificates)
  - [Preparing the _.env_ and _docker-compose.yml_](#preparing-the-env-and-docker-composeyml)
    - [Changes in _docker-compose.yml_](#changes-in-docker-composeyml)
    - [Changes in _.env_ file](#changes-in-env-file)
  - [Starting the platform](#starting-the-platform)
  - [Steps after deployment or deployment errors](#steps-after-deployment-or-deployment-errors)
    - [Delete previously created subdirs](#delete-previously-created-subdirs)

## Into
This directory contains the internal certificate authority _(CA)_ related scripts help to create own (test) CA and certificates.
### Prerequisites
Right now we will use [_easyrsa3_](https://easy-rsa.readthedocs.io/) helper tool. This tool uses _openssl_, so it needs to be installed, if you use not use some Linux vendor packaged edition.

### Install on Debian/Ubuntu
```sh
sudo apt-get update
sudo apt-get install easy-rsa
```

### Install on Fedora/Centos/RedHat
```sh
sudo yum install epel-release
sudo yum makecache
sudo yum install easy-rsa
```

### Install on OpenSuse/SLES
```sh
sudo zypper refresh
sudo zypper install easy-rsa
```

### Install on Alpine
```sh
apk update
apk search easy-rsa
```

## Create the PKI infrastructure
To create custom Public Key Infrastructure ([PKI](https://easy-rsa.readthedocs.io/en/latest/intro-to-PKI/)), we should create a new CA, and create server certificates, and sign with the created CA

### Creating directory to start the process
The first step is creating the PKI infrastructure.

**Warning!** All steps needs to start inside of freshly created directory.
```sh
make-cadir ca-dir
cd ca-dir
./easyrsa init-pki
```

### Customize the _vars_ file
We should change these parameters:
```sh
...
set_var EASYRSA_DN    "org"
...
set_var EASYRSA_REQ_COUNTRY   "US"
set_var EASYRSA_REQ_PROVINCE  "California"
set_var EASYRSA_REQ_CITY      "Los Angeles"
set_var EASYRSA_REQ_ORG       "Example Startup Company"
set_var EASYRSA_REQ_EMAIL     "it@examplestartup.com"
set_var EASYRSA_REQ_OU        "IT Sec group"
...
set_var EASYRSA_CA_EXPIRE     3650
...
set_var EASYRSA_CERT_EXPIRE   1080
...
set_var EASYRSA_NS_SUPPORT    "yes"
...
set_var EASYRSA_NS_COMMENT    ""
...
```
### Create new CA
If the _vars_ file changed well, the only important question is about _Common Name_ (**CN**) of the CA. 
```sh
./easyrsa build-ca nopass
```
### Create new Server certificate
Here the script also asks about _CN_, please be careful with this.
Using wildcard (for ex.: _*.examplestartup.com_) here is also allowed.
```sh
CN='foobar.examplestartup.com'
SAN="DNS:*.examplestartup.com"
./easyrsa --batch --subject-alt-name="${SAN}" --req-cn="${CN}" gen-req "${CN}" nopass
```
### Sign server certificate with CA
```sh
./easyrsa sign-req server foobar.example.com
```

### Copy the created certificates
We should create a directory called _ssl_  next to _platform-docker-compose.yaml_:
```sh
cd ..
mkdir -p ssl
cp ca-dir/pki/private/foobar.example.com.key ssl/private.key
cp ca-dir/pki/issued/foobar.example.com.crt ssl/certificate.crt
cat ca-dir/pki/ca.crt >> ssl/certificate.crt
chmod a+w ssl
chmod a+r ssl/*
```

## Preparing the _.env_ and _docker-compose.yml_
If we want to use the certificates in SSL, we need some change in _.env_ and in _docker-compose.yml_ as well.
### Changes in _docker-compose.yml_

We can use the _prepare-cust-ca.sh_ shell script, which can extend the _docker-compose.yml_ file with the needed options.
It will change some part of the _.env_ file as well.

### Changes in _.env_ file
We should edit the file, and change lines like this, if it needs:
```sh
...
# Public domain of the deployment
PUBLIC_DOMAIN=platform.examplestartup.com

# Public URL of the deployment that will be used for external access (Public domain + protocol + port)
PUBLIC_URL=https://platform.examplestartup.com

# Public URL of the SSO endpoint that will be used for external access. In most cases it should be the same as the PUBLIC_URL
SSO_PUBLIC_URL=https://platform.examplestartup.com
...
JHUB_CUSTOM_CA_CERTS=/full/path/to/platform/ssl/deb_cacerts/
```

**Warning!** _JHUB_CUSTOM_CA_CERTS_ must contains the full path of your platform directory, plus _ssl/deb_cacerts/_ subdirectory.
 
## Starting the platform
The starting process is the same as documented in the [official documentation](https://docs.rapidminer.com/latest/deployment/docker-compose/).

## Steps after deployment or deployment errors

### Delete previously created subdirs
If we want to restart the certificate transformation part of RapidMiner Initialization service, we should remove the created subdirs:
```sh
sudo rm -fr ssl/deb_cacerts/
sudo rm -fr ssl/java_cacerts/
sudo rm -fr ssl/rh_cacerts/
```
 
