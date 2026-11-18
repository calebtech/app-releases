# UAT

Placeholder for the UAT environment. Layout per cluster and stage:

```
environments/uat/<cluster>/<stage>/<app>/
├── version.yaml   # chart version, written by Kargo on promotion
└── values.yaml    # Helm value overrides for this app in this stage
```

Then add the environment to the release-templates values with
`path: environments/uat/<cluster>/<stage>`.
