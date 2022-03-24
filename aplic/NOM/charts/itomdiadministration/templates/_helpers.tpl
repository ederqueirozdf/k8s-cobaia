#=============================================================================
  #validateTenantAndDeploymentForAdmin
  #validate the character length for tenant and deployment
  {{- define "validateTenantAndDeploymentForAdmin" -}}
  {{- $tenant := .Values.global.di.tenant | default "provider" -}}
  {{- $deployment := .Values.global.di.deployment | default "default" -}}
  {{- $lengthTenant := len $tenant -}}
  {{- $lengthDeployment := len $deployment -}}
  {{- $total := add $lengthTenant $lengthDeployment -}}
  {{- if lt $total 71 -}}
    {{- cat "di.tenant: " -}}
    {{- $tenant -}}
    {{ cat "\ndi.deployment: " | indent 2 }}
    {{- $deployment }}
  {{- end -}}
  {{- end -}}

{{/*
is cloud deployment
*/}}
{{- define "admin.is_cloud_deployment" -}}
{{- if or (eq (lower .Values.global.cluster.k8sProvider) "azure") (eq (lower .Values.global.cluster.k8sProvider) "aws") -}}
{{- printf "%t" true -}}
{{- else -}}
{{- printf "%t" false -}}
{{- end -}}
{{- end -}}

{{/*
Vertica Database Properties.
*/}}

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
admin service domain
*/}}
{{- define "admin.service_domain" -}}
	{{- if eq (include  "admin.is_cloud_deployment" . ) "true" -}}
	    {{- if and (and .Values.global.di.cloud.externalDNS.enabled (empty .Values.global.loadBalancer.ip)) (not (empty .Values.global.di.cloud.externalAccessHost.administration)) -}}
       		{{- printf "external-dns.alpha.kubernetes.io/hostname: \"%s\"" .Values.global.di.cloud.externalAccessHost.administration -}}
        {{- end -}}
    {{- else -}}
         {{- print "" -}}
        {{- end -}}
{{- end }}


{{/*
admin service type
*/}}
{{- define "admin.service_type" -}}
{{- if eq (include  "admin.is_cloud_deployment" . ) "true" -}}
	{{- print "LoadBalancer" -}}
  {{- else -}}
      {{- print "ClusterIP" -}}
  {{- end -}}
{{- end -}}


{{/*
MinIO/S3 Properties.
*/}}

{{- define "minio.host" -}}
{{- if .Values.diadmin.config.minio.host -}}
   {{- print .Values.diadmin.config.minio.host -}}
{{- else -}}
   {{- if eq (.Values.global.cluster.k8sProvider | toString) "aws" -}}
       {{- printf "s3.%s.amazonaws.com" .Values.diadmin.config.s3.region -}}
   {{- else -}}
       {{- print "itom-di-minio-svc" -}}
   {{- end -}}
{{- end -}}
{{- end -}}

{{- define "minio.port" -}}
{{- if .Values.diadmin.config.minio.port -}}
   {{- $mport := .Values.diadmin.config.minio.port | quote -}}
   {{- printf "%s" $mport -}}
{{- else -}}
   {{- if eq (.Values.global.cluster.k8sProvider | toString) "aws" -}}
       {{- $mport := "443" | quote -}}
       {{- printf "%s" $mport -}}
   {{- else -}}
       {{- $mport := "9000" | quote -}}
       {{- printf "%s" $mport -}}
   {{- end -}}
{{- end -}}
{{- end -}}

{{- define "minio.ssl" -}}
{{- if .Values.diadmin.config.minio.tlsEnabled -}}
   {{- $mssl := .Values.diadmin.config.minio.tlsEnabled | quote -}}
   {{- printf "%s" $mssl -}}
{{- else -}}
   {{- $mssl := "true" | quote -}}
   {{- printf "%s" $mssl -}}
{{- end -}}
{{- end -}}


{{- define "minio.nodePort" -}}
{{- if .Values.diadmin.config.minio.service.nodePort -}}
   {{- $mnodePort := .Values.diadmin.config.minio.service.nodePort | quote -}}
   {{- printf "%s" $mnodePort -}}
{{- else -}}
   {{- if eq (.Values.global.cluster.k8sProvider | toString) "aws" -}}
       {{- $mnodePort := "443" | quote -}}
       {{- printf "%s" $mnodePort -}}
   {{- else if eq (.Values.global.cluster.k8sProvider | toString) "azure" -}}
        {{- if .Values.diadmin.config.minio.port -}}
             {{- $mnodePort := .Values.diadmin.config.minio.port | quote -}}
             {{- printf "%s" $mnodePort -}}
        {{- else -}}
             {{- $mnodePort := "9000" | quote -}}
             {{- printf "%s" $mnodePort -}}
           {{- end -}}
   {{- else -}}
        {{- $mnodePort := "30006" | quote -}}
        {{- printf "%s" $mnodePort -}}
   {{- end -}}
{{- end -}}
{{- end -}}

{{- define "minio.externalAccessHost" -}}
{{- if and (eq (lower .Values.global.cluster.k8sProvider) "azure") (empty .Values.global.loadBalancer.ip) -}}
   {{- print .Values.global.di.cloud.externalAccessHost.minio -}}
{{- else -}}
   {{- print .Values.global.externalAccessHost -}}
{{- end -}}
{{- end -}}

{{/*
S3 Bucket Prefix Validation
*/}}
{{- define "validateS3BucketPrefix" -}}
{{- if regexMatch "^[a-z0-9][a-z0-9-]*$" .Values.diadmin.config.s3.bucketPrefix -}}
{{- if lt (len .Values.diadmin.config.s3.bucketPrefix) 37 -}}
{{- printf "admin.s3.bucketPrefix: \"%s\"" .Values.diadmin.config.s3.bucketPrefix -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
admin azure loadbalancer ip
*/}}
{{- define "admin.azure_loadbalancer_ip" -}}
{{- if and (eq (lower .Values.global.cluster.k8sProvider) "azure") (not (empty .Values.global.loadBalancer.ip)) -}}
	{{- printf "loadBalancerIP: \"%s\"" .Values.global.loadBalancer.ip -}}
  {{- end -}}
{{- end -}}

{{/*
 admin cloud loadbalancer source ranges
*/}}
{{- define "admin.cloud_loadbalancer_source_range" -}}
{{- if and (eq (include  "admin.is_cloud_deployment" . ) "true") (not (empty .Values.global.loadBalancer.sourceRanges)) -}}
{{ printf "loadBalancerSourceRanges:" }}
{{- with .Values.global.loadBalancer.sourceRanges }}
{{- toYaml . | nindent 4 }}
{{- end }}
{{- end -}}
{{- end -}}