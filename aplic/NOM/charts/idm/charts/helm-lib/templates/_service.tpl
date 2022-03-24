#===========================================================================
# internalLBAnnotations()
# https://kubernetes.io/docs/concepts/services-networking/service/#internal-load-balancer
#
{{- define "helm-lib.service.internalLBAnnotations" -}}
{{- $provider := "" }}
{{- if .Values.global.cluster }}
  {{- if .Values.global.cluster.k8sProvider }}
    {{- $provider = .Values.global.cluster.k8sProvider }}
  {{- end }}
{{- end }}
{{- if and ( .Values.global.k8sProvider) (not $provider) }}
  {{- $provider = .Values.global.k8sProvider }}
{{- end }}
{{- if eq $provider "aws" }}
service.beta.kubernetes.io/aws-load-balancer-internal: "true"
{{- else if eq $provider "azure" }}
service.beta.kubernetes.io/azure-load-balancer-internal: "true"
{{- else if eq $provider "alicloud" }}
service.beta.kubernetes.io/alibaba-cloud-loadbalancer-address-type: "intranet"
{{- else if eq $provider "gcp" }}
cloud.google.com/load-balancer-type: "Internal"
{{- else if eq $provider "oci" }}
service.beta.kubernetes.io/oci-load-balancer-internal: "true"
{{- else if eq $provider "openshift" }}
service.beta.kubernetes.io/openstack-internal-load-balancer: "true"
{{- else if eq $provider "none" }}
{{- end }}
{{- end -}}