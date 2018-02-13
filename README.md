# Sensu Demo

## Prerequisites

__[Install Docker for Mac (Edge)](https://store.docker.com/editions/community/docker-ce-desktop-mac)__

__Enable Kubernetes (in the Docker for Mac preferences)__

![docker-kubernetes](./images/docker-kubernetes.png =250x)

__Deploy the [Kubernetes NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)__

Use the modified "ingress-nginx" Kubernetes Service definition (works with Docker for Mac):

```
kubectl create -f deploy/kube-config/ingress-nginx/services/ingress-nginx.yaml
```

4. Add hostnames to /etc/hosts

```
sudo vi /etc/hosts

127.0.0.1       sensu.local influxdb.local dummy.local
```

5. Create a Kubernetes Ingress Resource

```
kubectl create -f deploy/kube-config/ingress-nginx/ingress/sensu-demo.yaml
```

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

### Multitenancy

Create "acme" organization.

```
sensuctl organization create acme
sensuctl config set-organization acme
```

Create "demo" environment within the "acme" organization.

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

### Deploy Application

Deploy "dummy" application pods with Sensu Agent sidecars in the "demo" environment within the "acme" organization.

```
kubectl create -f deploy/kube-config/dummy.acme.yaml
```

### Prometheus Scraping

Create "sensu-prometheus-collector" asset in the "acme" organization.

| attribute | value |
| --- | --- |
| URL | https://github.com/portertech/sensu-prometheus-collector/releases/download/1.0.0/sensu-prometheus-collector.tar |
| SHA | c1ec2f493f0ff9d83914e0a1bf3b2f6d424a51ffd9b5852d3dd04e592ebc56ab3d09635540677d6f78ea07138024f3d6a4f7f71e2cb744d7a565d4fa4077611c |

```
sensuctl asset create sensu-prometheus-collector --interactive
```

Create "prometheus" check in the "demo" environment within the "acme" organization. The check uses the "influxdb" handler previously created.

```
sensuctl check create prometheus --interactive
```

Query InfluxDB to list received series.

```
curl -GET 'http://influxdb.local/query' --data-urlencode 'q=SHOW SERIES ON sensu'
```
