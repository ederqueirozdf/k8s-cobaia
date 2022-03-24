{{/*
Define the pulsar bookkeeper service
*/}}
{{- define "pulsar.bookkeeper.service" -}}
{{ template "pulsar.fullname" . }}-{{ .Values.bookkeeper.component }}
{{- end }}

{{/*
Define the bookkeeper hostname
*/}}
{{- define "pulsar.bookkeeper.hostname" -}}
${HOSTNAME}.{{ template "pulsar.bookkeeper.service" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}


{{/*
Define bookie zookeeper client tls settings
*/}}
{{- define "pulsar.bookkeeper.zookeeper.tls.settings" -}}
{{- if and .Values.tls.enabled .Values.tls.zookeeper.enabled }}
/pulsar/keytool/keytool.sh bookie {{ template "pulsar.bookkeeper.hostname" . }} true;
{{- end }}
{{- end }}

{{- define "pulsar.bookkeeper.journal.pvc.name" -}}
{{ template "pulsar.fullname" . }}-{{ .Values.bookkeeper.component }}-{{ .Values.bookkeeper.volumes.journal.name }}
{{- end }}

{{- define "pulsar.bookkeeper.ledgers.pvc.name" -}}
{{ template "pulsar.fullname" . }}-{{ .Values.bookkeeper.component }}-{{ .Values.bookkeeper.volumes.ledgers.name }}
{{- end }}

{{- define "pulsar.bookkeeper.journal.storage.class" -}}
{{- if and .Values.global.localPersistence.enabled (include "bookkeeper.journal_local_storage" . ) }}
  {{- print .Values.bookkeeper.volumes.journal.storageClassName -}}
{{- else }}
  {{- if  .Values.bookkeeper.volumes.journal.storageClass }}
    {{- print .Values.bookkeeper.volumes.ledgers.storageClassName }}
  {{- else if .Values.bookkeeper.volumes.journal.storageClassName }}
    {{- print .Values.bookkeeper.volumes.journal.storageClassName }}
  {{- end -}}
{{- end }}
{{- end }}

{{- define "pulsar.bookkeeper.ledgers.storage.class" -}}
{{- if and .Values.global.localPersistence.enabled (include  "bookkeeper.ledgers_local_storage" . ) }}
  {{- print .Values.bookkeeper.volumes.ledgers.storageClassName -}}
{{- else }}
  {{- if  .Values.bookkeeper.volumes.ledgers.storageClass }}
    {{- print .Values.bookkeeper.volumes.ledgers.storageClassName }}
  {{- else if .Values.bookkeeper.volumes.ledgers.storageClassName }}
    {{- print .Values.bookkeeper.volumes.ledgers.storageClassName }}
  {{- end -}}
{{- end }}
{{- end }}

{{/*
Define bookie tls certs mounts
*/}}
{{- define "pulsar.bookkeeper.certs.volumeMounts" -}}
{{- if and .Values.tls.enabled (or .Values.tls.bookie.enabled .Values.tls.zookeeper.enabled) }}
{{- if .Values.tls.zookeeper.enabled }}
- name: keytool
  mountPath: "/pulsar/keytool/keytool.sh"
  subPath: keytool.sh
{{- end }}
{{- end }}
{{- end }}

{{/*
Define bookie tls certs volumes
*/}}
{{- define "pulsar.bookkeeper.certs.volumes" -}}
{{- if and .Values.tls.enabled (or .Values.tls.bookie.enabled .Values.tls.zookeeper.enabled) }}
{{- if .Values.tls.zookeeper.enabled }}
- name: keytool
  configMap:
    name: "{{ template "pulsar.fullname" . }}-keytool-configmap"
    defaultMode: 0755
{{- end }}
{{- end }}
{{- end }}

{{/*
Define bookie common config
*/}}
{{- define "pulsar.bookkeeper.config.common" -}}
zkServers: "{{ template "pulsar.zookeeper.connect" . }}"
zkLedgersRootPath: "{{ .Values.metadataPrefix }}/ledgers"
# enable bookkeeper http server
httpServerEnabled: "true"
httpServerPort: "{{ .Values.bookkeeper.ports.http }}"
# config the stats provider
statsProviderClass: org.apache.bookkeeper.stats.prometheus.PrometheusMetricsProvider
# use hostname as the bookie id
useHostNameAsBookieID: "true"
{{- end }}

{{/*
Define bookie tls config
*/}}
{{- define "pulsar.bookkeeper.config.tls" -}}
{{- if and .Values.tls.enabled .Values.tls.bookie.enabled }}
PULSAR_PREFIX_tlsProvider: "OpenSSL"
PULSAR_PREFIX_tlsKeyStoreType: "PKCS12"
PULSAR_PREFIX_tlsKeyStore: "/pulsar/ssl/store/keystore.p12"
PULSAR_PREFIX_tlsTrustStore: "/pulsar/ssl/store/truststore.p12"
PULSAR_PREFIX_tlsKeyStorePasswordPath: /pulsar/ssl/store/bookie.keystore.passwd
PULSAR_PREFIX_tlsTrustStorePasswordPath: /pulsar/ssl/store/bookie.truststore.passwd
PULSAR_PREFIX_clientTrustStorePasswordPath: /pulsar/ssl/store/client.truststore.passwd
PULSAR_PREFIX_tlsClientAuthentication: "true"
PULSAR_PREFIX_tlsProviderFactoryClass: "org.apache.bookkeeper.tls.TLSContextFactory"
{{- end }}
{{- end }}

{{/*
Define bookie init container : verify cluster id
*/}}
{{- define "pulsar.bookkeeper.init.verify_cluster_id" -}}
{{- if not (and .Values.global.localPersistence.enabled .Values.bookkeeper.volumes.persistence) }}
bin/apply-config-from-env.py conf/bookkeeper.conf;
until bin/bookkeeper shell whatisinstanceid; do
  sleep 3;
done;
#the below code is added in the pulsar chart repo for the ephemeral storage disks .We should not be cleaning the storage in case we are using the nfs based disks (data vol) bin/bookkeeper shell bookieformat -nonInteractive -force -deleteCookie
{{- end }}
{{- if and .Values.global.localPersistence.enabled .Values.bookkeeper.volumes.persistence }}
set -e;
bin/apply-config-from-env.py conf/bookkeeper.conf;
until bin/bookkeeper shell whatisinstanceid; do
  sleep 3;
done;
{{- end }}
{{- end }}

{{/*
Define bookkeeper log mounts
*/}}
{{- define "pulsar.bookkeeper.log.volumeMounts" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.bookkeeper.component }}-log4j2"
  mountPath: "{{ template "pulsar.home" .}}/conf/log4j2.yaml"
  subPath: log4j2.yaml
{{- end }}

{{/*
Define bookkeeper log volumes
*/}}
{{- define "pulsar.bookkeeper.log.volumes" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.bookkeeper.component }}-log4j2"
  configMap:
    name: "{{ template "pulsar.fullname" . }}-{{ .Values.bookkeeper.component }}"
{{- end }}


{{/*
Define bookkeeper config data
*/}}
{{- define "bookkeeper.config_data" -}}
{{- if eq (include  "pulsar.is_cloud_deployment" . ) "false" -}}
{{ toYaml .Values.bookkeeper.configData | indent 2 }}
{{- else -}}
{{ toYaml .Values.bookkeeper.configData | indent 2 | replace "journalSyncData: \"false\"" "journalSyncData: \"true\"" }}
{{- end }}
{{- end }}
