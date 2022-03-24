{{/*
   *
   *  Mount details for oracle wallet configmap
   *
   *
   */}}
{{- define "bvd.oracleWallet" -}}
{{- if eq .args "volumeMounts" }}
{{- if .Values.global.database.oracleWalletName  }}
          - name: oracle-wallet-volume
            mountPath: /var/bvd/oracle_wallet

{{- end }}
{{- end }}

{{- if eq .args "volumes" }}
{{- if .Values.global.database.oracleWalletName  }}
      - name: oracle-wallet-volume
        configMap:
          name: {{ .Values.global.database.oracleWalletName  }}
{{- end }}
{{- end }}

{{- end -}}
