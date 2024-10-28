#!/bin/bash
NAMESPACE=${1:-default}
eval $(minikube -p minikube docker-env)
kubectl config set-context --current --namespace=${NAMESPACE}
kubectl exec --namespace ${NAMESPACE} -it svc/dora-jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
