{{- define "ha-nginx.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "ha-nginx.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "ha-nginx.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "ha-nginx.labels" -}}
app.kubernetes.io/name: {{ include "ha-nginx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
