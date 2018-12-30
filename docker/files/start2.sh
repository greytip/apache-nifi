#!/bin/bash -e

scripts_dir='/opt/nifi/scripts'

echo "Running start2.sh..."

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

cat "${NIFI_HOME}/conf/nifi.temp" > "${NIFI_HOME}/conf/nifi.properties"

if [[$(grep $(hostname) conf/authorizers.temp)]]; then
  cat "${NIFI_HOME}/conf/authorizers.temp" > "${NIFI_HOME}/conf/authorizers.xml"
else
  cat "${NIFI_HOME}/conf/authorizers.empty" > "${NIFI_HOME}/conf/authorizers.xml"
fi

#NIFI_WEB_HTTP_HOST=$HOSTNAME.$HEADLESS_SERVICE_NAME
# {{- if .Values.ca.enabled }}
export NIFI_CLUSTER_ADDRESS=$HOSTNAME.$NIFI_SERVICE_NAME
export NIFI_WEB_HTTP_HOST=$HOSTNAME.$NIFI_SERVICE_NAME
export NIFI_WEB_HTTPS_HOST=$HOSTNAME.$NIFI_SERVICE_NAME
export KEYSTORE_PATH=${NIFI_BASE_DIR}/data/cert/keystore.jks
export KEYSTORE_TYPE='JKS'
export KEYSTORE_PASSWORD=$(jq -r .keyStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)
export TRUSTSTORE_PATH=${NIFI_BASE_DIR}/data/cert/truststore.jks
export TRUSTSTORE_TYPE='JKS'
export TRUSTSTORE_PASSWORD=$(jq -r .trustStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)
# {{- end }}

echo "Cluster address: $NIFI_CLUSTER_ADDRESS"


exec ${scripts_dir}/start.sh