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

#export KEYSTORE_PATH=${KEYSTORE_FOLDER}/keystore.jks
#export TRUSTSTORE_PATH=${KEYSTORE_FOLDER}/truststore.jks


old_keystore_pass=$(jq -r .keyStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)
old_truststore_pass=$(jq -r .trustStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)

export KEYSTORE_PASSWORD=$(jq -r .keyStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)
export TRUSTSTORE_PASSWORD=$(jq -r .trustStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)

#export KEYSTORE_PASSWORD=$KEYSTORE_PASSWORD2
#export TRUSTSTORE_PASSWORD=$TRUSTSTORE_PASSWORD2

export KEYSTORE_PATH=${NIFI_BASE_DIR}/data/cert/keystore.jks
export KEYSTORE_TYPE='JKS'
export TRUSTSTORE_PATH=${NIFI_BASE_DIR}/data/cert/truststore.jks
export TRUSTSTORE_TYPE='JKS'

# echo "Changing password for stores... $KEYSTORE_PASSWORD -- $KEYSTORE_PASSWORD2"

KEYSTORE_FOLDER=${NIFI_BASE_DIR}/nifi-certs/
if [ ! -e ${NIFI_BASE_DIR}/nifi-certs ]; then
  mkdir -p ${KEYSTORE_FOLDER}
  cp ${NIFI_BASE_DIR}/data/cert/*.jks $KEYSTORE_FOLDER

  keytool -storepasswd -new $KEYSTORE_PASSWORD2 -keystore $KEYSTORE_FOLDER/keystore.jks -storepass $old_keystore_pass
  keytool -storepasswd -new $TRUSTSTORE_PASSWORD2 -keystore $KEYSTORE_FOLDER/truststore.jks -storepass $old_truststore_pass
else
  echo 'Password already updated. Skipping.'
fi

# echo "Done changing passwords"

exec ${scripts_dir}/start.sh

