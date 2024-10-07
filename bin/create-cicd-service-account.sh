#!/bin/bash

set -x

eval $(minikube -p minikube docker-env)
kubectl -n default create serviceaccount ${1:-jenkins}-robot
kubectl -n default create rolebinding ${1:-jenkins}-robot-binding --clusterrole=cluster-admin --serviceaccount=default:${1:-jenkins}-robot
kubectl -n default create clusterrolebinding ${1:-jenkins}-robot-binding --clusterrole=cluster-admin --serviceaccount=default:${1:-jenkins}-robot
#kubectl -n default get serviceaccount ${1:-jenkins}-robot -o go-template --template='{{range .secrets}}{{.name}}{{"\n"}}{{end}}'
#kubectl -n default get serviceaccount ${1:-jenkins}-robot -o yaml
echo "Use token to configure ${1:-jenkins}:" 
kubectl create token ${1:-jenkins}-robot
