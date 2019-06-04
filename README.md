# Sensu Demo

## Prerequisites

1. __[Install Docker for Mac (Edge)](https://store.docker.com/editions/community/docker-ce-desktop-mac)__

2. __Enable Kubernetes (in the Docker for Mac preferences)__

<img src="https://github.com/portertech/sensu-demo/raw/master/images/docker-kubernetes.png" width="600">

3. __Deploy the [Kubernetes NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)__

   ```
   $ kubectl apply -f kube/ingress-nginx/ingress-nginx.yml
   ```

4. __Add hostnames to /etc/hosts__

   ```
   $ sudo vi /etc/hosts

   127.0.0.1       sensu.local webui.sensu.local influxdb.local grafana.local dummy.local
   ```

5. __Create a Kubernetes Ingress Resource__

   ```
   $ kubectl create -f kube/ingress-nginx/sensu-demo.yml
   ```

## Demo

### Deploy Application

1. Deploy dummy app pods

   ```
   $ kubectl apply -f kube/dummy.yaml

   $ kubectl get pods

   $ curl -i http://dummy.local
   ```

### Sensu

1. Deploy Sensu

   ```
   $ kubectl apply -f kube/sensu.yml

   $ kubectl get pods
   ```

2. Configure `sensuctl` to use the built-in "admin" user

   ```
   $ sensuctl configure
   ```

### Multitenancy

1. Create "demo" namespace, user role, and role binding

   ```
   $ sensuctl create -f sensu/multitenancy.yml
   ```

2. Create "demo" user that is a member of the "dev" group

   ```
   $ sensuctl user create demo --interactive
   ```

3. Reconfigure `sensuctl` to use the "demo" user and "demo" namespace

   ```
   $ sensuctl configure
   ```

### Deploy Sensu Sidecars

1. Deploy dummy app Sensu Agent sidecars

   ```
   $ kubectl apply -f kube/dummy.sensu.yaml

   $ kubectl get pods

   $ curl -i http://dummy.local
   ```

### Simple Monitoring Check

1. Register a Sensu Asset for check plugins

   ```
   $ cat sensu/assets/check-plugins.yml

   $ sensuctl create -f sensu/assets/check-plugins.yml

   $ sensuctl asset info check-plugins
   ```

2. Create a check to monitor dummy app /healthz

   ```
   $ sensuctl create -f sensu/checks/dummy-app-healthz.yml

   $ sensuctl check info dummy-app-healthz

   $ sensuctl event list
   ```

3. Toggle the dummy app /healthz status

   ```
   $ curl -iXPOST http://dummy.local/healthz

   $ sensuctl event list
   ```

### Deploy InfluxDB

1. Create a Kubernetes ConfigMap for InfluxDB configuration

   ```
   $ kubectl create configmap influxdb-config --from-file kube/configmap/influxdb-config.conf
   ```

2. Deploy InfluxDB with a Sensu Agent sidecar

    ```
    $ kubectl apply -f kube/influxdb.yml

    $ kubectl get pods

    $ sensuctl entity list
    ```

### Sensu InfluxDB Event Handler

1. Create "influxdb" event handler for sending metrics to InfluxDB

   ```
   $ sensuctl create -f sensu/assets/sensu-influxdb-handler-3.1.2-linux-amd64.yml

   $ cat sensu/handlers/influxdb.yml

   $ sensuctl create -f sensu/handlers/influxdb.yml

   $ sensuctl handler info influxdb
   ```

### Prometheus Scraping

1. Register a Sensu Asset for the Prometheus metric collector

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
    $ kubectl create configmap grafana-provisioning-datasources --from-file=./kube/configmap/grafana-provisioning-datasources.yml

    $ kubectl create -f kube/grafana.yml

    $ kubectl get pods

    $ sensuctl entity list
    ```
