{{/*
Define the pulsar zookeeper
*/}}
{{- define "pulsar.zookeeper.service" -}}
{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}
{{- end }}

{{/*
Define the pulsar zookeeper
*/}}
{{- define "pulsar.zookeeper.connect" -}}
{{$zk:=.Values.pulsar_metadata.userProvidedZookeepers}}
{{- if and (not .Values.components.zookeeper) $zk }}
{{- $zk -}}
{{ else }}
{{- if not (and .Values.tls.enabled .Values.tls.zookeeper.enabled) -}}
{{ template "pulsar.zookeeper.service" . }}:{{ .Values.zookeeper.ports.client }}
{{- end -}}
{{- if and .Values.tls.enabled .Values.tls.zookeeper.enabled -}}
{{ template "pulsar.zookeeper.service" . }}:{{ .Values.zookeeper.ports.clientTls }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Define the zookeeper hostname
*/}}
{{- define "pulsar.zookeeper.hostname" -}}
${HOSTNAME}.{{ template "pulsar.zookeeper.service" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Define zookeeper tls settings
*/}}
{{- define "pulsar.zookeeper.tls.settings" -}}
{{- if and .Values.tls.enabled .Values.tls.zookeeper.enabled }}
/pulsar/keytool/keytool.sh zookeeper {{ template "pulsar.zookeeper.hostname" . }} false;
{{- end }}
{{- end }}

{{/*
Define zookeeper certs mounts
*/}}
{{- define "pulsar.zookeeper.certs.volumeMounts" -}}
{{- if and .Values.tls.enabled .Values.tls.zookeeper.enabled }}
- name: keytool
  mountPath: "/pulsar/keytool/keytool.sh"
  subPath: keytool.sh
{{- end }}
{{- end }}


{{/*
Define zookeeper certs volumes
*/}}
{{- define "pulsar.zookeeper.certs.volumes" -}}
{{- if and .Values.tls.enabled .Values.tls.zookeeper.enabled }}
- name: keytool
  configMap:
    name: "{{ template "pulsar.fullname" . }}-keytool-configmap"
    defaultMode: 0755
{{- end}}
{{- end }}


{{/*
Define zookeeper log mounts
*/}}
{{- define "pulsar.zookeeper.log.volumeMounts" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-log4j2"
  mountPath: "{{ template "pulsar.home" . }}/conf/log4j2.yaml"
  subPath: log4j2.yaml
{{- end }}


{{/*
Define zookeeper log volumes
*/}}
{{- define "pulsar.zookeeper.log.volumes" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-log4j2"
  configMap:
    name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}"
{{- end }}

{{/*
Define zookeeper data mounts
*/}}
{{- define "pulsar.zookeeper.data.volumeMounts" -}}
{{- if .Values.zookeeper.volumes.useSeparateDiskForTxlog }}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.data.name }}"
  mountPath: "/pulsar/data/zookeeper"
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.dataLog.name }}"
  mountPath: "/pulsar/data/zookeeper-datalog"
{{- else }}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.data.name }}"
  mountPath: "/pulsar/data"
{{- end }}
{{- end }}

{{/*
Define zookeeper data volumes
*/}}
{{- define "pulsar.zookeeper.data.volumes" -}}
{{- if not (and .Values.global.localPersistence.enabled .Values.zookeeper.volumes.persistence) }}
{{- if ne (.Values.zookeeper.replicaCount | int) 1 }}
{{- fail "Zookeeper replica count should be 1 when not using local persistence" }}
{{- end }}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.data.name }}"
  {{- include "helm-lib.pvcStorage" (dict "claim" "dataVolumeClaim" "Release" .Release "Template" .Template "Values" .Values ) | nindent 2 }}
{{- if .Values.zookeeper.volumes.useSeparateDiskForTxlog }}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.dataLog.name }}"
  emptyDir: {}
{{- end }}
{{- end }}
{{- end }}

{{/*
Define zookeeper data volume claim templates
*/}}
{{- define "pulsar.zookeeper.data.volumeClaimTemplates" -}}
{{- if and .Values.global.localPersistence.enabled .Values.zookeeper.volumes.persistence -}}
- metadata:
    name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.data.name }}"
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: {{ .Values.zookeeper.volumes.data.size }}
  {{- if and .Values.global.localPersistence.enabled (include "zookeeper.data_local_storage" . ) }}
    storageClassName: {{ .Values.zookeeper.volumes.data.storageClassName | default "fast-disks" }}
  {{- else }}
    {{- if  .Values.zookeeper.volumes.data.storageClass }}
    storageClassName: {{ .Values.zookeeper.volumes.data.storageClassName | default "fast-disks" }}
    {{- else if .Values.zookeeper.volumes.data.storageClassName }}
    storageClassName: {{ .Values.zookeeper.volumes.data.storageClassName | default "fast-disks" }}
    {{- end -}}
  {{- end }}
{{- if .Values.zookeeper.volumes.useSeparateDiskForTxlog -}}
- metadata:
    name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.dataLog.name }}"
  spec:
    accessModes: [ "ReadWriteOnce" ]
    resources:
      requests:
        storage: {{ .Values.zookeeper.volumes.dataLog.size }}
  {{- if and .Values.global.localPersistence.enabled (include "zookeeper.data_local_storage" . ) }}
    storageClassName: {{ .Values.zookeeper.volumes.data.storageClassName | default "fast-disks" }}
  {{- else }}
    {{- if  .Values.zookeeper.volumes.dataLog.storageClass }}
    storageClassName: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-{{ .Values.zookeeper.volumes.dataLog.name }}"
    {{- else if .Values.zookeeper.volumes.dataLog.storageClassName }}
    storageClassName: {{ .Values.zookeeper.volumes.dataLog.storageClassName }}
    {{- end -}}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Define zookeeper gen-zk-conf volume mounts
*/}}
{{- define "pulsar.zookeeper.genzkconf.volumeMounts" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-genzkconf"
  mountPath: "{{ template "pulsar.home" . }}/bin/gen-zk-conf.sh"
  subPath: gen-zk-conf.sh
{{- end }}

{{/*
Define zookeeper gen-zk-conf volumes
*/}}
{{- define "pulsar.zookeeper.genzkconf.volumes" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}-genzkconf"
  configMap:
    name: "{{ template "pulsar.fullname" . }}-genzkconf-configmap"
    defaultMode: 0755
{{- end }}

{{/*
Define zookeeper zkprobe Commands
*/}}
{{- define "pulsar.zookeeper.zkprobe.command" -}}
exec:
  command:
  - /bin/bash
  - -c
  - |
    #!/bin/bash
    exec 2>/tmp/probe.out
    set -x
{{- if (and .global.Values.tls.enabled .global.Values.tls.zookeeper.enabled) }}
    (echo ruok;sleep 1)|openssl s_client -CAfile /pulsar/ssl/vault/ca.crt -cert /pulsar/ssl/vault/server.crt -key /pulsar/ssl/vault/server.key {{ .host }}:{{ .global.Values.zookeeper.ports.clientTls }} 2>/dev/null |grep imok
{{- else }}
    (echo ruok) | nc {{ .host }} {{ .global.Values.zookeeper.ports.client }} |grep imok
{{- end }}
    if [[ $? -eq 0 ]]
    then
      echo WORKS
      exit 0
    else
      echo FAILED
      exit 1
    fi
{{- end }}
