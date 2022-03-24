#===========================================================================
# confirmEula()
# This function will confirm that the customer has accepted the EULA, by
# setting "acceptEula=true".  The default will be "false", of course.
# If EULA is not accepted, then deployment of the chart will exit with error.
#
{{- define "helm-lib.confirmEula" -}}
{{- if not (kindIs "bool" .Values.acceptEula) -}}
{{- cat "\n\nERROR: You must accept the Micro Focus EULA by setting acceptEula=true" | fail -}}
{{- else -}}
{{- if .Values.acceptEula -}}
acceptedEULA: {{ .Values.acceptEula | quote }}
{{- else -}}
{{- cat "\n\nERROR: You must accept the Micro Focus EULA by setting acceptEula=true" | fail -}}
{{- end -}}
{{- end -}}
{{- end -}}


#===========================================================================
# injectVar(varName:VARName, Values:Values, Template:Template)
# Enables a global configmap to be defined, in the composition chart, and service
# charts will inherit values from that config map.  If the global.configMap is not
# defined, then the properties become normal "values.yaml" properties.  Example:
#
# injectVar(varName:"foo.bar.env1") expands to equivalent of:
#
#    if (global.configMap) {
#        valueFrom:
#          configMapRef:
#            name: my-configmap     # whatever the value of global.configMap is
#            key: foo.bar.env1
#    } else {
#        value: foo.bar.env1
#    }
# 
{{- define "helm-lib.injectVar" -}}
{{- $varName := .varName -}}
{{- if .Values.global.configMap -}}
valueFrom:
  configMapKeyRef:
{{ cat "    name:" .Values.global.configMap }}
{{ cat "    key:" $varName }}
{{- else -}}
{{- $fullVarName := cat "{{ .Values." .varName " | quote }}" | nospace -}}
{{- $fullVarValue := tpl $fullVarName . }}
{{- cat "value:" $fullVarValue -}}
{{- end -}}
{{- end -}}

#===========================================================================
# apiVersion(kind:kind)
# Get apiVersion according to the provided kind value and based on current kubernetes minor version from 15 to 19.
#
{{- define "helm-lib.apiVersion" -}}
{{- $gvk21 := dict "Binding" "v1" "ComponentStatus" "v1" "ConfigMap" "v1" "Endpoints" "v1" "Event" "v1" "LimitRange" "v1" "Namespace" "v1" "Node" "v1" "PersistentVolumeClaim" "v1" "PersistentVolume" "v1" "Pod" "v1" "PodTemplate" "v1" "ReplicationController" "v1" "ResourceQuota" "v1" "Secret" "v1" "ServiceAccount" "v1" "Service" "v1" "MutatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "CustomResourceDefinition" "apiextensions.k8s.io/v1" "APIService" "apiregistration.k8s.io/v1" "ControllerRevision" "apps/v1" "DaemonSet" "apps/v1" "Deployment" "apps/v1" "ReplicaSet" "apps/v1" "StatefulSet" "apps/v1" "TokenReview" "authentication.k8s.io/v1" "LocalSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectRulesReview" "authorization.k8s.io/v1" "SubjectAccessReview" "authorization.k8s.io/v1" "HorizontalPodAutoscaler" "autoscaling/v1" "CronJob" "batch/v1beta1" "Job" "batch/v1" "CertificateSigningRequest" "certificates.k8s.io/v1" "Lease" "coordination.k8s.io/v1" "EndpointSlice" "discovery.k8s.io/v1beta1" "Ingress" "networking.k8s.io/v1" "FlowSchema" "flowcontrol.apiserver.k8s.io/v1alpha1" "PriorityLevelConfiguration" "flowcontrol.apiserver.k8s.io/v1alpha1" "IngressClass" "networking.k8s.io/v1" "NetworkPolicy" "networking.k8s.io/v1" "RuntimeClass" "node.k8s.io/v1beta1" "PodDisruptionBudget" "policy/v1" "PodSecurityPolicy" "policy/v1beta1" "ClusterRoleBinding" "rbac.authorization.k8s.io/v1" "ClusterRole" "rbac.authorization.k8s.io/v1" "RoleBinding" "rbac.authorization.k8s.io/v1" "Role" "rbac.authorization.k8s.io/v1" "PriorityClass" "scheduling.k8s.io/v1" "CSIDriver" "storage.k8s.io/v1" "CSINode" "storage.k8s.io/v1" "StorageClass" "storage.k8s.io/v1" "VolumeAttachment" "storage.k8s.io/v1" -}}
{{- $gvk19 := dict "Binding" "v1" "ComponentStatus" "v1" "ConfigMap" "v1" "Endpoints" "v1" "Event" "v1" "LimitRange" "v1" "Namespace" "v1" "Node" "v1" "PersistentVolumeClaim" "v1" "PersistentVolume" "v1" "Pod" "v1" "PodTemplate" "v1" "ReplicationController" "v1" "ResourceQuota" "v1" "Secret" "v1" "ServiceAccount" "v1" "Service" "v1" "MutatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "CustomResourceDefinition" "apiextensions.k8s.io/v1" "APIService" "apiregistration.k8s.io/v1" "ControllerRevision" "apps/v1" "DaemonSet" "apps/v1" "Deployment" "apps/v1" "ReplicaSet" "apps/v1" "StatefulSet" "apps/v1" "TokenReview" "authentication.k8s.io/v1" "LocalSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectRulesReview" "authorization.k8s.io/v1" "SubjectAccessReview" "authorization.k8s.io/v1" "HorizontalPodAutoscaler" "autoscaling/v1" "CronJob" "batch/v1beta1" "Job" "batch/v1" "CertificateSigningRequest" "certificates.k8s.io/v1" "Lease" "coordination.k8s.io/v1" "EndpointSlice" "discovery.k8s.io/v1beta1" "Ingress" "networking.k8s.io/v1" "FlowSchema" "flowcontrol.apiserver.k8s.io/v1alpha1" "PriorityLevelConfiguration" "flowcontrol.apiserver.k8s.io/v1alpha1" "IngressClass" "networking.k8s.io/v1" "NetworkPolicy" "networking.k8s.io/v1" "RuntimeClass" "node.k8s.io/v1beta1" "PodDisruptionBudget" "policy/v1beta1" "PodSecurityPolicy" "policy/v1beta1" "ClusterRoleBinding" "rbac.authorization.k8s.io/v1" "ClusterRole" "rbac.authorization.k8s.io/v1" "RoleBinding" "rbac.authorization.k8s.io/v1" "Role" "rbac.authorization.k8s.io/v1" "PriorityClass" "scheduling.k8s.io/v1" "CSIDriver" "storage.k8s.io/v1" "CSINode" "storage.k8s.io/v1" "StorageClass" "storage.k8s.io/v1" "VolumeAttachment" "storage.k8s.io/v1" -}}
{{- $gvk18 := dict "Binding" "v1" "ComponentStatus" "v1" "ConfigMap" "v1" "Endpoints" "v1" "Event" "v1" "LimitRange" "v1" "Namespace" "v1" "Node" "v1" "PersistentVolumeClaim" "v1" "PersistentVolume" "v1" "Pod" "v1" "PodTemplate" "v1" "ReplicationController" "v1" "ResourceQuota" "v1" "Secret" "v1" "ServiceAccount" "v1" "Service" "v1" "MutatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "CustomResourceDefinition" "apiextensions.k8s.io/v1" "APIService" "apiregistration.k8s.io/v1" "ControllerRevision" "apps/v1" "DaemonSet" "apps/v1" "Deployment" "apps/v1" "ReplicaSet" "apps/v1" "StatefulSet" "apps/v1" "TokenReview" "authentication.k8s.io/v1" "LocalSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectRulesReview" "authorization.k8s.io/v1" "SubjectAccessReview" "authorization.k8s.io/v1" "HorizontalPodAutoscaler" "autoscaling/v1" "CronJob" "batch/v1beta1" "Job" "batch/v1" "CertificateSigningRequest" "certificates.k8s.io/v1beta1" "Lease" "coordination.k8s.io/v1beta1" "EndpointSlice" "discovery.k8s.io/v1beta1" "Ingress" "networking.k8s.io/v1beta1" "FlowSchema" "flowcontrol.apiserver.k8s.io/v1alpha1" "PriorityLevelConfiguration" "flowcontrol.apiserver.k8s.io/v1alpha1" "IngressClass" "networking.k8s.io/v1beta1" "NetworkPolicy" "networking.k8s.io/v1" "RuntimeClass" "node.k8s.io/v1beta1" "PodDisruptionBudget" "policy/v1beta1" "PodSecurityPolicy" "policy/v1beta1" "ClusterRoleBinding" "rbac.authorization.k8s.io/v1" "ClusterRole" "rbac.authorization.k8s.io/v1" "RoleBinding" "rbac.authorization.k8s.io/v1" "Role" "rbac.authorization.k8s.io/v1" "PriorityClass" "scheduling.k8s.io/v1" "CSIDriver" "storage.k8s.io/v1" "CSINode" "storage.k8s.io/v1" "StorageClass" "storage.k8s.io/v1" "VolumeAttachment" "storage.k8s.io/v1" -}}
{{- $gvk17 := dict "Binding" "v1" "ComponentStatus" "v1" "ConfigMap" "v1" "Endpoints" "v1" "Event" "v1" "LimitRange" "v1" "Namespace" "v1" "Node" "v1" "PersistentVolumeClaim" "v1" "PersistentVolume" "v1" "Pod" "v1" "PodTemplate" "v1" "ReplicationController" "v1" "ResourceQuota" "v1" "Secret" "v1" "ServiceAccount" "v1" "Service" "v1" "MutatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "CustomResourceDefinition" "apiextensions.k8s.io/v1" "APIService" "apiregistration.k8s.io/v1" "ControllerRevision" "apps/v1" "DaemonSet" "apps/v1" "Deployment" "apps/v1" "ReplicaSet" "apps/v1" "StatefulSet" "apps/v1" "TokenReview" "authentication.k8s.io/v1" "LocalSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectRulesReview" "authorization.k8s.io/v1" "SubjectAccessReview" "authorization.k8s.io/v1" "HorizontalPodAutoscaler" "autoscaling/v1" "CronJob" "batch/v1beta1" "Job" "batch/v1" "CertificateSigningRequest" "certificates.k8s.io/v1beta1" "Lease" "coordination.k8s.io/v1beta1" "EndpointSlice" "discovery.k8s.io/v1beta1" "Ingress" "networking.k8s.io/v1beta1" "FlowSchema" "flowcontrol.apiserver.k8s.io/v1alpha1" "PriorityLevelConfiguration" "flowcontrol.apiserver.k8s.io/v1alpha1" "NetworkPolicy" "networking.k8s.io/v1" "RuntimeClass" "node.k8s.io/v1beta1" "PodDisruptionBudget" "policy/v1beta1" "PodSecurityPolicy" "policy/v1beta1" "ClusterRoleBinding" "rbac.authorization.k8s.io/v1" "ClusterRole" "rbac.authorization.k8s.io/v1" "RoleBinding" "rbac.authorization.k8s.io/v1" "Role" "rbac.authorization.k8s.io/v1" "PriorityClass" "scheduling.k8s.io/v1" "CSIDriver" "storage.k8s.io/v1beta1" "CSINode" "storage.k8s.io/v1" "StorageClass" "storage.k8s.io/v1" "VolumeAttachment" "storage.k8s.io/v1" -}}
{{- $gvk16 := dict "Binding" "v1" "ComponentStatus" "v1" "ConfigMap" "v1" "Endpoints" "v1" "Event" "v1" "LimitRange" "v1" "Namespace" "v1" "Node" "v1" "PersistentVolumeClaim" "v1" "PersistentVolume" "v1" "Pod" "v1" "PodTemplate" "v1" "ReplicationController" "v1" "ResourceQuota" "v1" "Secret" "v1" "ServiceAccount" "v1" "Service" "v1" "MutatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io/v1" "CustomResourceDefinition" "apiextensions.k8s.io/v1" "APIService" "apiregistration.k8s.io/v1" "ControllerRevision" "apps/v1" "DaemonSet" "apps/v1" "Deployment" "apps/v1" "ReplicaSet" "apps/v1" "StatefulSet" "apps/v1" "TokenReview" "authentication.k8s.io/v1" "LocalSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectRulesReview" "authorization.k8s.io/v1" "SubjectAccessReview" "authorization.k8s.io/v1" "HorizontalPodAutoscaler" "autoscaling/v1" "CronJob" "batch/v1beta1" "Job" "batch/v1" "CertificateSigningRequest" "certificates.k8s.io/v1beta1" "Lease" "coordination.k8s.io/v1" "EndpointSlice" "discovery.k8s.io/v1alpha1" "Ingress" "networking.k8s.io/v1beta1" "NetworkPolicy" "networking.k8s.io/v1" "RuntimeClass" "node.k8s.io/v1beta1" "PodDisruptionBudget" "policy/v1beta1" "PodSecurityPolicy" "policy/v1beta1" "ClusterRoleBinding" "rbac.authorization.k8s.io/v1" "ClusterRole" "rbac.authorization.k8s.io/v1" "RoleBinding" "rbac.authorization.k8s.io/v1" "Role" "rbac.authorization.k8s.io/v1" "PriorityClass" "scheduling.k8s.io/v1" "CSIDriver" "storage.k8s.io/v1beta1" "CSINode" "storage.k8s.io/v1beta1" "StorageClass" "storage.k8s.io/v1" "VolumeAttachment" "storage.k8s.io/v1" -}}
{{- $gvk15 := dict "Binding" "v1" "ComponentStatus" "v1" "ConfigMap" "v1" "Endpoints" "v1" "Event" "v1" "LimitRange" "v1" "Namespace" "v1" "Node" "v1" "PersistentVolumeClaim" "v1" "PersistentVolume" "v1" "Pod" "v1" "PodTemplate" "v1" "ReplicationController" "v1" "ResourceQuota" "v1" "Secret" "v1" "ServiceAccount" "v1" "Service" "v1" "MutatingWebhookConfiguration" "admissionregistration.k8s.io/v1beta1" "ValidatingWebhookConfiguration" "admissionregistration.k8s.io/v1beta1" "CustomResourceDefinition" "apiextensions.k8s.io/v1beta1" "APIService" "apiregistration.k8s.io/v1" "ControllerRevision" "apps/v1" "DaemonSet" "apps/v1" "Deployment" "apps/v1" "ReplicaSet" "apps/v1" "StatefulSet" "apps/v1" "TokenReview" "authentication.k8s.io/v1" "LocalSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectAccessReview" "authorization.k8s.io/v1" "SelfSubjectRulesReview" "authorization.k8s.io/v1" "SubjectAccessReview" "authorization.k8s.io/v1" "HorizontalPodAutoscaler" "autoscaling/v1" "CronJob" "batch/v1beta1" "Job" "batch/v1" "CertificateSigningRequest" "certificates.k8s.io/v1beta1" "Lease" "coordination.k8s.io/v1" "Ingress" "networking.k8s.io/v1beta1" "NetworkPolicy" "networking.k8s.io/v1" "RuntimeClass" "node.k8s.io/v1beta1" "PodDisruptionBudget" "policy/v1beta1" "PodSecurityPolicy" "policy/v1beta1" "ClusterRoleBinding" "rbac.authorization.k8s.io/v1" "ClusterRole" "rbac.authorization.k8s.io/v1" "RoleBinding" "rbac.authorization.k8s.io/v1" "Role" "rbac.authorization.k8s.io/v1" "PriorityClass" "scheduling.k8s.io/v1" "CSIDriver" "storage.k8s.io/v1beta1" "CSINode" "storage.k8s.io/v1beta1" "StorageClass" "storage.k8s.io/v1" "VolumeAttachment" "storage.k8s.io/v1" -}}
{{- if ge .Capabilities.KubeVersion.Minor "21" -}}
{{ get $gvk21 .kind }}
{{- else if ge .Capabilities.KubeVersion.Minor "19" -}}
{{ get $gvk19 .kind }}
{{- else if eq .Capabilities.KubeVersion.Minor "18" -}}
{{ get $gvk18 .kind }}
{{- else if eq .Capabilities.KubeVersion.Minor "17" -}}
{{ get $gvk17 .kind }}
{{- else if eq .Capabilities.KubeVersion.Minor "16" -}}
{{ get $gvk16 .kind }}
{{- else if le .Capabilities.KubeVersion.Minor "15" -}}
{{ get $gvk15 .kind }}
{{- end -}}
{{- end -}}

#===========================================================================
# getObjectName(name:name, Release:Release, Values:Values)
# This macro can generate the objectName follow the rules as below.
#
# The objectName consists of namePrefix and name:
# 1. All names (service name, deployment name, config map name, etc.) will be prefixed as per following rules:
# if `.Values.namePrefix` is injected, then use that.
# else if `.Values.backwardsCompat` flag is true, prefix with Helm Release.Name, as per previous releases.
# else prefix with "itom", since we want to STOP (i.e. deprecate) using Helm Release.Name in service names.
# 2. Pass the name in via "name".
#
# Here is an example of the call:
#
# apiVersion: apps/v1
# kind: Deployment
# metadata:
#   name: {{ include "helm-lib.getObjectName" (dict "name" "nginx-ingress" "Release" .Release "Values" .Values ) }}
#
{{- define "helm-lib.getObjectName" -}}
{{- $name := .name -}}
{{- if and (not .Values.namePrefix) .Values.backwardsCompatServiceName -}}
{{- printf "%s-itom-%s" .Release.Name $name | trunc 63  | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (default "itom" .Values.namePrefix) $name | trunc 63  | trimSuffix "-" -}}
{{- end -}}
{{- end -}}