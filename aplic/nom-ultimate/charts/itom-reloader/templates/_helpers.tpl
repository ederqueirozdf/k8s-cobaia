{{/* vim: set filetype=mustache: */}}
{{/*
  All names (service name, deployment name, config map name, etc.) will be prefixed as per following rules:
    if .Values.namePrefix is injected, then use that.
    else if .Values.backwardsCompat flag is true, prefix with Helm Release.Name, as per previous releases.
    else prefix with "itom", since we want to STOP (i.e. deprecate) using Helm Release.Name in service names.
*/}}
{{- define "namePrefix" -}}
{{- if and (not .Values.namePrefix) .Values.backwardsCompatServiceName -}}
{{- printf "%s-itom" .Release.Name -}}
{{- else -}}
{{- default "itom" .Values.namePrefix -}}
{{- end -}}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "itom-reloader.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" | lower -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "itom-reloader.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "itom-reloader.chart" -}}
app: {{ template "itom-reloader.fullname" . }}
chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
release: {{ .Release.Name | quote }}
heritage: {{ .Release.Service | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end -}}

{{/*Common labels*/}}
{{- define "itom-reloader.labels" -}}
app.kubernetes.io/name: {{ include "namePrefix" . }}-reloader
helm.sh/chart: {{ include "namePrefix" . }}-reloader
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*Selector labels*/}}
{{- define "itom-reloader.selectorLabels" -}}
app.kubernetes.io/name: {{ include "namePrefix" . }}-reloader
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

