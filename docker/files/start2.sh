#!/bin/bash -e

scripts_dir='/opt/nifi/scripts'

# FQDN=$HOSTNAME.$NIFI_SERVICE_NAME
FQDN=$(hostname -f)

echo "Running start2.sh... $FQDN"

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

cat "${NIFI_HOME}/conf/nifi.temp" > "${NIFI_HOME}/conf/nifi.properties"
cat "${NIFI_HOME}/conf/logback.temp" > "${NIFI_HOME}/conf/logback.xml"
cat "${NIFI_HOME}/conf/login-identity-providers.temp" > "${NIFI_HOME}/conf/login-identity-providers.xml"
cat "${NIFI_HOME}/conf/state-management.temp" > "${NIFI_HOME}/conf/state-management.xml"

if output=$(grep $(hostname) conf/authorizers.temp); then
  cat "${NIFI_HOME}/conf/authorizers.temp" > "${NIFI_HOME}/conf/authorizers.xml"
else
  cat "${NIFI_HOME}/conf/authorizers.empty" > "${NIFI_HOME}/conf/authorizers.xml"
fi

prop_replace 'nifi.sensitive.props.key'               "${NIFI_SECRET_KEY:-'xxx'}"

export NIFI_CLUSTER_ADDRESS=$FQDN
export NIFI_WEB_HTTP_HOST=$FQDN
export NIFI_WEB_HTTPS_HOST=$FQDN
export NIFI_REMOTE_INPUT_HOST=$FQDN

echo "Cluster address: $NIFI_CLUSTER_ADDRESS"

KEYSTORE_FOLDER=${NIFI_BASE_DIR}/nifi-certs/
mkdir -p $KEYSTORE_FOLDER

export KEYSTORE_PATH=${KEYSTORE_FOLDER}/keystore.jks
export TRUSTSTORE_PATH=${KEYSTORE_FOLDER}/truststore.jks

cp ${NIFI_BASE_DIR}/data/cert/*.jks $KEYSTORE_FOLDER

keytool -storepasswd -new $KEYSTORE_PASSWORD -keystore $KEYSTORE_PATH
keytool -storepasswd -new $TRUSTSTORE_PASSWORD -keystore $TRUSTSTORE_PATH


exec ${scripts_dir}/start.sh


