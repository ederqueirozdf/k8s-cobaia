{{- define "bvd.checkStartOfTheWeek" -}}  
  {{- $days := list "monday" "tuesday" "wednesday" "thursday" "friday" "saturday" "sunday" -}}
  {{- if has (lower (toString .Values.params.startOfTheWeek)) $days }}
  bvd.startOfTheWeek: {{ .Values.params.startOfTheWeek | quote }}
  {{- else }}
  {{- fail "ERROR: Provide valid day as input for startOfTheWeek" }}
  {{- end }}
{{- end }}