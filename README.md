# Sensu Demo

## Prerequisites

1. __[Install Docker for Mac (Edge)](https://store.docker.com/editions/community/docker-ce-desktop-mac)__

2. __Enable Kubernetes (in the Docker for Mac preferences)__

<img src="https://github.com/portertech/sensu-demo/raw/master/images/docker-kubernetes.png" width="600">

3. __Deploy the [Kubernetes NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)__

   ```
   $ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
   ```

   Then use the modified "ingress-nginx" Kubernetes Service definition (works with Docker for Mac):

   ```
   $ kubectl create -f deploy/kube-config/ingress-nginx/services/ingress-nginx.yaml
   ```

4. __Add hostnames to /etc/hosts__

   ```
   $ sudo vi /etc/hosts

   127.0.0.1       sensu.local webui.sensu.local influxdb.local grafana.local dummy.local
   ```

5. __Create a Kubernetes Ingress Resource__

   ```
   $ kubectl create -f deploy/kube-config/ingress-nginx/ingress/sensu-demo.yaml
   ```

## Demo

### Deploy Application

1. Deploy dummy app pods

   ```
   $ kubectl create -f deploy/kube-config/dummy.yaml

   $ kubectl get pods

   $ curl -i http://dummy.local
   ```

### Sensu Backend

1. Deploy Sensu Backend

   ```
   $ kubectl create -f deploy/kube-config/sensu-backend.yaml

   $ kubectl get pods
   ```

2. Configure `sensuctl` to use the built-in "admin" user

   ```
   $ sensuctl configure
   ```

### Multitenancy

1. Create "acme" organization

   ```
   $ sensuctl organization create acme

   $ sensuctl config set-organization acme
   ```

2. Create "demo" environment within the "acme" organization

   ```
   $ sensuctl environment create demo --interactive

   $ sensuctl environment list

   $ sensuctl config set-environment demo
   ```

3. Create "dev" user role with full-access to the "demo" environment

   ```
   $ sensuctl role create dev -t '*' \
   --create --delete --update --read \
   --environment demo --organization acme
   ```

4. Create "demo" user with the "dev" role

   ```
   $ sensuctl user create demo --interactive
   ```

5. Reconfigure `sensuctl` to use the "demo" user, "acme" organization", and "demo" environment

   ```
   $ sensuctl configure
   ```

### Deploy InfluxDB

1. Create a Kubernetes ConfigMap for InfluxDB configuration

   ```
   $ kubectl create configmap influxdb-config --from-file deploy/kube-config/influxdb/influxdb.conf
   ```

2. Deploy InfluxDB with a Sensu Agent sidecar

    ```
    $ kubectl create -f deploy/kube-config/influxdb/influxdb.sensu.yaml

    $ kubectl get pods

    $ sensuctl entity list
    ```

### Sensu InfluxDB Event Handler

1. Create "influxdb" event handler for sending Sensu 2.0 metrics to InfluxDB

   ```
   $ cat config/handlers/influxdb.json

   $ sensuctl create -f config/handlers/influxdb.json

   $ sensuctl handler info influxdb
   ```

### Deploy Application

1. Deploy dummy app Sensu Agent sidecars

   ```
   $ kubectl apply -f deploy/kube-config/dummy.sensu.yaml

   $ kubectl get pods

   $ curl -i http://dummy.local
   ```

### Sensu Monitoring Checks

1. Register a Sensu 2.0 Asset for check plugins

   ```
   $ cat config/assets/check-plugins.json

   $ sensuctl create -f config/assets/check-plugins.json

   $ sensuctl asset info check-plugins
   ```

2. Create a check to monitor dummy app /healthz

   ```
   $ sensuctl create -f config/checks/dummy-app-healthz.json

   $ sensuctl check info dummy-app-healthz

   $ sensuctl event list
   ```

3. Toggle the dummy app /healthz status

   ```
   $ curl -iXPOST http://dummy.local/healthz

   $ sensuctl event list
   ```

### Prometheus Scraping

1. Register a Sensu 2.0 Asset for the Prometheus metric collector

   ```
   $ sensuctl create -f config/assets/prometheus-collector.json
   ```

2. Create a check to collect dummy app Prometheus metrics

   ```
   $ sensuctl create -f config/checks/dummy-app-prometheus.json

   $ sensuctl check info dummy-app-prometheus
   ```

3. Query InfluxDB to list the stored series

   ```
   $ curl -GET 'http://influxdb.local/query' --data-urlencode 'q=SHOW SERIES ON sensu'
   ```

### Deploy Grafana

1. Deploy Grafana with a Sensu Agent sidecar

    ```
    $ kubectl create -f deploy/kube-config/grafana.sensu.yaml

    $ kubectl get pods

    $ sensuctl entity list
    ```

### Grafana Data Source

In the Grafana WebUI (http://grafana.local), add the [InfluxDB data source](http://docs.grafana.org/features/datasources/influxdb/).

| Setting | Value |
| --- | --- |
| Type | InfluxDB |
| URL | http://influxdb.default.svc.cluster.local:8086 |
| Database | sensu |
| User | sensu |
| Password | password |
