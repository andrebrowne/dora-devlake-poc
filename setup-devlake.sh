#!/bin/bash

# set -x
set -e

echo "> Installing tools..."
brew install minikube helm kubernetes-cli k9s

echo "> Provisioning pods..."
# TODO: detect docker and prompt to start if not running
# TODO: detect minikube and start if not running
#minikube pause
#minikube stop
minikube start --kubernetes-version=latest 

# Create devlake secret
openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1 > ./.secret.txt
echo -e  ">> Adding the following to ~/.zshenv:\n>> export ENCRYPTION_SECRET=`cat ./.secret.txt`"
echo -e  "\nexport ENCRYPTION_SECRET=`cat ./.secret.txt`\n" >> ~/.zshenv
source ~/.zshenv
rm -vf ./.secret.txt

echo ">> Adding helm repos"
#helm repo add concourse https://concourse-charts.storage.googleapis.com/
helm repo add jenkins https://charts.jenkins.io
helm repo add devlake https://apache.github.io/incubator-devlake-helm-chart
helm repo update

# https://github.com/concourse/concourse-chart
#echo ">> Installing concourse via helm"
#helm install dora-concourse concourse/concourse

# https://github.com/jenkinsci/helm-charts?tab=readme-ov-file
# https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/README.md
echo ">> Installing jenkins via helm"
helm install dora-jenkins jenkins/jenkins

echo ">> Installing devlake via helm"
helm install dora-devlake devlake/devlake \
        --version=1.0-beta1 \
        --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET \
        --set grafana.adminPassword=AlwaysBeKind!

# TODO: Add container pods healthy and ready checks
SLEEP_DURATION_SECONDS=100
echo ">> Waiting ${SLEEP_DURATION_SECONDS} seconds for pods"
sleep $SLEEP_DURATION_SECONDS

export POD_NAME=$(kubectl get pods --namespace default -l "app=dora-concourse-web" -o jsonpath="{.items[0].metadata.name}")
# dora-concourse-web.default.svc.cluster.local
echo "Visit http://127.0.0.1:8080 to use Concourse"
kubectl port-forward --namespace default $POD_NAME 8080:8080

kubectl exec --namespace default -it svc/dora-jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
echo http://127.0.0.1:8080
kubectl --namespace default port-forward svc/dora-jenkins 8080:8080 & 2>/dev/null
echo "Login with the password from above and the username: admin"
echo "Configure security realm and authorization strategy"

export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services dora-devlake-ui)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")

kubectl port-forward service/devlake-ui --pod-running-timeout=10s $NODE_PORT:$NODE_PORT & 2>/dev/null
#kubectl port-forward service/devlake-grafana  --pod-running-timeout=10s 3000:80 & 2>/dev/null

echo "Click http://${NODE_IP}:${NODE_PORT} to view DevLake Config UI (password: AlwaysBeKind!)"
#echo "Click http://localhost:30091 to view DevLake Grafana UI (password: AlwaysBeKind!)"

# If any environment variables are modified (e.g. ENABLE_SUBTASKS_BY_DEFAULT) run: 
#helm upgrade devlake devlake/devlake --recreate-pods
