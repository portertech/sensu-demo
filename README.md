# Sensu Demo

## Prerequisites

1. __[Install Docker for Mac (Edge)](https://store.docker.com/editions/community/docker-ce-desktop-mac)__

2. __Enable Kubernetes (in the Docker for Mac preferences)__

<img src="https://github.com/portertech/sensu-demo/raw/master/images/docker-kubernetes.png" width="600">

3. __Deploy the [Kubernetes NGINX Ingress Controller](https://github.com/kubernetes/ingress-nginx)__

   Use the modified "ingress-nginx" Kubernetes Service definition (works with Docker for Mac):

   ```
   $ kubectl create -f deploy/kube-config/ingress-nginx/services/ingress-nginx.yaml
   ```

4. __Add hostnames to /etc/hosts__

   ```
   $ sudo vi /etc/hosts

   127.0.0.1       sensu.local influxdb.local dummy.local
   ```

5. __Create a Kubernetes Ingress Resource__

   ```
   $ kubectl create -f deploy/kube-config/ingress-nginx/ingress/sensu-demo.yaml
   ```

## Demo

### Sensu Backend

1. Deploy Sensu Backend

   ```
   $ kubectl create -f deploy/kube-config/sensu-backend.yaml
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

1. Deploy InfluxDB with a Sensu Agent sidecar

    ```
    $ kubectl create -f deploy/kube-config/influxdb/influxdb.acme.yaml
    ```

### Sensu InfluxDB Event Handler

1. Create "influx" UDP event handler for sending metrics to the InfluxDB UDP service plugin

   ```
   $ sensuctl handler create influx --type udp \
   --socket-host influxdb.default.svc.cluster.local --socket-port 8089 \
   --mutator only_check_output --timeout 5 \
   --organization acme --environment demo
   ```

### Deploy Application

1. Deploy dummy app pods with Sensu Agent sidecars

   ```
   $ kubectl create -f deploy/kube-config/dummy.acme.yaml
   ```

### Sensu Monitoring Checks

1. Register a Sensu 2.0 Asset for check plugins

   ```
   $ sensuctl asset create check-plugins \
   --url https://github.com/portertech/sensu-plugins-go/releases/download/0.0.1/sensu-check-plugins.tar.gz \
   --sha512 4e6f621ebe652d3b0ba5d4dead8ddb2901ea03f846a1cb2e39ddb71b8d0daa83b54742671f179913ed6c350fc32446a22501339f60b8d4e0cdb6ade5ee77af16 \
   --organization acme
   ```

2. Create a check to monitor Google via ICMP from the dummy app pods

   ```
   $ sensuctl check create google \
   --runtime-assets check-plugins \
   --command "check-ping -h google.ca -P 80" \
   --subscriptions dummy --interval 10 --timeout 5 \
   --organization acme --environment demo
   ```

### Prometheus Scraping

1. Register a Sensu 2.0 Asset for the Prometheus metric collector

   ```
   $ sensuctl asset create prometheus-collector \
   --url https://github.com/portertech/sensu-prometheus-collector/releases/download/1.0.0/sensu-prometheus-collector.tar \
   --sha512 c1ec2f493f0ff9d83914e0a1bf3b2f6d424a51ffd9b5852d3dd04e592ebc56ab3d09635540677d6f78ea07138024f3d6a4f7f71e2cb744d7a565d4fa4077611c \
   --organization acme
   ```

2. Create a check to collect dummy app Prometheus metrics

   ```
   $ sensuctl check create prometheus \
   --runtime-assets prometheus-collector \
   --command "sensu-prometheus-collector -exporter-url http://localhost:8080/metrics" \
   --subscriptions dummy --interval 10 --timeout 5 \
   --organization acme --environment demo \
   --handlers influx
   ```

3. Query InfluxDB to list received series

   ```
   $ curl -GET 'http://influxdb.local/query' --data-urlencode 'q=SHOW SERIES ON sensu'
   ```
