{{- define "kubetemplates.annotations" }}
{{- if or (.annotations) (.helm_sh_annotations) }}
annotations:
{{- if .annotations }}
{{- toYaml .annotations | nindent 2 }}
{{- end }}
{{- if .helm_sh_annotations }}
{{- if .helm_sh_annotations.helm_sh_hook }}
  "helm.sh/hook": {{ .helm_sh_annotations.helm_sh_hook }}
{{- end }}
{{- if .helm_sh_annotations.helm_sh_hook_weight }}
  "helm.sh/hook-weight": {{ .helm_sh_annotations.helm_sh_hook_weight | quote }}
{{- end }}
{{- if .helm_sh_annotations.helm_sh_hook_delete_policy }}
  "helm.sh/hook-delete-policy": {{ .helm_sh_annotations.helm_sh_hook_delete_policy }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}


{{- define "kubernetes.core.handler" }}
{{- if .exec }}
exec:
{{- include "kubernetes.core.execaction" .exec | nindent 2 }}
{{- end }}
{{- if .httpGet }}
httpGet:
{{- include "kubernetes.core.httpgetaction" .httpGet | nindent 2 }}
{{- end }}
{{- if .tcpSocket }}
tcpSocket:
{{- include "kubernetes.core.tcpsocketaction" .tcpsocket | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.lifecycle" }}
{{- if .postStart }}
postStart:
{{- include "kubernetes.core.handler" .postStart | nindent 2 }}
{{- end }}
{{- if .preStop }}
preStop:
{{- include "kubernetes.core.handler" .preStop | nindent 2 }}
{{- end }}
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
{{- end }}
{{- if .limits }}
limits:
  memory: {{ .limits.memory | default "1024Mi" }}
  cpu: {{ .limits.cpu | default "1000m" }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.tcpsocketaction" -}}
port: {{ .port }}
{{- if .host -}}
host: {{ .host }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.execaction" -}}
command: {{ .command }}
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
{{- if .exec -}}
exec:
{{- include "kubernetes.core.execaction" .exec | nindent 2 }}
{{- end }}
{{- if .tcpSocket -}}
tcpSocket:
{{- include "kubernetes.core.tcpsocketaction" .tcpSocket | nindent 2 }}
{{- end }}
initialDelaySeconds: {{ .initialDelaySeconds | default 1 }}
periodSeconds: {{ .periodSeconds | default 1 }}
timeoutSeconds: {{ .timeoutSeconds | default 1 }}
successThreshold: {{ .successThreshold | default 1 }}
failureThreshold: {{ .failureThreshold | default 3 }}
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

{{- define "kubernetes.core.fieldrefkeyselector" -}}
fieldPath: {{ .fieldPath }}
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
{{- if .fieldRef -}}
fieldRef:
{{- include "kubernetes.core.fieldrefkeyselector" .fieldRef | nindent 4 }}
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

{{- define "kubernetes.core.configmapenvsource" -}}
name: {{ .name }}
{{- if .optional }}
optional: {{ .optional }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.secretenvsource" -}}
name: {{ .name }}
{{- if .optional }}
optional: {{ .optional }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.envfromsource" -}}
{{- if .configMapRef -}}
- configMapRef:
{{- include "kubernetes.core.configmapenvsource" .configMapRef | nindent 4 }}
{{- if .secretRef -}}
  secretRef:
{{- include "kubernetes.core.secretenvsource" .secretRef | nindent 4 }}
{{- end }}
{{- else }}
{{- if .secretRef -}}
- secretRef:
{{- include "kubernetes.core.secretenvsource" .secretRef | nindent 4 }}
{{- end }}
{{- end }}
{{- if .optional }}
optional: {{ .optional }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.configmapvolumesource" -}}
name: {{ .name }}
{{- if .optional }}
optional: {{ .optional }}
{{- end }}
{{- if .defaultMode }}
defaultMode: {{ .defaultMode }}
{{- end }}
{{- if .items }}
items: {{ .items }}
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
{{- if .items }}
items: {{ .items }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.volume" -}}
- name: {{ .name }}
{{- if .secret }}
  secret:
{{- include "kubernetes.core.secretvolumesource" .secret | nindent 4 }}
{{- end }}
{{- if .configMap }}
  configMap:
{{- include "kubernetes.core.configmapvolumesource" .configMap | nindent 4 }}
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
{{- if .envFrom }}
  envFrom:
{{- range $key, $value := .envFrom }}
{{- include "kubernetes.core.envfromsource" $value | nindent 4 }}
{{- end }}
{{- end }}

{{- if or .env .envOverrideOne .envOverrideTwo }}
  env:
{{- end }}

{{- if .env }}
{{- range $key, $value := .env }}
{{- include "kubernetes.core.envvar" $value | nindent 4 }}
{{- end }}
{{- end }}

{{- if .envOverrideOne }}
{{- range $key, $value := .envOverrideOne }}
{{- include "kubernetes.core.envvar" $value | nindent 4 }}
{{- end }}
{{- end }}

{{- if .envOverrideTwo }}
{{- range $key, $value := .envOverrideTwo }}
{{- include "kubernetes.core.envvar" $value | nindent 4 }}
{{- end }}
{{- end }}

{{- if .lifecycle }}
  lifecycle:
{{- include "kubernetes.core.lifecycle" .lifecycle | nindent 4}}
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

{{- if .livenessProbe }}
  livenessProbe:
{{- include "kubernetes.core.probe" .livenessProbe | nindent 4 }}
{{- end }}


{{- if .startupProbe }}
  startupProbe:
{{- include "kubernetes.core.probe" .startupProbe | nindent 4 }}
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

{{- define "kubernetes.apps.deploymentstrategy" -}}
{{- if .rollingUpdate }}
rollingUpdate:
  maxSurge: {{ default "25%" .rollingUpdate.maxSurge }}
  maxUnavailable: {{ default "25%" .rollingUpdate.maxUnavailable }}
{{- end -}}
type: {{ default "RollingUpdate" .type }}
{{- end -}}

{{- define "kubernetes.core.toleration" -}}
- effect: {{ .effect }}
  key: {{ .key }}
  operator: {{ .operator }}
{{- if .tolerationSeconds }}
  tolerationSeconds: {{ .tolerationSeconds }}
{{- end }}
  value: {{ .value }}
{{- end -}}

{{- define "kubernetes.core.labelselector" -}}
matchLabels: {{ .matchLabels | toYaml | nindent 2 }}
{{- end }}

{{- define "kubernetes.core.podaffinityterm" -}}
- topologyKey: {{ .topologyKey }}
{{- if .labelSelector }}
  labelSelector:
{{- include "kubernetes.core.labelselector" .labelSelector | nindent 4 }}
{{- end -}}
{{- end -}}

{{- define "kubernetes.core.podantiaffinity" -}}
{{- if .requiredDuringSchedulingIgnoredDuringExecution -}}
  requiredDuringSchedulingIgnoredDuringExecution:
{{- range $value := .requiredDuringSchedulingIgnoredDuringExecution }}
{{- include "kubernetes.core.podaffinityterm" $value | nindent 2}}
{{- end }}
{{- end }}
{{- end -}}

{{- define "kubernetes.core.affinity" -}}
{{- if .podAntiAffinity -}}
  podAntiAffinity:
{{- include "kubernetes.core.podantiaffinity" .podAntiAffinity | nindent 2}}
{{- end }}
{{- end }}

{{- define "kubernetes.core.podspec" -}}
{{- if .nodeSelector }}
nodeSelector:
  {{ .nodeSelector | toYaml }}
{{- end }}
restartPolicy: {{ default "Never" .restartPolicy }}
{{- if.tolerations }}
tolerations:
{{- range $key, $value := .tolerations }}
{{- include "kubernetes.core.toleration" $value | nindent 2 }}
{{- end }}
{{- end }}
{{- if.affinity }}
affinity:
{{- range $key, $value := .affinity }}
{{- include "kubernetes.core.affinity" $value | nindent 2 }}
{{- end }}
{{- end }}
{{- if .serviceAccountName }}
serviceAccountName: {{ .serviceAccountName }}
{{- end }}
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
{{- end -}}
backoffLimit: {{ if kindIs "float64" .backoffLimit }}{{ .backoffLimit }}{{ else }}6{{ end }}
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

{{/*
kubernetes resource definitions start here
*/}}


{{- define "kubernetes.extensions.ingress" -}}
{{- if .Values.ingress.enabled -}}
{{- $ingressPaths := .Values.ingress.paths -}}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ default .Chart.Name .Values.ingress.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default .Chart.Name .Values.ingress.metadata.name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.ingress.metadata.labels }}
{{- toYaml .Values.ingress.metadata.labels | nindent 4 }}
{{- end }}
{{- if .Values.ingress.metadata }}
{{- include "kubetemplates.annotations" .Values.ingress.metadata | nindent 2 }}
{{- end }}
spec:
{{- if .Values.ingress.ingressClassName }}
  ingressClassName: {{ .Values.ingress.ingressClassName | quote }}
{{- end }}
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
          - backend:
            {{- if $value1.backend.service }}
              service:
                name: {{ $value1.backend.service.name }}
                port:
                {{- if $value1.backend.service.port.name }}
                  name: {{ $value1.backend.service.port.name }}
                {{- end }}
                {{- if $value1.backend.service.port.number }}
                  number: {{ $value1.backend.service.port.number }}
                {{- end }}
            {{- end }}
            {{- if $value1.backend.resource }}
              resource:
                apiGroup: {{ $value1.backend.resource.apiGroup }}
                kind: {{ $value1.backend.resource.kind }}
                name: {{ $value1.backend.resource.name }}
            {{- end }}
            {{- if $value1.path }}
            path: {{ $value1.path }}
            {{- end }}
            pathType: {{ $value1.pathType | default "ImplementationSpecific" }}
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
{{- if $value.metadata.labels }}
{{- toYaml $value.metadata.labels | nindent 4 }}
{{- end }}
{{- if $value.metadata }}
{{- include "kubetemplates.annotations" $value.metadata | nindent 2 }}
{{- end }}
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
{{- if $value.metadata.labels }}
{{- toYaml $value.metadata.labels | nindent 4 }}
{{- end }}
{{- if $value.metadata }}
{{- include "kubetemplates.annotations" $value.metadata | nindent 2 }}
{{- end }}
spec:
{{- include "kubernetes.batch.jobspec" .spec | nindent 2 }}
{{- end }}
{{- end -}}


{{- define "kubernetes.batch.cronjob" -}}
{{- range $key, $value := .Values.cronjobs }}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- if $value.metadata.labels }}
{{- toYaml $value.metadata.labels | nindent 4 }}
{{- end }}
{{- if $value.metadata }}
{{- include "kubetemplates.annotations" $value.metadata | nindent 2 }}
{{- end }}
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
{{- if $value.metadata.labels }}
{{- toYaml $value.metadata.labels | nindent 4 }}
{{- end }}
{{- if $value.metadata }}
{{- include "kubetemplates.annotations" $value.metadata | nindent 2 }}
{{- end }}
spec:
  type: {{ default "ClusterIP" $value.type }}
{{- if $value.externalName }}
  externalName: {{ $value.externalName }}
{{- end }}
{{- if $value.ports }}
  ports:
{{- range $key, $value1 := $value.ports }}
{{- include "kubernetes.core.serviceport" $value1 | nindent 4 }}
{{- end }}
{{- end }}
{{- if $value.selector }}
  selector:
    app.kubernetes.io/name: {{ default $.Chart.Name $value.selector.name | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "kubernetes.apps.configmap" -}}
{{- range $key, $value := .Values.configmaps }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- if $value.metadata.labels }}
{{- toYaml $value.metadata.labels | nindent 4 }}
{{- end }}
{{- if $value.metadata }}
{{- include "kubetemplates.annotations" $value.metadata | nindent 2 }}
{{- end }}
data:
{{- range $key1, $value1 := $value.data }}
{{- range $key2, $value2 := $value1 }}
  {{ $value2.name }}: {{ $value2.value }}
{{- end }}
{{- end }}
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
    helm.sh/chart: {{ printf "%s-%s" $.Chart.Name $.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ $.Release.Name }}
    app.kubernetes.io/managed-by: {{ $.Release.Service }}
{{- if $value.metadata.labels }}
{{- toYaml $value.metadata.labels | nindent 4 }}
{{- end }}
{{- if $value.metadata }}
{{- include "kubetemplates.annotations" $value.metadata | nindent 2 }}
{{- end }}
spec:
  replicas: {{ $value.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
      app.kubernetes.io/instance: {{ $.Release.Name }}
  strategy:
{{- include "kubernetes.apps.deploymentstrategy" $value.deploymentStrategy | nindent 4 }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ default $.Chart.Name $value.metadata.name | trunc 63 | trimSuffix "-" }}
        app.kubernetes.io/instance: {{ $.Release.Name }}
{{- if $value.metadata.labels }}
{{- toYaml $value.metadata.labels | nindent 8 }}
{{- end }}
{{- if $value.podAnnotations }}
      annotations:
{{- toYaml $value.podAnnotations | nindent 8 }}
{{- end }}
    spec:
{{- if $value.nodeSelector }}
      nodeSelector:
        {{ $value.nodeSelector | toYaml }}
{{- end -}}
{{- if $value.tolerations }}
      tolerations:
{{- range $key, $value1 := $value.tolerations }}
{{- include "kubernetes.core.toleration" $value1 | nindent 8 }}
{{- end }}
{{- end }}
{{- if $value.affinity }}
      affinity:
{{- include "kubernetes.core.affinity" $value.affinity | nindent 8 }}
{{- end }}
{{- if $value.terminationGracePeriodSeconds }}
      terminationGracePeriodSeconds: {{ $value.terminationGracePeriodSeconds }}
{{- end }}
      restartPolicy: {{ default "Always" .restartPolicy }}
{{- if $value.serviceAccountName }}
      serviceAccountName: {{ $value.serviceAccountName }}
{{- end }}
{{- if $value.initContainers }}
      initContainers:
{{ range $key, $value1 := $value.initContainers }}
{{- include "kubernetes.core.container" $value1 | nindent 8 }}
{{- end }}
{{- end }}
      containers:
{{- range $key, $value1 := $value.containers }}
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


{{- define "kubernetes.core.serviceaccount" -}}
{{- if .Values.serviceaccount.enabled }}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ default .Chart.Name .Values.serviceaccount.metadata.name | trunc 63 | trimSuffix "-" }}
  labels:
    app.kubernetes.io/name: {{ default .Chart.Name .Values.serviceaccount.metadata.name | trunc 63 | trimSuffix "-" }}
    helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
    app.kubernetes.io/instance: {{ .Release.Name }}
    app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.serviceaccount.metadata.labels }}
{{- toYaml .Values.serviceaccount.metadata.labels | nindent 4 }}
{{- end }}
{{- if .Values.serviceaccount.metadata }}
{{- include "kubetemplates.annotations" .Values.serviceaccount.metadata | nindent 2 }}
{{- end }}
{{- end }}
{{- end -}}
