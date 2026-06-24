{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "portainer-run.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "portainer-run.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "portainer-run.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "portainer-run.labels" -}}
helm.sh/chart: {{ include "portainer-run.chart" . }}
{{ include "portainer-run.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "portainer-run.selectorLabels" -}}
app.kubernetes.io/name: {{ include "portainer-run.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Name of the Secret holding sensitive values.
*/}}
{{- define "portainer-run.secretName" -}}
{{- if .Values.secret.existingSecret -}}
{{- .Values.secret.existingSecret -}}
{{- else -}}
{{- printf "%s-secret" (include "portainer-run.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Name of the ConfigMap holding non-sensitive configuration.
*/}}
{{- define "portainer-run.configMapName" -}}
{{- printf "%s-config" (include "portainer-run.fullname" .) -}}
{{- end -}}

{{/*
Resolve the ENCRYPTION_KEY for the managed Secret.
Precedence: explicit value -> existing Secret's value (preserved on upgrade)
-> a freshly generated 64-char hex key (equivalent to `openssl rand -hex 32`).
The lookup keeps the key stable across upgrades; rotating it would make the
existing Portainer-Run database unreadable.
*/}}
{{- define "portainer-run.encryptionKey" -}}
{{- if .Values.secret.encryptionKey -}}
{{- .Values.secret.encryptionKey -}}
{{- else -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "portainer-run.secretName" .) -}}
{{- if and $existing $existing.data.ENCRYPTION_KEY -}}
{{- $existing.data.ENCRYPTION_KEY | b64dec -}}
{{- else -}}
{{- printf "%s%s" (randAlphaNum 32 | lower) (randAlphaNum 32 | lower) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Name of the PersistentVolumeClaim to use for the cache volume.
*/}}
{{- define "portainer-run.pvcName" -}}
{{- if .Values.persistence.existingClaim -}}
{{- .Values.persistence.existingClaim -}}
{{- else -}}
{{- printf "%s-cache" (include "portainer-run.fullname" .) -}}
{{- end -}}
{{- end -}}
