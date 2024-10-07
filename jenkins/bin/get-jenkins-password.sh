#!/bin/bash
eval $(minikube -p minikube docker-env)
kubectl config set-context --current --namespace=default
kubectl exec --namespace default -it svc/dora-jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
