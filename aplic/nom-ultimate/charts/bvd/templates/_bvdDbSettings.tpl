{{/*
   *
   *  BVD DB Settings
   *
   *  bvd.params have higher precendence over global.database
   *  
   */}}
{{- define "bvd.dbsettings" -}}
  {{- $tlsCert := "" -}}
  {{- if (or .Values.deployment.database .Values.global.database) }}
  {{- if (and (not .Values.global.database.internal) (or .Values.deployment.database.tlsEnabled .Values.global.database.tlsEnabled)) }}
  {{- if (eq (include "helm-lib.dbType" .)  "postgresql") }}
  {{- if (or .Values.deployment.database.tlsCert .Values.global.database.tlsCert) }}
  {{- $tlsCert = (coalesce .Values.deployment.database.tlsCert .Values.global.database.tlsCert "") | b64enc -}}
  {{- else }}
  {{- if (and (not .Values.global.certificateSecret) (not .Values.global.database.tlsTruststore) (not .Values.global.tlsTruststore)) }}
  {{- fail "Error: You must provide certificate for TLS Connection" }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if (eq (include "helm-lib.dbType" .)  "oracle") }}
  {{- if (not .Values.global.database.oracleWalletName) }}
  {{- fail "Error: You must provide wallet for TLS Connection" }}
  {{- end }}
  {{- end }}
  {{- end }}
  {{- end }}

  bvd.dbCa.base64: {{ $tlsCert | quote }}
  bvd.dbCa.base64.key: "bvd_db_cert"
{{- end -}}
