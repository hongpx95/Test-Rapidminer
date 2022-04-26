#!/bin/bash

# https://mikefarah.gitbook.io/yq/commands/write-update

YQ_MAIN_VERSION="$(yq --version|sed -e 's/^.\+version \([0-9]\)\..*/\1/')"

function yq_read() {
    eval "yq_${YQ_MAIN_VERSION}_read $*"
}
function yq_write() {
    eval "yq_${YQ_MAIN_VERSION}_write $*"
}
function yq_add_map() {
  eval "yq_${YQ_MAIN_VERSION}_add_map $*"
}

function yq_4_read() {
    YML_FILE=$1
    ITEM=$2
    #yq eval '.services.rm-proxy-svc.environment' docker-compose.yml
    yq e ".$ITEM" "$YML_FILE"
}
function yq_4_write() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq eval '.services.rm-proxy-svc.environment' docker-compose.yml
    #yq e '.a.b += ["cow"]' 
    yq -i e ".$ITEM += [\"$VALUE\"]" "$YML_FILE"
}
function yq_4_add_map() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq -i e ".services.rm-init-svc.user = \"root\""
    yq -i e ".$ITEM = \"$VALUE\"" "$YML_FILE"
}

function yq_3_read() {
    YML_FILE=$1
    ITEM=$2
    #yq r "$PLATFORM_YML" services.rm-init-svc.environment
    yq r "$YML_FILE" "$ITEM"
}
function yq_3_write() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq w -i "$PLATFORM_YML" "services.rm-init-svc.environment[+]" "HTTPS_CRT_PATH=\${HTTPS_CRT_PATH}"
    yq w -i "$YML_FILE" "$ITEM[+]" "$VALUE"
}
function yq_3_add_map() {
    YML_FILE=$1
    ITEM=$2
    VALUE=$3
    #yq w -i docker-compose.yml "services.rm-init-svc.user" "root"
    yq w -i "$YML_FILE" "$ITEM" "$VALUE"
}

PLATFORM_YML="docker-compose.yml"
ENV_FILE=".env"

PLATFORM_ORIG="docker-compose_orig.yml"
ENV_ORIG=".env_orig"

if [ -f "$PLATFORM_ORIG" ];then
    echo "Backup file $PLATFORM_ORIG already created"
else
    cp "$PLATFORM_YML" "$PLATFORM_ORIG"
fi
if [ -f "$ENV_ORIG" ];then
    echo "Backup file $ENV_ORIG already created"
else
    cp "$ENV_FILE" "$ENV_ORIG"
fi


if ! (yq_read "$PLATFORM_YML" "services.rm-init-svc.environment"|grep -v "^#"|grep -q HTTPS_CRT_PATH);then
    yq_write "$PLATFORM_YML" "services.rm-init-svc.environment" 'HTTPS_CRT_PATH=\${HTTPS_CRT_PATH}'
fi
if ! (yq_read "$PLATFORM_YML" "services.rm-init-svc"|grep -v "^#"|grep -q root);then
    yq_add_map "$PLATFORM_YML" "services.rm-init-svc.user" "root"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-init-svc.volumes|grep -v "^#"|grep -q '\/tmp\/ssl');then
    yq_write "$PLATFORM_YML" "services.rm-init-svc.volumes" "./ssl:/tmp/ssl"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-server-job-agent-svc.environment|grep -v "^#"|grep -q 'JAVA_KEYSTORE_PATH');then
    yq_write "$PLATFORM_YML" "services.rm-server-job-agent-svc.environment" "JAVA_KEYSTORE_PATH=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-server-job-agent-svc.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.rm-server-job-agent-svc.volumes" ./ssl/java_cacerts/cacerts:/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts
fi
if ! (yq_read "$PLATFORM_YML" services.rm-server-svc.environment|grep -v "^#"|grep -q 'JAVA_KEYSTORE_PATH');then
    yq_write "$PLATFORM_YML" "services.rm-server-svc.environment" "JAVA_KEYSTORE_PATH=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-server-svc.environment|grep -v "^#"|grep -q 'PROXY_HTTPS_PORT');then
    yq_write "$PLATFORM_YML" "services.rm-server-svc.environment" "PROXY_HTTPS_PORT=443"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-server-svc.volumes|grep -v "^#"|grep -q '\/java_cacerts');then
    yq_write "$PLATFORM_YML" "services.rm-server-svc.volumes" "./ssl/java_cacerts/cacerts:/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-radoop-proxy-svc|grep -v "^#"|grep -q 'volumes');then
    yq_write "$PLATFORM_YML" "services.rm-radoop-proxy-svc.volumes" null
fi
if ! (yq_read "$PLATFORM_YML" services.rm-radoop-proxy-svc.volumes|grep -v "^#"|grep -q '\/ca-bunde');then
    yq_write "$PLATFORM_YML" "services.rm-radoop-proxy-svc.volumes" "./ssl/rh_cacerts/ca-bundle.trust.crt:/etc/pki/ca-trust/extracted/openssl/ca-bundle.trust.crt"
    yq_write "$PLATFORM_YML" "services.rm-radoop-proxy-svc.volumes" "./ssl/rh_cacerts/ca-bundle.crt:/etc/pki/tls/certs/ca-bundle.crt"
fi
if ! (yq_read "$PLATFORM_YML" services.platform-admin-webui-svc.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.platform-admin-webui-svc.volumes" "./ssl/deb_cacerts/:/etc/ssl/certs/"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-jupyterhub-svc.environment|grep -v "^#"|grep -q 'REQUESTS_CA_BUNDLE');then
    yq_write "$PLATFORM_YML" "services.rm-jupyterhub-svc.environment" "REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-jupyterhub-svc.environment|grep -v "^#"|grep -q 'JHUB_CUSTOM_CA_CERTS');then
    yq_write "$PLATFORM_YML" "services.rm-jupyterhub-svc.environment" 'JHUB_CUSTOM_CA_CERTS=\${JHUB_CUSTOM_CA_CERTS}'
fi
if ! (yq_read "$PLATFORM_YML" services.rm-jupyterhub-svc.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.rm-jupyterhub-svc.volumes" "./ssl/deb_cacerts/:/etc/ssl/certs/"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-grafana-svc.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.rm-grafana-svc.volumes" "./ssl/deb_cacerts/:/etc/ssl/certs/"
fi
if ! (yq_read "$PLATFORM_YML" services.landing-page.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.landing-page.volumes" "./ssl/deb_cacerts/:/etc/ssl/certs/"
fi
if ! (yq_read "$PLATFORM_YML" services.rm-token-tool-svc.volumes|grep -v "^#"|grep -q '\.\/ssl\/deb_cacerts');then
    yq_write "$PLATFORM_YML" "services.rm-token-tool-svc.volumes" "./ssl/deb_cacerts/:/etc/ssl/certs/"
fi
if ( $1 == "extraKC");then
    if ! (yq_read "$PLATFORM_YML" services.rm-keycloak-svc.volumes|grep -v "^#"|grep -q '\.\/ssl\/rh_cacerts\/ca-bundle.crt');then
        yq_write "$PLATFORM_YML" "services.rm-keycloak-svc.volumes" "./ssl/rh_cacerts/ca-bundle.crt:/etc/pki/java/cacerts"
    fi
fi
if grep -q "^PUBLIC_URL=http:" "$ENV_FILE";then
    sed -i 's/^PUBLIC_URL=http:/PUBLIC_URL=https:/' "$ENV_FILE"
fi
if grep -q "^SSO_PUBLIC_URL=http:" "$ENV_FILE";then
    sed -i 's/^SSO_PUBLIC_URL=http:/SSO_PUBLIC_URL=https:/' "$ENV_FILE"
fi
if grep -q "^\#\?JHUB_CUSTOM_CA_CERTS" "$ENV_FILE";then
    sed -i "s,^\#\?JHUB_CUSTOM_CA_CERTS.*$,JHUB_CUSTOM_CA_CERTS=$PWD/ssl/deb_cacerts/," "$ENV_FILE"
fi

echo "Fixing permissions on files"
chmod -v a+w .env
if [ -d 'ssl/' ];then
    chmod -v a+w ssl/
fi
if [ -d 'ssl/certificate.crt' ];then
    chmod -v a+r ssl/certificate.crt
fi
if [ -d 'ssl/private.key' ];then
    chmod -v a+r ssl/private.key
fi
