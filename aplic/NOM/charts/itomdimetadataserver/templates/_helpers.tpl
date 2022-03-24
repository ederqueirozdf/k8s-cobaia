#=============================================================================
  #validateTenantAndDeploymentForMetadataServer
  #validate the character length for tenant and deployment
  {{- define "validateTenantAndDeploymentForMetadataServer" -}}
  {{- $tenant := .Values.global.di.tenant | default "provider" -}}
  {{- $deployment := .Values.global.di.deployment | default "default" -}}
  {{- $lengthTenant := len $tenant -}}
  {{- $lengthDeployment := len $deployment -}}
  {{- $total := add $lengthTenant $lengthDeployment -}}
  {{- if lt $total 71 -}}
  {{ cat "- name: DI_TENANT" }}
  {{ cat "value: " | indent 12 }}
  {{- $tenant -}}
  {{ cat "\n- name: DI_DEPLOYMENT " | indent 12 }}
  {{ cat "value: " | indent 12 }}
  {{- $deployment -}}
  {{- end -}}
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

{{- define "externalaccess.hostname" -}}
{{- if (and (ne .Values.global.cluster.k8sProvider "cdf")  (not (empty .Values.di.cloud.externalAccessHost.dataAccess))) }}
{{- $hostname := .Values.di.cloud.externalAccessHost.dataAccess | quote -}}
{{- printf "%s" $hostname -}}
{{- else -}}
{{- $hostname := .Values.global.externalAccessHost | quote -}}
{{- printf "%s" $hostname -}}
{{- end -}}
{{- end -}}