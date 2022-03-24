{{/*
   *
   *  Global certificate secret
   *
   *  
   */}}
{{- define "bvd.certificateSecret" -}}
{{- if eq .args "volumeMounts" }}
{{- if .Values.global.certificateSecret }}
          - name: secret-volume
            mountPath: /var/opt/composition/certificates
{{- end }}
{{- end }}

{{- if eq .args "volumes" }}
{{- if .Values.global.certificateSecret }}
      - name: secret-volume
        secret:
          secretName: {{ .Values.global.certificateSecret }}
{{- end }}
{{- end }}

{{- end -}}