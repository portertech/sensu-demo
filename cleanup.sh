#!/bin/bash

kubectl delete deployment dummy
kubectl delete service dummy

kubectl delete deployment influxdb
kubectl delete service influxdb

kubectl delete deployment sensu-backend
kubectl delete service sensu-backend
