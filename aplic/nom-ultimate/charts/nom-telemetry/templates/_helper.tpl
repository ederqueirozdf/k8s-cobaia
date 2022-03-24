#
#  (c) Copyright 2018-2021 Micro Focus or one of its affiliates.
#
#  The only warranties for products and services of Micro Focus and its affiliates and licensors
#  ("Micro Focus") are as may be set forth in the express warranty statements accompanying such
#  products and services. Nothing herein should be construed as constituting an additional
#  warranty. Micro Focus shall not be liable for technical or editorial errors or omissions contained
#  herein. The information contained herein is subject to change without notice.
#
#  Except as specifically indicated otherwise, this document contains confidential information
#  and a valid license is required for possession, use or copying. If this work is provided to the
#  U.S. Government, consistent with FAR 12.211 and 12.212, Commercial Computer Software,
#  Computer Software Documentation, and Technical Data for Commercial Items are licensed
#  to the U.S. Government under vendor's standard commercial license.
#
{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "telemetry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "telemetry.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "telemetry.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

