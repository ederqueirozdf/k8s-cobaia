{{/*
   *
   *  Annotation for the list of configmaps to be monitored for automatic restart
   *
   *
   */}}
{{- define "bvd.monitorConfigmap" -}}
{{- $configMaps := "bvd-config,bvd-services-config" -}}

{{- if .Values.global.tlsTruststore }}
{{- $configMaps = printf "%s,%s" $configMaps .Values.global.tlsTruststore }}
{{- end }}

{{- if .Values.global.database.tlsTruststore }}
{{- $configMaps = printf "%s,%s" $configMaps .Values.global.database.tlsTruststore }}
{{- end }}

{{- if .Values.global.database.oracleWalletName }}
{{- $configMaps = printf "%s,%s" $configMaps .Values.global.database.oracleWalletName }}
{{- end }}

configmap.reloader.stakater.com/reload: {{ $configMaps | quote }}
{{- end -}}
