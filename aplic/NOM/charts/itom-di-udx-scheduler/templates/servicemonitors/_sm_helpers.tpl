{{/* vim: set filetype=mustache: */}}

{{/*
Prometheus ServiceMonitor Labels
*/}}
{{- define "servicemonitor.labels" -}}
{{- toYaml .Values.global.prometheus.prometheusSelector }}
app.kubernetes.io/managed-by: {{.Release.Name}}
app.kubernetes.io/version: {{.Chart.Version}}
itom.microfocus.com/capability: itom-data-ingestion
tier.itom.microfocus.com/backend: backend
{{- end }}

{{/*
Prometheus ServiceMonitor tlsConfig RID
*/}}
{{- define "servicemonitor.tlsConfig.certs.rid" -}}
cert:
  secret:
    name: {{ .Values.global.prometheus.scrapeCertSecretName }}
    key: tls.crt
keySecret:
  name: {{ .Values.global.prometheus.scrapeCertSecretName }}
  key: tls.key
ca:
  configMap:
    name: public-ca-certificates
    key: RID_ca.crt
{{- end }}

{{/*
Prometheus ServiceMonitor base relabelings
*/}}
{{- define "servicemonitor.relabelings" -}}
- sourceLabels: [__meta_kubernetes_pod_label_component]
  targetLabel: job
- sourceLabels: [__meta_kubernetes_pod_name]
  targetLabel: kubernetes_pod_name
- action: labelmap
  regex: __meta_kubernetes_pod_label_(.+)
{{- end }}

{{/*
Prometheus ServiceMonitor namespaceSelector
*/}}
{{- define "servicemonitor.namespaceSelector" -}}
namespaceSelector:
  matchNames:
  - {{ .Release.Namespace }}
{{- end }}
