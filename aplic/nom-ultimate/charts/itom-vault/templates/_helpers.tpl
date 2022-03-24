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
Create the name of the service account to use
*/}}
{{- define "itom-vault.serviceAccountName" -}}
{{- if .Values.global.rbac.serviceAccountCreate -}}
    {{ default (printf "%s-%s" (include "namePrefix" .) "vault") .Values.deployment.rbac.serviceAccountName }}
{{- else -}}
    {{ default "default" .Values.deployment.rbac.serviceAccountName }}
{{- end -}}
{{- end -}}