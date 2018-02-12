# Sensu Demo

## Prerequisites

## Demo

### Sensu Backend

Deploy Sensu Backend.

```
kubectl create -f deploy/kube-config/sensu-backend.yaml
```

Configure `sensuctl` to use the built-in "admin" user.

```
sensuctl configure
```

### RBAC

Create "acme" organization.

```
sensuctl organization create acme
sensuctl config set-organization acme
```

Create "demo" environment within "acme" organization.

```
sensuctl environment create demo --interactive
sensuctl config set-environment demo
```

Create "dev" user role with full-access to the "demo" environment.

```
sensuctl role create dev
sensuctl role add-rule dev --interactive
```

Create "demo" user with the "dev" role.

```
sensuctl user create demo --interactive
```

Reconfigure `sensuctl` to use the "demo" user, "acme" organization", and "demo" environment.

```
sensuctl configure
```

### Deploy InfluxDB

Deploy InfluxDB with a Sensu Agent sidecar in the "demo" environment within the "acme" organization.

```
kubectl create -f deploy/kube-config/influxdb/influxdb.acme.yaml
```

### Sensu InfluxDB Handler

Create "influxdb" UDP event handler for sending metrics to the InfluxDB UDP service plugin.

```
sensuctl handler create influxdb --interactive
```

### Deploy Dummy App

Deploy "dummy" application pods with Sensu Agent sidecars in the "demo" environment within the "acme" organization.

```
kubectl create -f deploy/kube-config/dummy.acme.yaml
```

### Prometheus Scraping

Create "sensu-prometheus-collector" asset in the "acme" organization.

```
sensuctl asset create sensu-prometheus-collector --interactive
```

Create "prometheus" check in the "demo" environment within the "acme" organization. The check uses the "influxdb" handler previously created.

```
sensuctl check create prometheus --interactive
```
