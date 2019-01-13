{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "apache-nifi.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "apache-nifi.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "apache-nifi.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Form the Zookeeper URL. If zookeeper is installed as part of this chart, use k8s service discovery,
else use user-provided URL
*/}}
{{- define "zookeeper.url" }}
{{- $port := .Values.zookeeper.port | toString }}
{{- if .Values.zookeeper.enabled -}}
{{- printf "%s-zookeeper:%s" .Release.Name $port }}
{{- else -}}
{{- printf "%s:%s" .Values.zookeeper.url $port }}
{{- end -}}
{{- end -}}

{{/*
NiFi environment variables
*/}}
{{- define "nifi-env" -}}
env:
- name: AUTH
  value: {{ .Values.properties.auth | quote }}
- name: INITIAL_ADMIN_IDENTITY
  value: "CN={{ .Values.ca.admin.cn }},OU=NIFI"
- name: NIFI_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ .Values.properties.secretsFile }}-secrets
      key: secret_key
- name: KEYSTORE_PASSWORD2
  valueFrom:
    secretKeyRef:
      name: {{ .Values.properties.secretsFile }}-secrets
      key: keystore_password
- name: TRUSTSTORE_PASSWORD2
  valueFrom:
    secretKeyRef:
      name: {{ .Values.properties.secretsFile }}-secrets
      key: truststore_password
- name: KEYSTORE_TYPE
  value: JKS
- name: TRUSTSTORE_TYPE
  value: JKS
- name: NIFI_ZK_CONNECT_STRING
  value: {{ template "zookeeper.url" . }}
- name: NIFI_SERVICE_NAME
  value: {{ template "apache-nifi.fullname" . }}-headless
- name: NIFI_CLUSTER_IS_NODE
  value: "{{.Values.properties.isNode}}"
- name: NIFI_CLUSTER_NODE_PROTOCOL_PORT
  value: "{{.Values.properties.clusterPort}}"
- name: NIFI_CLUSTER_NODE_PROTOCOL_THREADS
  value: "10"
- name: NIFI_CLUSTER_NODE_PROTOCOL_MAX_THREADS
  value: "50"
- name: NIFI_ELECTION_MAX_CANDIDATES
  value: "2"
- name: NIFI_PROVENANCE_STORAGE
  value: "{{ .Values.properties.provenanceStorage }}"
- name: NIFI_STS_SECURE
  value: "{{ .Values.properties.siteToSite.secure }}"
- name: NIFI_STS_INPUT_PORT
  value: "{{ .Values.properties.siteToSite.port }}"
- name: NIFI_WEB_PROXY_HOST
  value: "{{ .Values.properties.webProxyHost }}"
- name: NIFI_HTTPS_PORT
  value: "{{ .Values.properties.httpsPort }}"
- name: NIFI_HTTP_PORT
  value: "{{ .Values.properties.httpPort }}"
- name: LDAP_AUTHENTICATION_STRATEGY
  value: "{{ .Values.ldap.authStrategy }}"
- name: LDAP_USER_SEARCH_BASE
  value: "{{ .Values.ldap.searchBase }}"
- name: LDAP_USER_SEARCH_FILTER
  value: "{{ .Values.ldap.searchFilter }}"
- name: LDAP_IDENTITY_STRATEGY
  value: "{{ .Values.ldap.idStrategy }}"
- name: LDAP_URL
  value: "{{ .Values.ldap.url }}"
- name: LDAP_MANAGER_DN
  value: "{{ .Values.ldap.managerDn }}"
- name: LDAP_MANAGER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.properties.secretsFile }}-secrets
      key: ldap_password
- name: OIDC_DISCOVERY_URL
  value: "{{ .Values.oidc.discoveryUrl }}"
- name: OIDC_CONNECT_TIMEOUT
  value: "{{ .Values.oidc.connectTimeout }}"
- name: OIDC_READ_TIMEOUT
  value: "{{ .Values.oidc.readTimeout }}"
- name: OIDC_CLIENT_ID
  value: "{{ .Values.oidc.clientId }}"
- name: OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ .Values.properties.secretsFile }}-secrets
      key: oidc_client_secret
{{- end -}}

{{/*
NiFi volume mounts
*/}}
{{- define "volume-mounts" -}}
volumeMounts:
- name: "data"
  mountPath: /opt/nifi/data
- name: "flowfile-repository"
  mountPath: /opt/nifi/flowfile_repository
- name: "content-repository"
  mountPath: /opt/nifi/content_repository
- name: "provenance-repository"
  mountPath: /opt/nifi/provenance_repository
- name: "logs"
  mountPath: /opt/nifi/nifi-current/logs
- name: "bootstrap-conf"
  mountPath: /opt/nifi/nifi-current/conf/bootstrap.conf
  subPath: "bootstrap.conf"
- name: "nifi-properties"
  mountPath: /opt/nifi/nifi-current/conf/nifi.temp
  subPath: "nifi.temp"
- name: "authorizers-temp"
  mountPath: /opt/nifi/nifi-current/conf/authorizers.temp
  subPath: "authorizers.temp"
- name: "authorizers-empty"
  mountPath: /opt/nifi/nifi-current/conf/authorizers.empty
  subPath: "authorizers.empty"
- name: "bootstrap-notification-services-xml"
  mountPath: /opt/nifi/nifi-current/conf/bootstrap-notification-services.xml
  subPath: "bootstrap-notification-services.xml"
- name: "logback-xml"
  mountPath: /opt/nifi/nifi-current/conf/logback.temp
  subPath: "logback.temp"
- name: "zookeeper-properties"
  mountPath: /opt/nifi/nifi-current/conf/zookeeper.properties
  subPath: "zookeeper.properties"
{{- end -}}

{{/*
NiFi volumes
*/}}
{{- define "nifi-volumes" -}}
volumes:
- name: "bootstrap-conf"
  configMap:
    name: {{ template "apache-nifi.fullname" . }}-config
    items:
      - key: "bootstrap.conf"
        path: "bootstrap.conf"
- name: "nifi-properties"
  configMap:
    name: {{ template "apache-nifi.fullname" . }}-config
    items:
      - key: "nifi.properties"
        path: "nifi.temp"
- name: "authorizers-temp"
  configMap:
    name: {{ template "apache-nifi.fullname" . }}-config
    items:
      - key: "authorizers.xml"
        path: "authorizers.temp"
- name: "authorizers-empty"
  configMap:
    name: {{ template "apache-nifi.fullname" . }}-config
    items:
      - key: "authorizers-empty.xml"
        path: "authorizers.empty"
- name: "bootstrap-notification-services-xml"
  configMap:
    name: {{ template "apache-nifi.fullname" . }}-config
    items:
      - key: "bootstrap-notification-services.xml"
        path: "bootstrap-notification-services.xml"
- name: "logback-xml"
  configMap:
    name: {{ template "apache-nifi.fullname" . }}-config
    items:
      - key: "logback.xml"
        path: "logback.temp"
- name: "zookeeper-properties"
  configMap:
    name: {{ template "apache-nifi.fullname" . }}-config
    items:
      - key: "zookeeper.properties"
        path: "zookeeper.properties"
- name: ca-mitm-token
  secret:
    secretName: {{ template "apache-nifi.fullname" . }}-ca-mitm-token
{{- end -}}

{{/*
NiFi PVC Templates
*/}}
{{- define "nifi-pvc-templates" -}}
volumeClaimTemplates:
- metadata:
    name: "data"
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: {{ .Values.storageClass | quote }}
    resources:
      requests:
        storage: {{ .Values.dataStorage }}
- metadata:
    name: "flowfile-repository"
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: {{ .Values.storageClass | quote }}
    resources:
      requests:
        storage: {{ .Values.flowfileRepoStorage }}
- metadata:
    name: "content-repository"
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: {{ .Values.storageClass | quote }}
    resources:
      requests:
        storage: {{ .Values.contentRepoStorage }}
- metadata:
    name: "provenance-repository"
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: {{ .Values.storageClass | quote }}
    resources:
      requests:
        storage: {{ .Values.provenanceRepoStorage }}
- metadata:
    name: "logs"
  spec:
    accessModes: ["ReadWriteOnce"]
    storageClassName: {{ .Values.storageClass | quote }}
    resources:
      requests:
        storage: {{ .Values.logStorage }}
{{- end -}}
