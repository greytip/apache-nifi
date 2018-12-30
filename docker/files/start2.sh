#!/bin/sh -e

scripts_dir='/opt/nifi/scripts'

echo "Running start2.sh..."

[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

cat "${NIFI_HOME}/conf/nifi.temp" > "${NIFI_HOME}/conf/nifi.properties"

if [[$(grep $(hostname) conf / authorizers.temp)]]; then
  cat "${NIFI_HOME}/conf/authorizers.temp" > "${NIFI_HOME}/conf/authorizers.xml"
else
  cat "${NIFI_HOME}/conf/authorizers.empty" > "${NIFI_HOME}/conf/authorizers.xml"
fi

{{- if .Values.ca.enabled }}
prop_replace nifi.web.https.host "${NIFI_WEB_HTTP_HOST:-$HOSTNAME}"

prop_replace nifi.security.keystore ${NIFI_BASE_DIR}/data/cert/keystore.jks
prop_replace nifi.security.keystorePasswd $(jq -r .keyStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)
prop_replace nifi.security.keyPasswd $(jq -r .keyPassword ${NIFI_BASE_DIR}/data/cert/config.json)

prop_replace nifi.security.truststore ${NIFI_BASE_DIR}/data/cert/truststore.jks
prop_replace nifi.security.truststorePasswd $(jq -r .trustStorePassword ${NIFI_BASE_DIR}/data/cert/config.json)
{{- else }}
{{- end }}

exec ${scripts_dir}/start.sh
