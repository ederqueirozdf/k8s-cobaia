{{/*
   *
   *  BVD pod affinity 
   *
   */}}
{{- define "bvd.affinity" -}}
{{- if .Values.affinity -}}
  {{- toYaml .Values.affinity -}}
{{- else -}}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 100
    podAffinityTerm:
      labelSelector:
        matchExpressions:
        - key: service
          operator: In
          values:
          - {{ .deployment }}
      topologyKey: "kubernetes.io/hostname"
{{- end -}}
{{- end -}}