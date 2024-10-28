#!/bin/bash

set -x

SA_NAME=${1:-jenkins}
NAMESPACE=${2:-default}

eval $(minikube -p minikube docker-env)

kubectl -n ${NAMESPACE} create serviceaccount ${SA_NAME}-robot
kubectl -n ${NAMESPACE} create rolebinding ${SA_NAME}-robot-binding --clusterrole=cluster-admin --serviceaccount=${NAMESPACE}:${SA_NAME}-robot
kubectl -n ${NAMESPACE} create clusterrolebinding ${SA_NAME}-robot-binding --clusterrole=cluster-admin --serviceaccount=${NAMESPACE}:${SA_NAME}-robot
#kubectl -n ${NAMESPACE} get serviceaccount ${SA_NAME}-robot -o go-template --template='{{range .secrets}}{{.name}}{{"\n"}}{{end}}'
#kubectl -n ${NAMESPACE} get serviceaccount ${SA_NAME}-robot -o yaml

echo "Use token to configure ${SA_NAME}:" 

kubectl create token ${SA_NAME}-robot
