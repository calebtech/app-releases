{{/*
OCI chart repo (no oci:// prefix) for an app in an env.
Precedence: app.chartRepo > env.chartRepo > ECR built from accountID/region/helmEnv/chartPath.
Usage: include "release-templates.chartRepo" (dict "app" $app "env" $env)
*/}}
{{- define "release-templates.chartRepo" -}}
{{- if .app.chartRepo -}}
{{- .app.chartRepo -}}
{{- else if .env.chartRepo -}}
{{- .env.chartRepo -}}
{{- else -}}
{{- printf "%s.dkr.ecr.%s.amazonaws.com/esp/%s/%s" (required "env.accountID is required when chartRepo is not set" .env.accountID) .env.region .env.helmEnv .app.chartPath -}}
{{- end -}}
{{- end }}

{{/*
Namespace the app is deployed into for an env: app.namespace + env.namespaceSuffix.
Set namespaceSuffix when several envs share one cluster (e.g. local minikube).
*/}}
{{- define "release-templates.destNamespace" -}}
{{- printf "%s%s" .app.namespace (.env.namespaceSuffix | default "") -}}
{{- end }}

{{/*
Namespace the Argo CD Application object lives in.
appsInAnyNamespace=true  -> app.namespace (needs Argo CD `application.namespaces` configured)
appsInAnyNamespace=false -> the Argo CD namespace
*/}}
{{- define "release-templates.appNamespace" -}}
{{- if .root.Values.argocd.appsInAnyNamespace -}}
{{- .app.namespace -}}
{{- else -}}
{{- .root.Values.argocd.namespace -}}
{{- end -}}
{{- end }}

{{/*
Unique git repos across environments, as a JSON list.
*/}}
{{- define "release-templates.gitRepos" -}}
{{- $seen := list }}
{{- range $env := .Values.environments }}
{{- $seen = append $seen $env.gitRepo }}
{{- end }}
{{- $seen | uniq | toJson }}
{{- end }}

{{/*
Validation: Kargo requires Stages/Warehouses/PromotionTasks to live in the
namespace named after the Kargo Project (app.name), so app.name must equal app.namespace.
*/}}
{{- define "release-templates.validate" -}}
{{- range $app := .Values.applications }}
{{- if ne $app.name $app.namespace }}
{{- fail (printf "applications[%s]: name (%s) must equal namespace (%s) because the Kargo project namespace is the project name" $app.name $app.name $app.namespace) }}
{{- end }}
{{- end }}
{{- end }}
