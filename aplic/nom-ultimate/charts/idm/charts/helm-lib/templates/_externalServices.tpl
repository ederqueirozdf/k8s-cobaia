#
# The purpose of the macros in this file is to provide access to externally
# available services.  E.g. IDM can be a service which is deployed by a
# composition chart.  Or it can be an already-existing deployment of IDM
# in another namespace or even another external cluster.
#

#
# All the other macros which need cross-namespace access to a service
# use this one for the detailed implementation, passing in a service name.
#
{{- define "helm-lib.getOtherNsService" -}}
  {{- if .Values.global.services.sharedOpticReporting -}}
    {{- if .Values.global.services.namespace -}}
      {{- printf "%s.%s" .service .Values.global.services.namespace -}}
    {{- else -}}
      {{- if .Values.global.services.internal.host -}}
        {{- printf "%s" .Values.global.services.internal.host -}}
      {{- else -}}
        {{- if .Values.global.services.external.host -}}
          {{- printf "%s" .Values.global.services.external.host -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{- define "helm-lib.getExternalHost" -}}
  {{- if .Values.global.services.external.host -}}
    {{- printf "%s" .Values.global.services.external.host -}}
  {{- end -}}
{{- end -}}


{{- define "helm-lib.getExternalPort" -}}
  {{- if .Values.global.services.external.port -}}
    {{- printf "%s" (.Values.global.services.external.port | toString) -}}
  {{- end -}}
{{- end -}}

#
# If customer has internal network separate from external network, then
# the "internal host" would be on that internal network.  However if
# there is no internal network, then it is the same as the external
# host of the remote service.  Either way, we want to get access to
# a remote service on the Ingress port, e.g. AutoPass.
#
{{- define "helm-lib.getInternalHost" -}}
  {{- if .Values.global.services.internal.host -}}
    {{- printf "%s" .Values.global.services.internal.host -}}
  {{- else -}}
    {{- if .Values.global.services.external.host -}}
      {{- printf "%s" .Values.global.services.external.host -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{- define "helm-lib.getInternalPort" -}}
  {{- if .Values.global.services.internal.port -}}
    {{- printf "%s" (.Values.global.services.internal.port | toString) -}}
  {{- else -}}
    {{- if .Values.global.services.external.port -}}
      {{- printf "%s" (.Values.global.services.external.port | toString) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "helm-lib.getAplsHost" -}}
  {{- include "helm-lib.getOtherNsService" (deepCopy . | merge (dict "service" "itom-autopass-lms"))  -}}
{{- end -}}


{{- define "helm-lib.getAplsPort" -}}
    {{- if .Values.global.services.namespace -}}
      {{- printf "5814" -}}
    {{- else -}}
      {{- include "helm-lib.getInternalPort" . -}}
    {{- end -}}
{{- end -}}


{{- define "helm-lib.getDiAdminHost" -}}
  {{- include "helm-lib.getOtherNsService" (deepCopy . | merge (dict "service" "itom-di-administration-svc"))  -}}
{{- end -}}


#For cross namespace do nothing and return, so that default value set by the chart can be used, instead of using Nodeport 30004
{{- define "helm-lib.getDiAdminPort" -}}
  {{- if .Values.global.services.sharedOpticReporting -}}
    {{- if .Values.global.services.diAdminPort -}}
      {{- printf "%s" (.Values.global.services.diAdminPort | toString) -}}
    {{- else -}}
      {{- if not (.Values.global.services.namespace) -}}
          {{- printf "30004" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{- define "helm-lib.getDiDataAccessHost" -}}
  {{- include "helm-lib.getOtherNsService" (deepCopy . | merge (dict "service" "itom-di-data-access-svc"))  -}}
{{- end -}}

#For cross namespace do nothing and return, so that default value set by the chart can be used, instead of using Nodeport 30003
{{- define "helm-lib.getDiDataAccessPort" -}}
  {{- if .Values.global.services.sharedOpticReporting -}}
    {{- if .Values.global.services.diDataAccessPort -}}
      {{- printf "%s" (.Values.global.services.diDataAccessPort | toString) -}}
    {{- else -}}
      {{- if not (.Values.global.services.namespace) -}}
          {{- printf "30003" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- define "helm-lib.getDiPulsarProxyHost" -}}
  {{- include "helm-lib.getOtherNsService" (deepCopy . | merge (dict "service" "itomdipulsar-proxy"))  -}}
{{- end -}}

#For cross namespace do nothing and return, so that default value set by the chart can be used, instead of using Nodeport 31051
{{- define "helm-lib.getDiPulsarProxyClientPort" -}}
  {{- if .Values.global.services.sharedOpticReporting -}}
    {{- if .Values.global.services.diPulsarProxyClientPort -}}
      {{- printf "%s" (.Values.global.services.diPulsarProxyClientPort | toString) -}}
    {{- else -}}
      {{- if not (.Values.global.services.namespace) -}}
          {{- printf "31051" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

#For cross namespace do nothing and return, so that default value set by the chart can be used, instead of using Nodeport 31001
{{- define "helm-lib.getDiPulsarProxyWebPort" -}}
  {{- if .Values.global.services.sharedOpticReporting -}}
    {{- if .Values.global.services.diPulsarProxyWebPort -}}
      {{- printf "%s" (.Values.global.services.diPulsarProxyWebPort | toString) -}}
    {{- else -}}
      {{- if not (.Values.global.services.namespace) -}}
          {{- printf "31001" -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}


{{- define "helm-lib.getExternalIdmHost" -}}
  {{- if .Values.global.services.external.host -}}
    {{- printf "%s" .Values.global.services.external.host -}}
  {{- end -}}
{{- end -}}


{{- define "helm-lib.getExternalIdmPort" -}}
  {{- include "helm-lib.getExternalPort" . -}}
{{- end -}}


#
# Internal host can use cross-namespace access, if allowed.  Otherwise
# look for internal network configuration.  If neither, then default
# to external host.
#
{{- define "helm-lib.getInternalIdmHost" -}}
  {{- include "helm-lib.getOtherNsService" (deepCopy . | merge (dict "service" "itom-idm-svc"))  -}}
{{- end -}}


{{- define "helm-lib.getInternalIdmPort" -}}
    {{- if .Values.global.services.namespace -}}
      {{- printf "18443" -}}
    {{- else -}}
      {{- include "helm-lib.getInternalPort" . -}}
    {{- end -}}
{{- end -}}

{{- define "helm-lib.getExternalBvdHost" -}}
  {{- include "helm-lib.getExternalHost" . -}}
{{- end -}}

{{- define "helm-lib.getExternalBvdPort" -}}
  {{- include "helm-lib.getExternalPort" . -}}
{{- end -}}

#
# Internal host can use cross-namespace access, if allowed.  Otherwise
# look for internal network configuration.  If neither, then default
# to external host.
#
{{- define "helm-lib.getInternalBvdHost" -}}
  {{- include "helm-lib.getOtherNsService" (deepCopy . | merge (dict "service" "bvd-www"))  -}}
{{- end -}}

{{- define "helm-lib.getInternalBvdPort" -}}
    {{- if .Values.global.services.namespace -}}
      {{- printf "4000" -}}
    {{- else -}}
      {{- include "helm-lib.getInternalPort" . -}}
    {{- end -}}
{{- end -}}

