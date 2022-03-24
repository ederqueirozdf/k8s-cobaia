{{/*
Dashboards folder placement
*/}}
{{- define "dashboards.annotation.folder" -}}
k8s-sidecar-target-directory: {{ .Release.Namespace }}
{{- end }}