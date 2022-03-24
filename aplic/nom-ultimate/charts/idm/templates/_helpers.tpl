{{/* vim: set filetype=mustache: */}}
# All names (service name, deployment name, config map name, etc.) will be prefixed as per following rules:
#    if .Values.namePrefix is injected, then use that.
#    else if .Values.backwardsCompat flag is true, prefix with Helm Release.Name, as per previous releases.
#    else prefix with "itom", since we want to STOP (i.e. deprecate) using Helm Release.Name in service names.
{{- define "namePrefix" -}}
{{- if and (not .Values.namePrefix) .Values.backwardsCompatServiceName -}}
{{- printf "%s-itom" .Release.Name -}}
{{- else -}}
{{- default "itom" .Values.namePrefix -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "itom-idm.serviceAccountName" -}}
{{- if .Values.global.rbac.serviceAccountCreate -}}
    {{ default (printf "%s-%s" (include "namePrefix" .) "idm") .Values.deployment.rbac.serviceAccountName }}
{{- else -}}
    {{ default "default" .Values.deployment.rbac.serviceAccountName }}
{{- end -}}
{{- end -}}

{{- define "getComponentName" -}}
  {{- if .Values.namePrefix -}}
    {{- printf "%s-%s" (trimSuffix "-" .Values.namePrefix) .Chart.Name | trunc 63  -}}
  {{- else if .Values.backwardsCompatServiceName -}}
    {{- printf "%s-%s" (trimSuffix "-" .Release.Name) .Chart.Name | trunc 63  -}}
  {{- else }}
    {{- printf "itom-idm" | trunc 63  -}}
  {{- end }}  
{{- end -}}

{{- define "kubernetes.domain-name" -}}
{{- coalesce .Values.global.kubernetesDomain.name .Values.global.cluster.kubernetesDomain | default "svc.cluster.local" }}
{{- end }}

{{- define "idm.cert" -}}
{{- $idmServiceName := (include "getComponentName" .) }}
{{- $domainName := (include "kubernetes.domain-name" .) }}
{{- printf "Common_Name:%s,Additional_SAN:%s/%s.%s/%s.%s.%s/%s/%s.%s/%s.%s.%s/%s/%s.%s/%s.%s.%s/%s/%s.%s/%s.%s.%s" $idmServiceName $idmServiceName $idmServiceName .Release.Namespace $idmServiceName .Release.Namespace $domainName "idm" "idm" .Release.Namespace "idm" .Release.Namespace $domainName "idm-svc" "idm-svc" .Release.Namespace "idm-svc" .Release.Namespace $domainName "itom-idm-svc" "itom-idm-svc" .Release.Namespace "itom-idm-svc" .Release.Namespace $domainName }}
{{- end }}

{{- define "idm-metrics.cert" -}}
{{- $idmServiceName := (include "getComponentName" .) }}
{{- $domainName := (include "kubernetes.domain-name" .) }}
{{- printf "Common_Name:%s,Additional_SAN:%s/%s.%s/%s.%s.%s/%s/%s.%s/%s.%s.%s/%s/%s.%s/%s.%s.%s/%s/%s.%s/%s.%s.%s,Secret:idm-metrics-client,UpdateSecret:true,File_Name:idm-metrics-client" $idmServiceName $idmServiceName $idmServiceName .Release.Namespace $idmServiceName .Release.Namespace $domainName "idm" "idm" .Release.Namespace "idm" .Release.Namespace $domainName "idm-svc" "idm-svc" .Release.Namespace "idm-svc" .Release.Namespace $domainName "itom-idm-svc" "itom-idm-svc" .Release.Namespace "itom-idm-svc" .Release.Namespace $domainName }}
{{- end }}