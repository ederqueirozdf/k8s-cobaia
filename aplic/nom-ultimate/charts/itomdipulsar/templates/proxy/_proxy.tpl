{{/*
is cloud deployment
*/}}
{{- define "pulsar.is_cloud_deployment" -}}
{{- if or (eq (lower .Values.global.cluster.k8sProvider) "azure") (eq (lower .Values.global.cluster.k8sProvider) "aws") -}}
{{- printf "%t" true -}}
{{- else -}}
{{- printf "%t" false -}}
{{- end -}}
{{- end -}}

{{/*
pulsar service domain
*/}}
{{- define "pulsar.service_domain" -}}
    {{- if eq (include  "pulsar.is_cloud_deployment" . ) "true" -}}
        {{- if and (and .Values.global.di.cloud.externalDNS.enabled (empty .Values.global.loadBalancer.ip)) (not (empty .Values.global.di.cloud.externalAccessHost.pulsar)) -}}
       		{{- printf "external-dns.alpha.kubernetes.io/hostname: \"%s\"" .Values.global.di.cloud.externalAccessHost.pulsar -}}
        {{- end -}}
    {{- else -}}
         {{- print "" -}}
        {{- end -}}
{{- end }}

{{/*
pulsar proxy service type
*/}}
{{- define "pulsar.proxy_service_type" -}}

    {{- if eq (include  "pulsar.is_cloud_deployment" . ) "true" -}}
			{{- print "LoadBalancer" -}}
	{{- else -}}
		{{- if .Values.ingress.proxy.enabled -}}
			{{- print "NodePort" -}}
		{{- else -}}
			{{- printf "%s" .Values.proxy.service.type -}}
		{{- end -}}
	{{- end -}}
{{- end -}}

{{/*
Define proxy token mounts
*/}}
{{- define "pulsar.proxy.token.volumeMounts" -}}
{{- if .Values.auth.authentication.enabled }}
{{- if eq .Values.auth.authentication.provider "jwt" }}
{{- if not .Values.auth.vault.enabled }}
- mountPath: "/pulsar/keys"
  name: token-keys
  readOnly: true
{{- end }}
- mountPath: "/pulsar/tokens"
  name: proxy-token
  readOnly: true
{{- end }}
{{- end }}
{{- end }}

{{/*
Define proxy token volumes
*/}}
{{- define "pulsar.proxy.token.volumes" -}}
{{- if .Values.auth.authentication.enabled }}
{{- if eq .Values.auth.authentication.provider "jwt" }}
{{- if not .Values.auth.vault.enabled }}
- name: token-keys
  secret:
    {{- if not .Values.auth.authentication.jwt.usingSecretKey }}
    secretName: "{{ .Release.Name }}-token-asymmetric-key"
    {{- end}}
    {{- if .Values.auth.authentication.jwt.usingSecretKey }}
    secretName: "{{ .Release.Name }}-token-symmetric-key"
    {{- end}}
    items:
      {{- if .Values.auth.authentication.jwt.usingSecretKey }}
      - key: SECRETKEY
        path: token/secret.key
      {{- else }}
      - key: PUBLICKEY
        path: token/public.key
      {{- end}}
{{- end }}
- name: proxy-token
  secret:
    secretName: "{{ .Release.Name }}-token-{{ .Values.auth.superUsers.proxy }}"
    items:
      - key: TOKEN
        path: proxy/token
{{- end }}
{{- end }}
{{- end }}

{{/*
Define proxy tls certs mounts
*/}}
{{- define "pulsar.proxy.certs.volumeMounts" -}}
{{- if and .Values.tls.enabled (or .Values.tls.proxy.enabled (or .Values.tls.bookie.enabled .Values.tls.zookeeper.enabled)) }}
{{- if or .Values.tls.zookeeper.enabled .Values.components.kop }}
- name: keytool
  mountPath: "/pulsar/keytool/keytool.sh"
  subPath: keytool.sh
{{- end }}
{{- end }}
{{- end }}

{{/*
Define proxy tls certs volumes
*/}}
{{- define "pulsar.proxy.certs.volumes" -}}
{{- if and .Values.tls.enabled (or .Values.tls.proxy.enabled (or .Values.tls.bookie.enabled .Values.tls.zookeeper.enabled)) }}
{{- if or .Values.tls.zookeeper.enabled .Values.components.kop }}
- name: keytool
  configMap:
    name: "{{ template "pulsar.fullname" . }}-keytool-configmap"
    defaultMode: 0755
{{- end }}
{{- end }}
{{- end }}

{{/*
Define proxy log mounts
*/}}
{{- define "pulsar.proxy.log.volumeMounts" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.proxy.component }}-log4j2"
  mountPath: "{{ template "pulsar.home" . }}/conf/log4j2.yaml"
  subPath: log4j2.yaml
{{- end }}

{{/*
Define proxy log volumes
*/}}
{{- define "pulsar.proxy.log.volumes" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.proxy.component }}-log4j2"
  configMap:
    name: "{{ template "pulsar.fullname" . }}-{{ .Values.proxy.component }}"
{{- end }}
{{/*


{{/*
pulsar ingress target port for http endpoint
*/}}
{{- define "pulsar.proxy.ingress.targetPort.admin" -}}
{{- if and .Values.tls.enabled .Values.tls.proxy.enabled }}
{{- print "https" -}}
{{- else -}}
{{- print "http" -}}
{{- end -}}
{{- end -}}

{{/*
pulsar ingress target port for http endpoint
*/}}
{{- define "pulsar.proxy.ingress.targetPort.data" -}}
{{- if and .Values.tls.enabled .Values.tls.proxy.enabled }}
{{- print "pulsarssl" -}}
{{- else -}}
{{- print "pulsar" -}}
{{- end -}}
{{- end -}}

{{/*
Pulsar Broker Service URL
*/}}
{{- define "pulsar.proxy.broker.service.url" -}}
{{- if .Values.proxy.brokerServiceURL -}}
{{- .Values.proxy.brokerServiceURL -}}
{{- else -}}
pulsar://{{ template "pulsar.fullname" . }}-{{ .Values.broker.component }}:{{ .Values.broker.ports.pulsar }}
{{- end -}}
{{- end -}}

{{/*
Pulsar Web Service URL
*/}}
{{- define "pulsar.proxy.web.service.url" -}}
{{- if .Values.proxy.brokerWebServiceURL -}}
{{- .Values.proxy.brokerWebServiceURL -}}
{{- else -}}
http://{{ template "pulsar.fullname" . }}-{{ .Values.broker.component }}:{{ .Values.broker.ports.http }}
{{- end -}}
{{- end -}}

{{/*
Pulsar Broker Service URL TLS
*/}}
{{- define "pulsar.proxy.broker.service.url.tls" -}}
{{- if .Values.proxy.brokerServiceURLTLS -}}
{{- .Values.proxy.brokerServiceURLTLS -}}
{{- else -}}
pulsar+ssl://{{ template "pulsar.fullname" . }}-{{ .Values.broker.component }}:{{ .Values.broker.ports.pulsarssl }}
{{- end -}}
{{- end -}}

{{/*
Pulsar Web Service URL
*/}}
{{- define "pulsar.proxy.web.service.url.tls" -}}
{{- if .Values.proxy.brokerWebServiceURLTLS -}}
{{- .Values.proxy.brokerWebServiceURLTLS -}}
{{- else -}}
https://{{ template "pulsar.fullname" . }}-{{ .Values.broker.component }}:{{ .Values.broker.ports.https }}
{{- end -}}
{{- end -}}

{{/*
Define Proxy probe
*/}}
{{- define "pulsar.proxy.probe" -}}
httpGet:
  path: /status.html
  {{- if and .Values.tls.enabled .Values.tls.proxy.enabled }}
  port: {{ .Values.proxy.ports.https }}
  scheme: HTTPS
  {{- else}}
  port: {{ .Values.proxy.ports.http }}
  scheme: HTTP
  {{- end}}
{{- end }}



{{/*
pulsar proxy azure loadbalancer ip
*/}}
{{- define "pulsar.proxy.azure_loadbalancer_ip" -}}
{{- if and (eq (lower .Values.global.cluster.k8sProvider) "azure") (not (empty .Values.global.loadBalancer.ip)) -}}
	{{- printf "loadBalancerIP: \"%s\"" .Values.global.loadBalancer.ip -}}
  {{- end -}}
{{- end -}}

{{/*
 pulsar proxy cloud loadbalancer source ranges
*/}}
{{- define "pulsar.proxy.cloud_loadbalancer_source_range" -}}
{{- if and (eq (include  "pulsar.is_cloud_deployment" . ) "true") (not (empty .Values.global.loadBalancer.sourceRanges)) -}}
{{ printf "loadBalancerSourceRanges:" }}
{{- with .Values.global.loadBalancer.sourceRanges }}
{{- toYaml . | nindent 4 }}
{{- end }}
{{- end -}}
{{- end -}}