#!/bin/bash

kubectl delete deployment dummy
kubectl delete service dummy

kubectl delete deployment influxdb
kubectl delete service influxdb

kubectl delete deployment grafana
kubectl delete service grafana

kubectl delete statefulset sensu --cascade=true
kubectl delete service sensu
