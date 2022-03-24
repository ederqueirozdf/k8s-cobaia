{{/*
   *
   *  global.database Trust Store for Certificates
   *
   *
   */}}
{{- define "bvd.tlsTrustStore" -}}
{{- if eq .args "volumeMounts" }}
{{- if .Values.global.database.tlsTruststore }}
          - name: cert-volume
            mountPath: /var/bvd/certificates

{{- end }}
{{- end }}

{{- if eq .args "volumes" }}
{{- if .Values.global.database.tlsTruststore }}
      - name: cert-volume
        configMap:
          name: {{ .Values.global.database.tlsTruststore }}
{{- end }}
{{- end }}

{{- end -}}
