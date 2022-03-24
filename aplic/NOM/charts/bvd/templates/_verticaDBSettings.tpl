{{/*
   *
   *  Vertica DB Settings
   *
   *
   */}}
{{- define "bvd.verticaDBSettings" -}}
  {{- if .Values.global.vertica }}
  {{- if and .Values.global.vertica.embedded (eq (toString .Values.global.vertica.embedded) "true") }}
  bvd.defaultVerticaUser: {{ coalesce .Values.global.vertica.rouser .Values.global.vertica.rwuser | default "dbadmin" | quote }}
  bvd.defaultVerticaPW.key: {{ coalesce .Values.global.vertica.rouserkey .Values.global.vertica.rwuserkey | default "ITOMDI_RO_USER_PASSWORD_KEY" | quote }}
  bvd.defaultVerticaHost: {{ .Values.global.vertica.host | default "itom-di-vertica-svc" | quote }}
  bvd.defaultVerticaDB: {{ .Values.global.vertica.db | default "itomdb" | quote }}
  bvd.defaultVerticaPort: {{ .Values.global.vertica.port | default "5444" | quote }}
  bvd.defaultVerticaTLS: {{ .Values.global.vertica.tlsEnabled | default true | quote }}
  {{- else }}
  bvd.defaultVerticaUser: {{ coalesce .Values.global.vertica.rouser .Values.global.vertica.rwuser | default "" | quote }}
  bvd.defaultVerticaPW.key: {{ coalesce .Values.global.vertica.rouserkey .Values.global.vertica.rwuserkey | default "" | quote }}
  bvd.defaultVerticaHost: {{ .Values.global.vertica.host | default "" | quote }}
  bvd.defaultVerticaDB: {{ .Values.global.vertica.db | default "" | quote }}
  bvd.defaultVerticaPort: {{ .Values.global.vertica.port | default "" | quote }}
  bvd.defaultVerticaTLS: {{ .Values.global.vertica.tlsEnabled | default false | quote }}
  {{- end }}
  {{- end }}
{{- end -}}
