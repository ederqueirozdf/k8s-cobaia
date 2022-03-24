{{/*
   *
   *  global Trust Store for Certificates
   *
   *
   */}}
{{- define "bvd.globalTlsTrustStore" -}}
{{- if eq .args "volumeMounts" }}
{{- if .Values.global.tlsTruststore }}
          - name: global-cert-volume
            mountPath: /var/bvd/globalCertificates

{{- end }}
{{- end }}

{{- if eq .args "volumes" }}
{{- if .Values.global.tlsTruststore }}
      - name: global-cert-volume
        configMap:
          name: {{ .Values.global.tlsTruststore }}
{{- end }}
{{- end }}

{{- end -}}
