# UAT

Placeholder for the UAT environment. Layout per cluster and stage:

```
environments/uat/<cluster>/<stage>/<app>/
├── Chart.yaml    # wrapper chart; dependencies[0].version is bumped by Kargo on promotion
└── values.yaml   # Helm values, nested under the dependency's chart name
```

Copy an app folder from `environments/local/minikube/qe/` as a starting point, then add the
environment to the release-templates values with `path: environments/uat/<cluster>/<stage>`.
