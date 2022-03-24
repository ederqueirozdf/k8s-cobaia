{{/* vim: set filetype=mustache: */}}
{{/*
gen-certs Kubernetes Job spec
*/}}
{{- define "gencerts.job.spec" -}}
spec:
  ttlSecondsAfterFinished: 1200
  template:
    metadata:
      annotations:
        {{- if .Values.global.vaultAppRole }}
        pod.boostport.com/vault-approle: {{ .Release.Namespace }}-{{ .Values.global.vaultAppRole }}
        {{- else }}
        pod.boostport.com/vault-approle: {{ .Release.Namespace }}-default
        {{- end }}
        pod.boostport.com/vault-init-container: generate-certificates
      labels:
        app.kubernetes.io/name: "{{ template "monitoring.fullname" . }}-{{ .Values.monitoring.gencerts.component }}"
        {{- include "monitoring.standardLabels" . | nindent 8 }}
    spec:
      restartPolicy: OnFailure
      serviceAccount: {{ template "monitoring.fullname" . }}-{{ .Values.monitoring.gencerts.component }}-sa
      serviceAccountName: {{ template "monitoring.fullname" . }}-{{ .Values.monitoring.gencerts.component }}-sa
      securityContext:
        runAsNonRoot: true
        runAsUser: {{ .Values.global.securityContext.user }}
        runAsGroup: {{ .Values.global.securityContext.fsGroup }}
      initContainers:
      - name: generate-certificates
      {{- if and .Values.global.vaultInit.registry .Values.global.vaultInit.orgName }}
        image: {{ .Values.global.vaultInit.registry }}/{{ .Values.global.vaultInit.orgName }}/{{ .Values.global.vaultInit.image }}:{{ .Values.global.vaultInit.imageTag }}
      {{- else}}
        image: {{ .Values.global.docker.registry }}/{{ .Values.global.docker.orgName }}/{{ .Values.global.vaultInit.image }}:{{ .Values.global.vaultInit.imageTag }}
      {{- end}}
        imagePullPolicy: {{ .Values.global.docker.imagePullPolicy }}
        env:
          - name: CERT_COMMON_NAME
            value: "{{ template "monitoring.fullname" . }}-{{ .Values.monitoring.gencerts.component }}"
        volumeMounts:
        - name: vault-token
          mountPath: /var/run/secrets/boostport.com
      containers:
      - name: {{ template "monitoring.fullname" . }}-{{ .Values.monitoring.gencerts.component }}
      {{- if and .Values.monitoring.gencerts.registry .Values.monitoring.gencerts.orgName }}
        image: {{ .Values.monitoring.gencerts.registry }}/{{ .Values.monitoring.gencerts.orgName }}/{{ .Values.monitoring.gencerts.image }}:{{ .Values.monitoring.gencerts.imageTag }}
      {{- else }}
        image: {{ .Values.global.docker.registry }}/{{ .Values.global.docker.orgName }}/{{ .Values.monitoring.gencerts.image }}:{{ .Values.monitoring.gencerts.imageTag }}
      {{- end }}
        imagePullPolicy: {{ .Values.global.docker.imagePullPolicy }}
        env:
        - name: TLS_CERT_FILE_PATH
          value: "/var/run/secrets/boostport.com/server.crt"
        - name: TLS_KEY_FILE_PATH
          value: "/var/run/secrets/boostport.com/server.key"
        - name: NAMESPACE
          value: {{ .Release.Namespace }}
        - name: SECRET_NAME
          value: {{ .Values.global.prometheus.scrapeCertSecretName }}
        volumeMounts:
        - name: vault-token
          mountPath: /var/run/secrets/boostport.com
      volumes:
      - name: vault-token
        emptyDir: {}
{{- end -}}
