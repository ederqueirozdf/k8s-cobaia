{{/* vim: set filetype=mustache: */}}
{{/*
Vertica Database Properties.
*/}}

{{/*
is cloud deployment
*/}}
{{- define "dataaccess.is_cloud_deployment" -}}
{{- if or (eq (lower .Values.global.cluster.k8sProvider) "azure") (eq (lower .Values.global.cluster.k8sProvider) "aws") -}}
{{- printf "%t" true -}}
{{- else -}}
{{- printf "%t" false -}}
{{- end -}}
{{- end -}}

{{- define "vertica.host" -}}
{{- $vhost := "itom-di-vertica-svc" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vhost -}}
{{- else -}}
{{- $vhost := .Values.global.vertica.host | quote -}}
{{- printf "%s" $vhost -}}
{{- end -}}
{{- end -}}

{{- define "vertica.rwuser" -}}
{{- $vrwuser := "dbadmin" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vrwuser -}}
{{- else -}}
{{- $vrwuser := .Values.global.vertica.rwuser | quote -}}
{{- printf "%s" $vrwuser -}}
{{- end -}}
{{- end -}}

{{- define "vertica.rouser" -}}
{{- $vrouser := "dbadmin" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vrouser -}}
{{- else -}}
{{- $vrouser := .Values.global.vertica.rouser | quote -}}
{{- printf "%s" $vrouser -}}
{{- end -}}
{{- end -}}

{{- define "vertica.db" -}}
{{- $vdb := "itomdb" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vdb -}}
{{- else -}}
{{- $vdb := .Values.global.vertica.db | quote -}}
{{- printf "%s" $vdb -}}
{{- end -}}
{{- end -}}

{{- define "vertica.port" -}}
{{- $vport := "5444" | quote -}}
{{- if (eq (.Values.global.vertica.embedded | toString) "true") }}
{{- printf "%s" $vport -}}
{{- else -}}
{{- $vport := .Values.global.vertica.port | quote -}}
{{- printf "%s" $vport -}}
{{- end -}}
{{- end -}}

{{/*
data access service domain
*/}}
{{- define "dataaccess.service_domain" -}}
	{{- if eq (include  "dataaccess.is_cloud_deployment" . ) "true" -}}
        {{- if and (and .Values.global.di.cloud.externalDNS.enabled (empty .Values.global.loadBalancer.ip)) (not (empty .Values.global.di.cloud.externalAccessHost.dataAccess)) -}}
       		{{- printf "external-dns.alpha.kubernetes.io/hostname: \"%s\"" .Values.global.di.cloud.externalAccessHost.dataAccess -}}
        {{- end -}}
    {{- else -}}
         {{- print "" -}}
        {{- end -}}
{{- end }}


{{/*
data access service type
*/}}
{{- define "dataaccess.service_type" -}}
{{- if eq (include  "dataaccess.is_cloud_deployment" . ) "true" -}}
	{{- print "LoadBalancer" -}}
{{- else -}}
    {{- print "ClusterIP" -}}
{{- end -}}     
{{- end -}}

{{/*
data access azure loadbalancer ip
*/}}
{{- define "dataaccess.azure_loadbalancer_ip" -}}
{{- if and (eq (lower .Values.global.cluster.k8sProvider) "azure") (not (empty .Values.global.loadBalancer.ip)) -}}
	{{- printf "loadBalancerIP: \"%s\"" .Values.global.loadBalancer.ip -}}
  {{- end -}}
{{- end -}}

{{/*
  data access cloud loadbalancer source ranges
*/}}
{{- define "dataaccess.cloud_loadbalancer_source_range" -}}
{{- if and (eq (include  "dataaccess.is_cloud_deployment" . ) "true") (not (empty .Values.global.loadBalancer.sourceRanges)) -}}
{{ printf "loadBalancerSourceRanges:" }}
{{- with .Values.global.loadBalancer.sourceRanges }}
{{- toYaml . | nindent 4 }}
{{- end }}
{{- end -}}
{{- end -}}