{{- define "kubernetes.meta.objectmeta" -}}
name: {{ default $.Chart.Name .name | trunc 63 | trimSuffix "-" }}
labels:
  app.kubernetes.io/name: {{ default $.Chart.Name .name | trunc 63 | trimSuffix "-" }}
  helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
  app.kubernetes.io/instance: {{ $.Release.Name }}
  app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- end -}}

{{- define "kubernetes.core.containerport" -}}
- name: {{ .name }}
  protocol: {{ .protocol | default "TCP" }}
  containerPort: {{ .containerPort }}
{{- if .hostPort }}
  hostPort: {{ .hostPort }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.resourcerequirements" -}}
{{- if .requests -}}
requests:
  memory: {{ .requests.memory | default "512Mi" }}
  cpu: {{ .requests.cpu | default "500m" }}
{{- else }}
requests:
  memory: 512Mi
  cpu: 500M
{{- end }}
{{- if .limits -}}
limits:
  memory: {{ .limits.memory | default "768Mi" }}
  cpu: {{ .limits.cpu | default "1000m" }}
{{- else }}
requests:
  memory: 786Mi
  cpu: 1000M
{{- end }}
{{- end -}}

{{- define "kubernetes.core.httpgetaction" -}}
path: {{ .path }}
port: {{ .port }}
scheme: {{ .scheme | default "http" }}
{{- end -}}

{{- define "kubernetes.core.probe" -}}
{{- if .httpGet -}}
httpGet:
{{- include "kubernetes.core.httpgetaction" .httpGet | nindent 2 }}
{{- end }}
initialDelaySeconds: {{ .initialDelaySeconds | default 1 }}
periodSeconds: {{ .periodSeconds | default 1 }}
successThreshold: {{ .successThreshold | default 1 }}
timeoutSeconds: {{ .timeoutSeconds | default 1 }}
{{- end -}}

{{- define "kubernetes.core.secretkeyselector" -}}
key: {{ .key }}
name: {{ .name }}
{{- if .optional }}
optional: {{ .optional }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.envvarsource" -}}
{{- if .secretKeyRef -}}
secretKeyRef:
{{- include "kubernetes.core.secretkeyselector" .secretKeyRef | nindent 4 }}  
{{- end }}
{{- end -}}

{{- define "kubernetes.core.envvar" -}}
- name: {{ .name }}
{{- if .value }}
  value: {{ .value | quote }}
{{- end }}
{{- if .valueFrom }}
  valueFrom:
{{- include "kubernetes.core.envvarsource" .valueFrom | nindent 4 }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.container" -}}
- name: {{ .name }}
  image: "{{ .image.repository }}:{{ .image.tag }}"
  imagePullPolicy: {{ .image.pullPolicy | default "Always" }}
{{- if .image.command }}
  command: {{ .image.command }}
{{- end }} 
{{- if .image.args }}
  args: {{ .image.args }}
{{- end }} 
{{- if .env }}
  env:
{{- range $key, $value := .env }}
{{- include "kubernetes.core.envvar" $value | nindent 4 }}
{{- end }}
{{- end }}

{{- if .ports }}
  ports:
{{- range $key, $value := .ports }}
{{- include "kubernetes.core.containerport" $value | nindent 4 }}
{{- end }}
{{- end }}

{{- if .readinessProbe }}
  readinessProbe:
{{- include "kubernetes.core.probe" .readinessProbe | nindent 4 }}
{{- end }}

{{- if .resources }}
  readinessProbe:
{{- include "kubernetes.core.resourcerequirements" .resources | nindent 4 }}
{{- end }}

{{- end }}

{{- define "kubernetes.core.serviceport" -}}
- name: {{ .name }}
{{- if .nodePort }}
  nodePort: {{ .nodePort }}
{{- end }}
  port: {{ .port }}
{{- if .protocol }}
  protocol: {{ .protocol }}
{{- end }}
  targetPort: {{ .targetPort }}
{{- end -}}

{{- define "kubernetes.apps.rollingupdatedeployment" -}}
maxSurge: {{ .maxSurge }}
maxUnavailable: {{ .maxUnavailable }}
{{- end -}}

{{- define "kubernetes.apps.deploymentstrategy" -}}
{{- if .rollingupdatedeployment }}
rollingUpdate:
{{- include "kubernetes.apps.rollingupdatedeployment" .rollingUpdateDeployment | nindent 2 }}
{{- end }}
type: {{ default "RollingUpdate" .type }}
{{- end -}}

{{- define "kubernetes.core.podspec" -}}
restartPolicy: {{ default "Never" .restartPolicy }}
containers:
{{- range $key, $value := .containers }}
{{- include "kubernetes.core.container" $value | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.podtemplatespec" -}}
spec:
{{- include "kubernetes.core.podspec" .spec | nindent 2 }}
{{- end -}}

{{- define "kubernetes.batch.jobspec" -}}
{{- if .activeDeadlineSeconds }}
activeDeadlineSeconds: {{ .activeDeadlineSeconds }}
{{- end }}
{{- if .backoffLimit }}
backoffLimit: {{ .backoffLimit }}
{{- end }}
template:
{{- include "kubernetes.core.podtemplatespec" .template | nindent 2 }}
{{- end -}}

{{- define "kubernetes.batch.jobtemplatespec" -}}
spec:
{{- include "kubernetes.batch.jobspec" .spec | nindent 2 }}
{{- end -}}

{{- define "kubernetes.batch.cronjobspec" -}}
concurrencyPolicy: {{ default "Forbid" .concurrencyPolicy }}
failedJobsHistoryLimit: {{ default 1 .failedJobsHistoryLimit }}
schedule: {{ .schedule }}
startingDeadlineSeconds: {{ default 60 .startingDeadlineSeconds }}
successfulJobsHistoryLimit: {{ default 0 .successfulJobsHistoryLimit }}
suspend: {{ default false .suspend }}
jobTemplate: 
{{- include "kubernetes.batch.jobtemplatespec" .jobTemplate | nindent 2 }}
{{- end -}}

{{- define "kubernetes.extensions.ingress" -}}
{{- if .Values.ingress.enabled -}}
{{- $ingressPaths := .Values.ingress.paths -}}
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: {{ default .Chart.Name .Values.ingress.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ .Chart.Name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.ingress.metadata.annotations }}
  annotations:
{{ toYaml .Values.ingress.metadata.annotations | nindent 4 }}
{{- end }}
spec:
{{- if .Values.ingress.tls }}
  tls:
  {{- range .Values.ingress.tls }}
    - hosts:
      {{- range .hosts }}
        - {{ . | quote }}
      {{- end }}
      secretName: {{ .secretName }}
  {{- end }}
{{- end }}
  rules:
{{- range $key, $value := .Values.ingress.hosts }}
    - host: {{ $value | quote }}
      http:
        paths:
{{- range $key, $value1 := $ingressPaths }}
          - path: {{ $value1.path }}
            backend:
              serviceName: {{ $value1.backend.serviceName }} 
              servicePort: {{ $value1.backend.servicePort }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.secret" -}}
{{- range $key, $value := .Values.secrets }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ $.Chart.Name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
type: Opaque
data:
{{- range $key, $value1 := $value.data -}}
{{- if $value1 }}
  {{ $key }}: {{ $value1 | b64enc | quote }}
{{- else -}}
  {{ $key }}: {{ randAlphaNum 20 | b64enc | quote }}
{{- end }}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kubernetes.batch.cronjob" -}}
{{- range $key, $value := .Values.cronjobs }}
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ $.Chart.Name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
spec:
{{- include "kubernetes.batch.cronjobspec" $value.spec | nindent 2 }}
{{- end }}
{{- end -}}


{{- define "kubernetes.core.service" -}}
{{- range $key, $value := .Values.services }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ $.Chart.Name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- if $value.metadata.annotations }}
  annotations:
{{ toYaml $value.metadata.annotations | nindent 4 }}
{{- end }}
spec:
  type: {{ default "ClusterIP" $value.type }}
{{- if $value.ports }}
  ports:
{{- range $key, $value1 := $value.ports }}
{{- include "kubernetes.core.serviceport" $value1 | nindent 4 }}
{{- end }}
{{- end }}
  selector:
    app.kubernetes.io/name: {{ $.Chart.Name | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
{{- end -}}
{{- end -}}

{{- define "kubernetes.apps.deployment" -}}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
      app.kubernetes.io/instance: {{ .Release.Name }}
  strategy:
{{- include "kubernetes.apps.deploymentstrategy" .strategy | nindent 4 }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
{{- range $key, $value := .Values.containers }}
{{- include "kubernetes.core.container" $value | nindent 8 }}
{{- end }}
{{- end -}}
