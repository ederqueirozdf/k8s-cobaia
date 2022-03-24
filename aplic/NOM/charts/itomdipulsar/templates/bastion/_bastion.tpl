{{/*
Define the pulsar bastion service
*/}}
{{- define "pulsar.bastion.service" -}}
{{ template "pulsar.fullname" . }}-{{ .Values.bastion.component }}
{{- end }}

{{/*
Define the bastion hostname
*/}}
{{- define "pulsar.bastion.hostname" -}}
${HOSTNAME}.{{ template "pulsar.bastion.service" . }}.{{ .Release.Namespace }}.svc.cluster.local
{{- end -}}

{{/*
Define bastion zookeeper client tls settings
*/}}
{{- define "pulsar.bastion.zookeeper.tls.settings" -}}
{{- if and .Values.tls.enabled (or .Values.tls.zookeeper.enabled (and .Values.tls.broker.enabled .Values.components.kop)) }}
/pulsar/keytool/keytool.sh bastion {{ template "pulsar.bastion.hostname" . }} true;
{{- end -}}
{{- end }}

{{/*
Define bastion kafka settings
*/}}
{{- define "pulsar.bastion.kafka.settings" -}}
{{- if and .Values.tls.enabled (and .Values.tls.broker.enabled .Values.components.kop) }}
cp conf/kafka.properties.template conf/kafka.properties;
echo "ssl.truststore.password=$(cat conf/password)" >> conf/kafka.properties;
{{- if and .Values.auth.authentication.enabled (eq .Values.auth.authentication.provider "jwt") }}
echo "sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \\" >> conf/kafka.properties;
echo '  username="public/default" \' >> conf/kafka.properties;
echo "  password=\"token:$(cat /pulsar/tokens/client/token)\";" >> conf/kafka.properties;
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Define bastion token mounts
*/}}
{{- define "pulsar.bastion.token.volumeMounts" -}}
{{- if .Values.auth.authentication.enabled }}
{{- if eq .Values.auth.authentication.provider "jwt" }}
- mountPath: "/pulsar/tokens"
  name: client-token
  readOnly: true
{{- end }}
{{- end }}
{{- end }}

{{/*
Define bastion token volumes
*/}}
{{- define "pulsar.bastion.token.volumes" -}}
{{- if .Values.auth.authentication.enabled }}
{{- if eq .Values.auth.authentication.provider "jwt" }}
- name: client-token
  secret:
    secretName: "{{ .Release.Name }}-token-{{ .Values.auth.superUsers.client }}"
    items:
      - key: TOKEN
        path: client/token
{{- end }}
{{- end }}
{{- end }}

{{/*
Define bastion tls certs mounts
*/}}
{{- define "pulsar.bastion.certs.volumeMounts" -}}
{{- if and .Values.tls.enabled (or .Values.tls.zookeeper.enabled .Values.tls.broker.enabled) }}
{{- if or .Values.tls.zookeeper.enabled (and .Values.tls.broker.enabled .Values.components.kop) }}
- name: keytool
  mountPath: "/pulsar/keytool/keytool.sh"
  subPath: keytool.sh
{{- end }}
{{- end }}
{{- if and .Values.tls.enabled (or .Values.tls.broker.enabled .Values.tls.proxy.enabled) }}
{{- end }}
{{- end }}

{{/*
Define bastion tls certs volumes
*/}}
{{- define "pulsar.bastion.certs.volumes" -}}
{{- if and .Values.tls.enabled (or .Values.tls.zookeeper.enabled .Values.tls.broker.enabled) }}
{{- if or .Values.tls.zookeeper.enabled (and .Values.tls.broker.enabled .Values.components.kop) }}
- name: keytool
  configMap:
    name: "{{ template "pulsar.fullname" . }}-keytool-configmap"
    defaultMode: 0755
{{- end }}
{{- end }}
{{- end }}

{{/*
Define bastion log mounts
*/}}
{{- define "pulsar.bastion.log.volumeMounts" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.bastion.component }}-log4j2"
  mountPath: "{{ template "pulsar.home" . }}/conf/log4j2.yaml"
  subPath: log4j2.yaml
{{- end }}

{{/*
Define bastion log volumes
*/}}
{{- define "pulsar.bastion.log.volumes" -}}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.bastion.component }}-log4j2"
  configMap:
    name: "{{ template "pulsar.fullname" . }}-{{ .Values.bastion.component }}"
{{- end }}

{{/*
Define bastion kafka conf mounts
*/}}
{{- define "pulsar.bastion.kafka.conf.volumeMounts" -}}
{{- if and .Values.tls.broker.enabled .Values.components.kop }}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.bastion.component }}-kafka-conf"
  mountPath: "{{ template "pulsar.home" . }}/conf/kafka.properties.template"
  subPath: kafka.properties
{{- end }}
{{- end }}

{{/*
Define bastion log volumes
*/}}
{{- define "pulsar.bastion.kafka.conf.volumes" -}}
{{- if and .Values.tls.broker.enabled .Values.components.kop }}
- name: "{{ template "pulsar.fullname" . }}-{{ .Values.bastion.component }}-kafka-conf"
  configMap:
    name: "{{ template "pulsar.fullname" . }}-{{ .Values.bastion.component }}"
{{- end }}
{{- end }}
