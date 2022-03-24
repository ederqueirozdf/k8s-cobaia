{{/*
   *
   *  Mount for /var/bvd where coverage data would be stored
   *
   *  
   */}}
{{- define "bvd.mountForCoverageData" -}}
{{- if eq .args "volumeMounts" }}
{{- if eq .Values.params.testing true }}
          - name: bvd-var
            mountPath: /var/bvd
            subPath: bvd/var/bvd
{{- end }}
{{- end }}

{{- if eq .args "volumes" }}
{{- if eq .Values.params.testing true }}
{{- if eq .Values.global.persistence.enabled true}}
      - name: bvd-var
        persistentVolumeClaim:
          claimName: {{ include "helm-lib.pvcStorageName" ( dict "claim" "configVolumeClaim" "Release" .Release "Values" .Values ) }}
{{- else -}}
      - name: bvd-var
        persistentVolumeClaim:
          claimName: {{ .Values.global.persistence.configVolumeClaim }}
{{- end }}
{{- end }}
{{- end }}

{{- end -}}