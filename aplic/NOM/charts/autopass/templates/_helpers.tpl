# All names (service name, deployment name, config map name, etc.) will be prefixed as per following rules:
#    if .Values.namePrefix is injected, then use that.
#    else if .Values.backwardsCompat flag is true, prefix with Helm Release.Name, as per previous releases.
#    else prefix with "itom", since we want to STOP (i.e. deprecate) using Helm Release.Name in service names.
#
{{- define "namePrefix" -}}
{{- if and (not .Values.namePrefix) .Values.backwardsCompatServiceName -}}
{{- printf "%s-itom" .Release.Name -}}
{{- else -}}
{{- default "itom" .Values.namePrefix -}}
{{- end -}}
{{- end -}}

{{/* RBAC */}}
{{/* Validate that only boolean values are provided via global.rbac values */}}
{{- define "autopass.rbac.validate.boolType" -}}
{{- if kindIs "bool" .Values.global.rbac.serviceAccountCreate -}}
true
{{- else -}}
{{- cat "\n\n[AutoPass] ERROR: The value of helm parameter 'global.rbac.serviceAccountCreate' is not of type boolean" | fail -}}
{{- end -}}
{{- if kindIs "bool" .Values.global.rbac.roleCreate -}}
true
{{- else -}}
{{- cat "\n\n[AutoPass] ERROR: The value of helm parameter 'global.rbac.roleCreate' is not of type boolean" | fail -}}
{{- end -}}
{{- end -}}

{{- define "autopass.rbac.sa.name" -}}
{{- if (include "autopass.rbac.validate.boolType" .) -}}
  {{- if and ( not .Values.global.rbac.serviceAccountCreate ) (not .Values.deployment.rbac.serviceAccount) -}}
    {{- cat "\n\n[AutoPass] ERROR: Detected global.rbac.serviceAccountCreate=false but no service account name provided via parameter 'deployment.rbac.serviceAccount'" | fail -}}
  {{- end -}}
  {{- $namePrefix := (include "namePrefix" .) -}}
  {{- if .Values.deployment.rbac.serviceAccount -}}
    {{- print .Values.deployment.rbac.serviceAccount -}}
  {{- else -}}
    {{- printf "%v-autopass-lms" $namePrefix -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "autopass.rbac.role.name" -}}
  {{- $namePrefix := (include "namePrefix" .) -}}
  {{- printf "%v-autopass-lms" $namePrefix -}}
{{- end -}}

{{/* IDM URL */}}
{{- define "autopass.idm.authUrl" -}}
{{- default ( printf "https://%s:%d/idm-service" .Values.global.externalAccessHost (int64 .Values.global.externalAccessPort) ) .Values.global.idm.idmAuthUrl -}}
{{- end -}}

{{- define "autopass.idm.serviceUrl" -}}
{{- default (include "autopass.idm.authUrl" .) .Values.global.idm.idmServiceUrl -}}
{{- end -}}

{{- define "apls.replicas" -}}
{{- if (kindIs "bool" .Values.deployment.replicas) -}}
    {{- cat "\n\n[AutoPass] ERROR: The value provided for deployment.replicas is not valid (range: >=1 and should be of type integer)" | fail -}}
{{- else -}}
    {{- if not (empty (.Values.deployment.replicas) ) -}}
        {{- if ( ge (int64 .Values.deployment.replicas ) 1 ) -}}
            {{- printf "%d" (int64 .Values.deployment.replicas ) -}}
        {{- else -}}
            {{- cat "\n\n[AutoPass] ERROR: The value provided for deployment.replicas is not valid (range: >=1 and should be of type integer)" | fail -}}
        {{- end -}}
    {{- else -}}
        {{- if eq (.Values.deployment.replicas | toString) "0" -}}
            {{- cat "\n\n[AutoPass] ERROR: The value provided for deployment.replicas is not valid (range: >=1 and should be of type integer)" | fail -}}
        {{- else -}}
            {{- printf "%d" (1) -}}
        {{- end -}}
    {{- end -}}
{{- end -}}
{{- end -}}
