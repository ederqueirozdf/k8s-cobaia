{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "scheduler.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
is cloud deployment
*/}}
{{- define "scheduler.is_cloud_deployment" -}}
{{- if or (eq (lower .Values.global.cluster.k8sProvider) "azure") (eq (lower .Values.global.cluster.k8sProvider) "aws") -}}
{{- printf "%t" true -}}
{{- else -}}
{{- printf "%t" false -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "scheduler.fullname" -}}
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

#validateTenantAndDeploymentForUdxScheduler
#validate the character length for tenant and deployment
{{- define "validateTenantAndDeploymentForUdxScheduler" -}}
{{- $tenant := .Values.global.di.tenant | default "provider" -}}
{{- $deployment := .Values.global.di.deployment | default "default" -}}
{{- $lengthTenant := len $tenant -}}
{{- $lengthDeployment := len $deployment -}}
{{- $total := add $lengthTenant $lengthDeployment -}}
{{- if lt $total 71 -}}
{{- cat "di.tenant: " -}}
  {{- $tenant -}}
  {{ cat "\ndi.deployment: " | indent 2 }}
  {{- $deployment }}
{{- end -}}
{{- end -}}

{{- define "resource.pool" -}}
  {{- if and (.Values.global.vertica.resourcepoolname) (not .Values.global.vertica.embedded ) }}
    {{- printf "%s" .Values.global.vertica.resourcepoolname | trunc 63 | trimSuffix "-" | replace "-" "_" | lower -}}
  {{- else -}}
      {{- if .Values.global.di -}}
      {{- $tenant :=  .Values.global.di.tenant | default "provider" -}}
      {{- $deployment := .Values.global.di.deployment | default "default" -}}
      {{- printf "%s-%s-%s" "itom-di-stream-respool" $tenant $deployment| trunc 63 | trimSuffix "-" | replace "-" "_" | lower -}}
      {{- else -}}
      {{- printf "itom-di-stream-respool-provider-default" | trunc 63 | trimSuffix "-" | replace "-" "_" | lower -}}    
      {{- end -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "scheduler.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Vertica Database Properties.
*/}}

{{- define "vertica.host" -}}
{{- $vhost := "itom-di-vertica-svc" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vhost -}}
{{- else -}}
{{- $vhost := .Values.global.vertica.host | quote -}}
{{- printf "%s" $vhost -}}
{{- end -}}
{{- end -}}

{{- define "vertica.rwuser" -}}
{{- $vrwuser := "dbadmin" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vrwuser -}}
{{- else -}}
{{- $vrwuser := .Values.global.vertica.rwuser | quote -}}
{{- printf "%s" $vrwuser -}}
{{- end -}}
{{- end -}}

{{- define "vertica.rouser" -}}
{{- $vrouser := "dbadmin" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vrouser -}}
{{- else -}}
{{- $vrouser := .Values.global.vertica.rouser | quote -}}
{{- printf "%s" $vrouser -}}
{{- end -}}
{{- end -}}

{{- define "vertica.db" -}}
{{- $vdb := "itomdb" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vdb -}}
{{- else -}}
{{- $vdb := .Values.global.vertica.db | quote -}}
{{- printf "%s" $vdb -}}
{{- end -}}
{{- end -}}

{{- define "vertica.port" -}}
{{- $vport := "5444" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vport -}}
{{- else -}}
{{- $vport := .Values.global.vertica.port | quote -}}
{{- printf "%s" $vport -}}
{{- end -}}
{{- end -}}

## Set UDX Scheduler Schema For Go Scheduler
{{- define "scheduler.schema" -}}
{{- $envVal := .Values.scheduler.configData.env.SCHED_PULSAR_UDX_SCHEMA |default "UNSET" -}}
{{- if eq $envVal "UNSET" -}}
{{- $component := .Values.scheduler.component | default "scheduler" -}}
{{- if .Values.global.di -}}
{{- $tenant :=  .Values.global.di.tenant | default "provider" -}}
{{- $deployment := .Values.global.di.deployment | default "default" -}}
{{- printf "itom-di-%s-%s-%s" $component $tenant $deployment| trunc 63 | trimSuffix "-" | replace "-" "_" | lower -}}
{{- else -}}
{{- printf "itom-di-%s-%s-%s" $component "provider" "default" | trunc 63 | trimSuffix "-" | replace "-" "_" | lower -}}
{{- end -}}
{{- else -}}
{{- printf $envVal -}}
{{- end -}}
{{- end -}}


{{/*
pulsar proxy service name
*/}}
{{- define "pulsar.proxy_service_name" -}}
    {{- if eq (include  "scheduler.is_cloud_deployment" . ) "false" -}}
        {{- printf "\"%s\"" .Values.global.externalAccessHost -}}
    {{- else -}}
        {{- if and (eq (lower .Values.global.cluster.k8sProvider) "azure") (not (empty .Values.global.loadBalancer.ip)) -}}
            {{- printf "\"%s\"" .Values.global.externalAccessHost -}}
        {{- else -}}
            {{- printf "\"%s\"" .Values.global.di.cloud.externalAccessHost.pulsar -}}
        {{- end -}}
    {{- end }}
{{- end }}

{{/*
pulsar proxy service port
*/}}
{{- define "pulsar.proxy_service_port" -}}
	{{- if or (and ( eq (include  "scheduler.is_cloud_deployment" . ) "true" )  (not (empty .Values.global.di.cloud.externalAccessHost.pulsar))) (eq (lower .Values.global.cluster.k8sProvider) "azure") -}}
		{{- printf "\"%d\"" (int64 .Values.proxy.ports.pulsarssl) -}}
	{{- else -}}
		{{- printf "\"%d\"" (int64 .Values.global.di.proxy.nodePorts.pulsarssl | default 31051 ) -}}
	{{- end }}
{{- end }}

{{- define "scheduler.frame_duration" -}}
	{{- if (ne .Values.scheduler.configData.scheduler.frameDuration "00:00:30") }}
		{{- printf "\"%s\"" .Values.scheduler.configData.scheduler.frameDuration -}}
	{{- else if .Values.scheduler.configData.scheduler.frameDurationSeconds }}
		{{- printf "\"%s\"" .Values.scheduler.configData.scheduler.frameDurationSeconds -}}
	{{- else -}}
    		{{- printf "\"%s\"" .Values.scheduler.configData.scheduler.frameDuration -}}
	{{- end }}
{{- end }}
