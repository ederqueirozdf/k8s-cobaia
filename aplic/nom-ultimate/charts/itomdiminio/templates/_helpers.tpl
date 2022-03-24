{{/*
is cloud deployment
*/}}
{{- define "minio.is_cloud_deployment" -}}
{{- if or (eq (lower .Values.global.cluster.k8sProvider) "azure") (eq (lower .Values.global.cluster.k8sProvider) "aws") -}}
{{- printf "%t" true -}}
{{- else -}}
{{- printf "%t" false -}}
{{- end -}}
{{- end -}}

{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "minio.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "minio.fullname" -}}
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
{{- define "minio.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for networkpolicy.
*/}}
{{- define "minio.networkPolicy.apiVersion" -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "minio.deployment.apiVersion" -}}
{{- print "apps/v1" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for statefulset.
*/}}
{{- define "minio.statefulset.apiVersion" -}}
{{- print "apps/v1" -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "minio.ingress.apiVersion" -}}
{{- print "networking.k8s.io/v1" -}}
{{- end -}}

{{/*
Determine service account name for deployment or statefulset.
*/}}
{{- define "minio.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "minio.fullname" .) .Values.serviceAccount.name | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}


{{/*
Create the common labels.
*/}}
{{- define "minio.standardLabels" -}}
app: {{ template "minio.name" . }}
chart: {{ template "minio.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
cluster: {{ template "minio.fullname" . }}
app.kubernetes.io/name:  {{ template "minio.fullname" . }}
app.kubernetes.io/managed-by: {{.Release.Name}}
app.kubernetes.io/version: {{.Chart.Version}}
itom.microfocus.com/capability: minio
tier.itom.microfocus.com/backend: backend
{{- end }}

{{/*
Create the template annotations.
*/}}
{{- define "minio.template.annotations" -}}
deployment.microfocus.com/default-replica-count: "4"
deployment.microfocus.com/runlevel: UP
{{- end }}

{{/*
   minio service type
  */}}
{{- define "minio.service_type" -}}
{{- if eq (include  "minio.is_cloud_deployment" . ) "true" -}}
{{- print "LoadBalancer" -}}
{{- else -}}
{{- print "ClusterIP" -}}
{{- end }}
{{- end -}}

{{/*
   minio service domain
  */}}
{{- define "minio.service_domain" -}}
	{{- if eq (include  "minio.is_cloud_deployment" . ) "true" -}}
        {{- if and (and .Values.global.di.cloud.externalDNS.enabled (empty .Values.global.loadBalancer.ip)) (not (empty .Values.global.di.cloud.externalAccessHost.minio)) -}}
       		{{- printf "external-dns.alpha.kubernetes.io/hostname: \"%s\"" .Values.global.di.cloud.externalAccessHost.minio -}}
        {{- end -}}
    {{- else -}}
         {{- print "" -}}
        {{- end -}}
{{- end }}

{{/*
minio azure loadbalancer ip
*/}}
{{- define "minio.azure_loadbalancer_ip" -}}
{{- if and (eq (lower .Values.global.cluster.k8sProvider) "azure") (not (empty .Values.global.loadBalancer.ip)) -}}
	{{- printf "loadBalancerIP: \"%s\"" .Values.global.loadBalancer.ip -}}
  {{- end -}}
{{- end -}}

{{/*
mini port
*/}}
{{- define "minio.azure_port" -}}
{{- if (eq (lower .Values.global.cluster.k8sProvider) "azure") -}}
{{- .Values.diminio.service.port -}}
{{- else -}}
{{- .Values.diminio.service.nodePort -}}
{{- end -}}
{{- end -}}

{{/*
 minio azure loadbalancer source ranges
*/}}
{{- define "minio.azure_loadbalancer_source_range" -}}
{{- if and (eq (include  "minio.is_cloud_deployment" . ) "true") (not (empty .Values.global.loadBalancer.sourceRanges)) -}}
{{ printf "loadBalancerSourceRanges:" }}
{{- with .Values.global.loadBalancer.sourceRanges }}
{{- toYaml . | nindent 4 }}
{{- end }}
{{- end -}}
{{- end -}}

