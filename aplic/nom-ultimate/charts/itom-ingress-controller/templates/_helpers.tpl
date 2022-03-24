{{/* vim: set filetype=mustache: */}}
{{/*
  All names (service name, deployment name, config map name, etc.) will be prefixed as per following rules:
    if .Values.namePrefix is injected, then use that.
    else if .Values.backwardsCompat flag is true, prefix with Helm Release.Name, as per previous releases.
    else prefix with "itom", since we want to STOP (i.e. deprecate) using Helm Release.Name in service names.
*/}}
{{- define "namePrefix" -}}
{{- if and (not .Values.namePrefix) .Values.backwardsCompatServiceName -}}
{{- printf "%s-itom" .Release.Name | trunc 30  | trimSuffix "-" -}}
{{- else -}}
{{- default "itom" .Values.namePrefix -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "itom-nginx-ingress-controller.labels" -}}
app.kubernetes.io/name: {{ include "namePrefix" . }}-ingress-controller
helm.sh/chart: {{ include "namePrefix" . }}-ingress-controller
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "itom-nginx-ingress-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "namePrefix" . }}-ingress-controller
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "itom-nginx-ingress-controller.tlsCertResolve" -}}
{{ $cert := .Values.global.tls.cert }}
{{- if (contains "-----BEGIN" $cert) }}
{{- $newVal := ( replace " " "\n" $cert | replace "\nCERTIFICATE" " CERTIFICATE" ) }}
{{- printf "%s" $newVal | b64enc }}
{{- else }}
{{- printf "%s" $cert }}
{{- end }}
{{- end -}}

{{- define "itom-nginx-ingress-controller.tlsKeyResolve" -}}
{{ $key := .Values.global.tls.key }}
{{- if (contains "-----BEGIN" $key) }}
{{- $newVal := ( replace " " "\n" $key) | replace "\nRSA"  " RSA" | replace "\nPRIVATE" " PRIVATE" | replace "\nKEY" " KEY" }}
{{- printf "%s" $newVal | b64enc}}
{{- else }}
{{- printf "%s" $key }}
{{- end }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "itom-nginx-ingress-controller.serviceAccountName" -}}
{{- if .Values.global.rbac.serviceAccountCreate -}}
    {{ default (printf "%s-%s" (include "namePrefix" .) "ingress-controller") .Values.deployment.rbac.serviceAccountName }}
{{- else -}}
    {{ default "default" .Values.deployment.rbac.serviceAccountName }}
{{- end -}}
{{- end -}}
