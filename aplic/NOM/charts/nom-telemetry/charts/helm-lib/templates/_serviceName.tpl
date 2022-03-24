#===========================================================================
# serviceName(instance:INSTANCE, suffix:SUFFIX)
# If "global.instance.INSTANCE" is defined, which is a Helm release name,
# then that specific instance of the desired service is returned.  Otherwise,
# the current Helm release name is prepended to the service name.  For example:
#
#   serviceName(instance:myService, suffix:mySuffix) will yield:
#       RELEASE_NAME-mySuffix            if global.instance.myService is not defined
#       FOO-mySuffix                     When global.instance.myService==FOO
#
#   similarly, serviceName(instance:zookeeper, suffix:zk-svc) will yield:
#       RELEASE_NAME-zk-svc              if global.instance.zookeeper is not defined
#       cold-fish-zk-svc                 When global.instance.zookeeper==cold-fish
#
{{- define "helm-lib.serviceName" -}}
{{- $instanceName := cat ".Values.global.instance." .instance | nospace -}}
{{- $evalInstanceName := cat "{{ " $instanceName " }}" -}}
{{- if tpl $evalInstanceName . -}}
{{- $serviceName := cat $evalInstanceName "-" .suffix | nospace -}}
{{- tpl $serviceName . -}}
{{- else -}}
{{- cat .Release.Name "-" .suffix | nospace -}}
{{- end -}}
{{- end -}}


#===========================================================================
# Returns the name of the zookeeper service (using "global.instance.zookeeper").
# For example: "cold-fish-zk-svc".
#
{{- define "helm-lib.serviceName.zookeeper" -}}
{{- include "helm-lib.serviceName" ( dict "instance" "zookeeper" "suffix" "zk-svc" "Release" .Release "Values" .Values "Template" .Template) }}
{{- end -}}


#===========================================================================
# Returns the name of the Postgres service (using "global.instance.postgres").
# For example: "cold-fish-itom-postgresql.NAMESPACE".
#
{{- define "helm-lib.serviceName.postgres" -}}
{{- include "helm-lib.serviceName" (dict "instance" "postgres" "suffix" "itom-postgresql" "Release" .Release "Values" .Values "Template" .Template) }}.{{ .Release.Namespace -}}
{{- end -}}


#===========================================================================
# This macro creates a "waitfor" definition which is expected to be part of the pod's "initContainer" section.
# The required parameters are "service" and "port", with optional parameter for "interval" (default value
# is 5 seconds between connection attempts).  As you can see in the code below, this expands into a
# "nc -z SERVICE PORT" call, inside a "forever" loop, until it succeeds.
#
{{- define "helm-lib.waitFor" -}}
{{- $serviceName := .service | lower -}}
{{- $port := .port | toString -}}
{{- $interval := .interval | default "5" -}}
{{- $serviceSuffix := (printf "%s-%s" (trunc 20 (replace "." "-" $serviceName)) $port) -}}
- name: waitfor-{{$serviceSuffix}}
  image: {{ .Values.global.docker.registry }}/{{ .Values.global.docker.orgName }}/{{ .Values.global.opensuse.image }}:{{ .Values.global.opensuse.imageTag }}
  imagePullPolicy: {{ .Values.global.docker.imagePullPolicy }}
  command: [ "sh", "-c", "until nc -z {{$serviceName}} {{$port}} -w 5 ; do echo waiting for {{$serviceName}}:{{$port}}...; sleep {{$interval}}; done; exit 0"]
  resources: {}
  {{- if or (.addSecurityContext) (eq (.addSecurityContext | toString) "<nil>") }}
  securityContext:
    runAsNonRoot: true
    runAsUser: {{ .Values.global.securityContext.user }}
    runAsGroup: {{ .Values.global.securityContext.fsGroup }}
  {{- end }}
{{- end -}}


#===========================================================================
# This macro is similar to the above, but intended to wait for multiple services.  The above macro can be
# called multiple times, each waiting for a single service, and each creating a new initContainer reference.
# Whereas this macro can only be called ONCE (an error will occur if it is called twice, since the
# "name" of the initContainer is not unique).  But this macro creates a single initContainer which
# waits for multiple services.
#
# The required parameter is "services" which is a space separated value of service:port values, e.g.
#      services = foo-svc:123 bar-svc:456 abc-svc:789
# It also has the optional "maxtries" (default to 24) and "interval" (default to 5 seconds).
#
{{- define "helm-lib.waitForMany" -}}
{{- $services := .services -}}
{{- $interval := .interval | default "5" -}}
- name: waitfor-dependencies
  image: {{ .Values.global.docker.registry }}/{{ .Values.global.docker.orgName }}/{{ .Values.global.opensuse.image }}:{{ .Values.global.opensuse.imageTag }}
  imagePullPolicy: {{ .Values.global.docker.imagePullPolicy }}
  command: [ "sh", "-c", "for svc in {{.services}} ; do until nc -z ${svc%:*} ${svc#*:} -w 5 ; do echo waiting for $svc...; sleep {{$interval}}; done; done; exit 0"]
  resources: {}
  {{- if or (.addSecurityContext) (eq (.addSecurityContext | toString) "<nil>") }}
  securityContext:
    runAsNonRoot: true
    runAsUser: {{ .Values.global.securityContext.user }}
    runAsGroup: {{ .Values.global.securityContext.fsGroup }}
  {{- end }}
{{- end -}}


#===========================================================================
# This macro creates an init container that runs a GET REST call on a provided URL and compares the http status code
# with an injected value. The GET call is executed every X seconds until the received status code matches the
# injected value, and when these two values don't match it logs the response.
#
# Required parameters:
# "service" - the value provided here will be used for naming the init container - eg: waitfor-$service
# "url" - the url against which the GET call is performed - eg: https://foo.bar.net:443/12345/api/version
# "code" - the expected status code for the check to succeed
#
# Optional parameter:
# "interval" - seconds to wait between check attempts
{{- define "helm-lib.waitForServiceUrl" -}}
{{- $name := .service | lower | nospace | trunc 55 -}}
{{- $url := .url | nospace -}}
{{- $code := .code -}}
{{- $interval := .interval | default "5" -}}
- name: waitfor-{{$name}}
  image: {{ .Values.global.docker.registry }}/{{ .Values.global.docker.orgName }}/{{ .Values.global.opensuse.image }}:{{ .Values.global.opensuse.imageTag }}
  imagePullPolicy: {{ .Values.global.docker.imagePullPolicy }}
  command: [ "sh", "-c", "CODE={{$code}} && CHECK='wget -q -S --spider --no-check-certificate '{{$url}}' 2>&1' && until [ `eval $CHECK | awk 'NR==1{print$2}'` == $CODE ] ; do echo Waiting for {{$url}}. Expected response: $CODE , received: `eval $CHECK | awk 'NR==1{print}'` ; sleep {{$interval}}; done; exit 0" ]
  resources: {}
  {{- if or (.addSecurityContext) (eq (.addSecurityContext | toString) "<nil>") }}
  securityContext:
    runAsNonRoot: true
    runAsUser: {{ .Values.global.securityContext.user }}
    runAsGroup: {{ .Values.global.securityContext.fsGroup }}
  {{- end }}
{{- end -}}


#===========================================================================
# This macro is a convenience macro to wait for "itom-vault" service, on port 8200.
#
{{- define "helm-lib.waitForVault" -}}
{{- include "helm-lib.waitFor" ( dict "service" "itom-vault" "port" "8200" "Values" .Values) }}
{{- end -}}

#===========================================================================
# This macro is a convenience macro to wait for "itom-vault" service without cdf default security context setting, on port 8200.
#
{{- define "helm-lib.waitForVaultNoSecurityContext" -}}
{{- include "helm-lib.waitFor" ( dict "addSecurityContext" false "service" "itom-vault" "port" "8200" "Values" .Values) }}
{{- end -}}