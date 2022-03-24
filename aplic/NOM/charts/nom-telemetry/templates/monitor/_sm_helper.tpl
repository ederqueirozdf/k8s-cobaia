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
Prometheus ServiceMonitor namespaceSelector
*/}}
{{- define "telemetry.servicemonitor.labels" -}}
prometheus_config: "1"
app.kubernetes.io/managed-by: {{.Release.Name}}
app.kubernetes.io/version: {{.Chart.Version}}
itom.microfocus.com/capability: itom-data-ingestion
tier.itom.microfocus.com/backend: backend
{{- end }}

{{/*
Prometheus ServiceMonitor tlsConfig RID
*/}}
{{- define "telemetry.servicemonitor.tlsConfig.certs.rid" -}}
cert:
  secret:
    name: prometheus-client
    key: tls.crt
keySecret:
  name: prometheus-client
  key: tls.key
ca:
  configMap:
    name: public-ca-certificates
    key: RID_ca.crt
{{- end }}

{{/*
Prometheus ServiceMonitor base relabelings
*/}}
{{- define "telemetry.servicemonitor.relabelings" -}}
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
{{- define "telemetry.servicemonitor.namespaceSelector" -}}
namespaceSelector:
  matchNames:
  - {{ .Release.Namespace }}
{{- end }}
