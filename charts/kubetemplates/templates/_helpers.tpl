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
{{- end }}
{{- if .limits }}
limits:
  memory: {{ .limits.memory | default "1024Mi" }}
  cpu: {{ .limits.cpu | default "1000m" }}
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

{{- define "kubernetes.core.configmapkeyselector" -}}
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
{{- if .configMapKeyRef -}}
configMapKeyRef:
{{- include "kubernetes.core.configmapkeyselector" .configMapKeyRef | nindent 4 }}
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

{{- define "kubernetes.core.secretvolumesource" -}}
secretName: {{ .secretName }}
{{- if .optional }}
optional: {{ .optional }}
{{- end }}
{{- if .defaultMode }}
defaultMode: {{ .defaultMode }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.volume" -}}
- name: {{ .name }}
{{- if .secret }}
  secret:
{{- include "kubernetes.core.secretvolumesource" .secret | nindent 4 }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.volumemount" -}}
- name: {{ .name }}
  mountPath: {{ .mountPath }}
{{- if .readOnly }}
  readOnly: {{ .readOnly }}
{{- end }}
{{- if .mountPropogation }}
  mountPropogation: {{ .mountPropogation }}
{{- end }}
{{- if .subPath }}
  mountPropogation: {{ .subPath }}
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
  args:
{{- range .image.args }}
    - {{ . | quote }}
{{- end }}
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
  resources:
{{- include "kubernetes.core.resourcerequirements" .resources | nindent 4 }}
{{- else }}
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 1024Mi
      cpu: 1000m
{{- end }}

{{- if .volumeMounts }}
  volumeMounts:
{{- range $key, $value := .volumeMounts }}
{{- include "kubernetes.core.volumemount" $value | nindent 4 }}
{{- end }}
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
{{- end -}}
type: {{ default "RollingUpdate" .type }}
{{- end -}}

{{- define "kubernetes.core.podspec" -}}
restartPolicy: {{ default "Never" .restartPolicy }}
containers:
{{- range $key, $value := .containers }}
{{- include "kubernetes.core.container" $value | nindent 2 }}
{{- end }}

{{- if .volumes }}
volumes:
{{- range $key, $value := .volumes }}
{{- include "kubernetes.core.volume" $value | nindent 2 }}
{{- end }}
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
{{- if .parallelism }}
parallelism: {{ .parallelism }}
{{- end }}
{{- if .completions }}
completions: {{ .completions }}
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
schedule: {{ .schedule | quote }}
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
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: {{ default .Chart.Name .Values.ingress.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default .Chart.Name .Values.ingress.metadata.name | trunc 63 | trimSuffix "-" }}
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
{{- range $key, $value := .Values.ingress.rules }}
    - host: {{ $value.host | quote }}
      http:
        paths:
{{- range $key, $value1 := $value.http.paths }}
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
    app.kubernetes.io/name: {{ default .Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
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

{{- define "kubernetes.batch.job" -}}
{{- range $key, $value := .Values.jobs }}
---
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- if or ($value.metadata.annotations) ($value.metadata.helm_sh_annotations) }}
  annotations:
{{- if $value.metadata.annotations }}
{{ toYaml $value.metadata.annotations | nindent 4 }}
{{- end }}
{{- if $value.metadata.helm_sh_annotations }}
{{- if $value.metadata.helm_sh_annotations.helm_sh_hook }}
    "helm.sh/hook": {{ $value.metadata.helm_sh_annotations.helm_sh_hook }}
{{- end }}
{{- if $value.metadata.helm_sh_annotations.helm_sh_hook_weight }}
    "helm.sh/hook-weight": {{ $value.metadata.helm_sh_annotations.helm_sh_hook_weight | quote }}
{{- end }}
{{- if $value.metadata.helm_sh_annotations.helm_sh_hook_delete_policy }}
    "helm.sh/hook-delete-policy": {{ $value.metadata.helm_sh_annotations.helm_sh_hook_delete_policy }}
{{- end }}
{{- end }}
{{- end }}
spec:
{{- include "kubernetes.batch.jobspec" .spec | nindent 2 }}
{{- end }}
{{- end -}}


{{- define "kubernetes.batch.cronjob" -}}
{{- range $key, $value := .Values.cronjobs }}
---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
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
    app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
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
    app.kubernetes.io/name: {{ default $.Chart.Name $value.selector.name | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
{{- end }}
{{- end -}}

{{- define "kubernetes.apps.deployment" -}}
{{- range $key, $value := .Values.deployments }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 65 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
spec:
  replicas: {{ $value.replicaCount | default 1 }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
      app.kubernetes.io/instance: {{ $.Release.Name }}
  strategy:
{{- include "kubernetes.apps.deploymentstrategy" $value.strategy | nindent 4 }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
        app.kubernetes.io/instance: {{ $.Release.Name }}
    spec:
{{- if $value.initContainers }}
      initContainers:
{{ range $key, $value1 := $value.initContainers }}
{{- include "kubernetes.core.container" $value1 | nindent 8 }}
{{- end }}
{{- end }}
      containers:
{{ range $key, $value1 := $value.containers }}
{{- include "kubernetes.core.container" $value1 | nindent 8 }}
{{- end }}
{{- if $value.volumes }}
      volumes:
{{ range $key, $value1 := $value.volumes }}
{{- include "kubernetes.core.volume" $value1 | nindent 8 }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}
