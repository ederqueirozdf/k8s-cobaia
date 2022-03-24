{{/* vim: set filetype=mustache: */}}

{{/*
pulsar home
*/}}
{{- define "pulsar.home" -}}
{{- if or (eq .Values.global.docker.orgName "streamnative/platform") (eq .Values.global.docker.orgName "streamnative/platform-all") }}
{{- print "/sn-platform" -}}
{{- else }}
{{- print "/pulsar" -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "pulsar.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Expand to the namespace pulsar installs into.
*/}}
{{- define "pulsar.namespace" -}}
{{- default .Release.Namespace .Values.namespace -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "pulsar.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
set the current component variables
*/}}
{{- define "pulsar.setCurrentComponentFull" -}}
{{- $_ := set . "currentComponentFull" (printf "%s-%s" (include "pulsar.fullname" .) (.componentFullSuffix | default .currentComponent)) -}}
{{- $_ := unset . "componentFullSuffix" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "pulsar.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the common labels.
*/}}
{{- define "pulsar.standardLabels" -}}
app: {{ template "pulsar.name" . }}
chart: {{ template "pulsar.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
cluster: {{ template "pulsar.fullname" . }}
app.kubernetes.io/name: {{ .currentComponentFull }}
app.kubernetes.io/managed-by: {{.Release.Name}}
app.kubernetes.io/version: {{.Chart.Version}}
itom.microfocus.com/capability: itom-data-ingestion
tier.itom.microfocus.com/backend: backend
component: {{ .currentComponent }}
{{- end }}

{{/*
Create the common labels.
*/}}
{{- define "pulsar.pdbLabels" -}}
app: {{ template "pulsar.name" . }}
chart: {{ template "pulsar.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
cluster: {{ template "pulsar.fullname" . }}
app.kubernetes.io/name: {{ .currentComponentFull }}
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/version: {{.Chart.Version}}
itom.microfocus.com/capability: itom-data-ingestion
tier.itom.microfocus.com/backend: backend
component: {{ .currentComponent }}
{{- end }}

{{/*
Create the template annotations.
*/}}
{{- define "pulsar.template.annotations" -}}
deployment.microfocus.com/default-replica-count: "1"
deployment.microfocus.com/runlevel: UP
{{- end }}

{{/*
Create extra template annotations for itom-chart-reloader.
*/}}
{{- define "pulsar.template.reloaderannotations" -}}
{{- if .Values.global.apiClient.authorizedClientCAs }}
configmap.reloader.stakater.com/reload: "{{ .Values.global.apiClient.authorizedClientCAs }}"
{{- end }}
{{- end }}

{{/*
Create the match labels.
*/}}
{{- define "pulsar.matchLabels" -}}
app: {{ template "pulsar.name" . }}
release: {{ .Release.Name }}
component: {{ .currentComponent }}
{{- end }}

{{/*
Pulsar Cluster Name.
*/}}
{{- define "pulsar.cluster" -}}
{{- if .Values.pulsar_metadata.clusterName }}
{{- .Values.pulsar_metadata.clusterName }}
{{- else }}
{{- template "pulsar.fullname" . }}
{{- end }}
{{- end }}


{{/*
Define coso init volumes
*/}}
{{- define "pulsar.coso.init.volumes" -}}
- name: cosoinit
  configMap:
    name: "{{ template "pulsar.fullname" . }}-cosoinit-configmap"
    defaultMode: 0755
{{- end }}

{{/*
Define Micro Focus Init script mount
*/}}
{{- define "pulsar.coso.init.volumeMounts" -}}
- name: cosoinit
  mountPath: "/pulsar/bin/coso-init.sh"
  subPath: coso-init.sh
{{- end }}

{{/*
Define coso external cert volumes
*/}}
{{- define "pulsar.coso.externalcert.volumes" -}}
{{- if .Values.global.apiClient.authorizedClientCAs }}
- name: cosoexternalcert
  configMap:
    name: {{ .Values.global.apiClient.authorizedClientCAs }}
{{- else }}
- name: cosoexternalcert
  secret:
    secretName: itomdipulsar-client-ca-certs-secret
{{- end }}
{{- end }}

{{/*
Define coso external cert mount
*/}}
{{- define "pulsar.coso.externalcert.volumeMounts" -}}
- name: cosoexternalcert
  mountPath: "/pulsar/ssl/custom/ca"
{{- end }}


{{/*
Define Wait for zookeeper init container
*/}}
{{- define "pulsar.zookeeper.wait.init" -}}
- name: wait-zookeeper-ready
  image: {{ .Values.global.docker.registry }}/{{ .Values.global.docker.orgName }}/{{ .Values.pulsar.image }}:{{ .Values.pulsar.imageTag }}
  imagePullPolicy: {{ .Values.global.docker.imagePullPolicy }}
  command: ["sh", "-c"]
  args:
    - >-
      source bin/coso-init.sh;
{{- if and .Values.tls.enabled .Values.tls.zookeeper.enabled }}
      until bin/pulsar zookeeper-shell -server {{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}:{{ .Values.zookeeper.ports.clientTls }} ls /; do
{{- else }}
      until bin/pulsar zookeeper-shell -server {{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}:{{ .Values.zookeeper.ports.client }} ls /; do
{{- end }}
        sleep 3;
      done;
  volumeMounts:
  {{- include "pulsar.coso.init.volumeMounts" . | nindent 2 }}
  {{- include "pulsar.bastion.certs.volumeMounts" . | nindent 2 }}
  - name: tmp
    mountPath: /pulsar/tmp
  - name: conf
    mountPath: /pulsar/conf
  - name: logs
    mountPath: /pulsar/logs
  - name: ssl
    mountPath: /pulsar/ssl
  - name: vault-token
    mountPath: /var/run/secrets/boostport.com
{{- end }}

{{/*
Define Wait for zookeeper init container with node info
*/}}
{{- define "pulsar.zookeeper.wait.init.node" -}}
- name: wait-zookeeper-ready
  image: {{ .Values.global.docker.registry }}/{{ .Values.global.docker.orgName }}/{{ .Values.pulsar.image }}:{{ .Values.pulsar.imageTag }}
  imagePullPolicy: {{ .Values.global.docker.imagePullPolicy }}
  command: ["sh", "-c"]
  args:
    - >-
      source bin/coso-init.sh;
{{- if and .Values.tls.enabled .Values.tls.zookeeper.enabled }}
      until bin/pulsar zookeeper-shell -server {{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}:{{ .Values.zookeeper.ports.clientTls }} ls /admin/clusters/{{ template "pulsar.fullname" . }}; do
{{- else }}
      until bin/pulsar zookeeper-shell -server {{ template "pulsar.fullname" . }}-{{ .Values.zookeeper.component }}:{{ .Values.zookeeper.ports.client }}  ls /admin/clusters/{{ template "pulsar.fullname" . }}; do
{{- end }}
        sleep 3;
      done;
  volumeMounts:
  {{- include "pulsar.coso.init.volumeMounts" . | nindent 2 }}
  {{- include "pulsar.bastion.certs.volumeMounts" . | nindent 2 }}
  - name: tmp
    mountPath: /pulsar/tmp
  - name: conf
    mountPath: /pulsar/conf
  - name: logs
    mountPath: /pulsar/logs
  - name: ssl
    mountPath: /pulsar/ssl
  - name: vault-token
    mountPath: /var/run/secrets/boostport.com
{{- end }}


{{/*
zookeeper data local storage
*/}}
{{- define "zookeeper.data_local_storage" -}}
    {{- if eq (include  "pulsar.is_cloud_deployment" . ) "true" -}}
		{{- print "false" -}}
	{{- else -}}
		{{- printf "%t" .Values.zookeeper.volumes.data.local_storage -}}
	{{- end }}
{{- end }}

{{/*
zookeeper datalog local storage
*/}}
{{- define "zookeeper.datalog_local_storage" -}}
    {{- if eq (include  "pulsar.is_cloud_deployment" . ) "true" -}}
		{{- print "false" -}}
	{{- else -}}
		{{- printf "%t" .Values.zookeeper.volumes.dataLog.local_storage -}}
	{{- end }}
{{- end }}

{{/*
bookkeeper ledgers local storage
*/}}
{{- define "bookkeeper.ledgers_local_storage" -}}
    {{- if eq (include  "pulsar.is_cloud_deployment" . ) "true" -}}
		{{- print "false" -}}
	{{- else -}}
		{{- printf "%t" .Values.bookkeeper.volumes.ledgers.local_storage -}}
	{{- end }}
{{- end }}

{{/*
bookkeeper journal local storage
*/}}
{{- define "bookkeeper.journal_local_storage" -}}
    {{- if eq (include  "pulsar.is_cloud_deployment" . ) "true" -}}
		{{- print "false" -}}
	{{- else -}}
		{{- printf "%t" .Values.bookkeeper.volumes.journal.local_storage -}}
	{{- end }}
{{- end }}


{{/*
Define coso Set Bookie Rack volumes
*/}}
{{- define "pulsar.coso.pulsarbookierack.volumes" -}}
- name: pulsarsetbookierack
  configMap:
    name: "{{ template "pulsar.fullname" . }}-pulsarsetbookierack-configmap"
    defaultMode: 0755
{{- end }}

{{/*
Define Micro Focus Init script mount
*/}}
{{- define "pulsar.coso.pulsarbookierack.volumeMounts" -}}
- name: pulsarsetbookierack
  mountPath: "/pulsar/bin/pulsar-set-bookie-rack.sh"
  subPath: pulsar-set-bookie-rack.sh
{{- end }}

{{/*
is aws deployment
*/}}
{{- define "pulsar.is_aws_deployment" -}}
    {{- if eq (lower .Values.global.cluster.k8sProvider) "aws" -}}
        {{- printf "%t" true -}}
    {{- else -}}
        {{- printf "%t" false -}}
    {{- end -}}
{{- end -}}


