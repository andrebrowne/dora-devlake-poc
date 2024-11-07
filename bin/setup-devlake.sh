#!/bin/bash

set -x
set -e

SCRIPT=$(realpath "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")
SECRET=AlwaysBeKind
CI_CD=jenkins
SLEEP_DURATION_SECONDS=900
NAMESPACE=${1:-devlake}
UI_PORT=${2:-32767}

export HOMEBREW_NO_AUTO_UPDATE=1

echo "> Installing tools..."
brew install minikube helm kubernetes-cli k9s

echo "> Starting kubernetes..."
minikube start -p devlake --kubernetes-version latest --disk-size 50gb  --cpus 4 --memory 8192 --auto-pause-interval 10h
minikube profile devlake
eval $(minikube -p devlake docker-env)
minikube -p devlake addons enable auto-pause
minikube -p devlake status
#minikube ssh docker image prune -a

echo "> Validate/Create namespace ${NAMESPACE}"
if kubectl get namespace ${NAMESPACE}; then
    echo ">> Namespace ${NAMESPACE} exists"
else
    kubectl create namespace ${NAMESPACE}
fi

echo "> Provisioning pods..."

kubectl config set-context --current --namespace=${NAMESPACE}

echo ">> Adding helm repos"
helm repo add devlake https://apache.github.io/incubator-devlake-helm-chart

if [ "$CI_CD" == "jenkins" ] ; then
    helm repo add jenkins https://charts.jenkins.io
fi

helm repo update

echo ">> Installing DevLake (via helm)"
if [[ -z "${ENCRYPTION_SECRET}" ]]; then
    echo ">> Using existing ENCRYPTION_SECRET"
else
    # Create devlake secret
    openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1 > ./.secret.txt
    echo -e  ">> Adding the following to ~/.zshenv:\n>> export ENCRYPTION_SECRET=`cat ./.secret.txt`"
    echo -e  "\nexport ENCRYPTION_SECRET=`cat ./.secret.txt`\n" >> ~/.zshenv
    source ~/.zshenv
    rm -vf ./.secret.txt
fi

#helm upgrade --install --create-namespace --namespace ${NAMESPACE} ${NAMESPACE}-devlake devlake/devlake --set service.uiPort=${UI_PORT} --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET --set grafana.adminPassword=$SECRET # --version=1.0.2-beta1
helm upgrade --install --create-namespace --namespace ${NAMESPACE} ${NAMESPACE}-devlake devlake/devlake --set lake.encryptionSecret.secret=${ENCRYPTION_SECRET} --set grafana.adminPassword=${SECRET} # --version=1.0.2-beta1

if [ "$CI_CD" == "jenkins" ] ; then
    # https://github.com/jenkinsci/helm-charts?tab=readme-ov-file
    # https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/README.md
    echo ">> Installing jenkins via helm"
    helm upgrade --install --create-namespace --namespace ${NAMESPACE} ${NAMESPACE}-jenkins jenkins/jenkins
fi

echo "> Confirming health checks..."

echo ">> Waiting for DevLake MySQL pod..."
kubectl rollout status statefulset ${NAMESPACE}-devlake-mysql --timeout=${SLEEP_DURATION_SECONDS}s

echo ">> Waiting for DevLake Lake pod..."
kubectl rollout status deployment ${NAMESPACE}-devlake-lake --timeout=${SLEEP_DURATION_SECONDS}s

echo ">> Waiting for DevLake UI pod..."
kubectl rollout status deployment ${NAMESPACE}-devlake-ui --timeout=${SLEEP_DURATION_SECONDS}s

echo ">> Waiting for DevLake Grafana pod..."
kubectl rollout status deployment ${NAMESPACE}-devlake-grafana --timeout=${SLEEP_DURATION_SECONDS}s

if [ "$CI_CD" == "jenkins" ] ; then
    echo ">> Waiting for Jenkins pod..."
    kubectl rollout status statefulset ${NAMESPACE}-jenkins --timeout=${SLEEP_DURATION_SECONDS}s
    kubectl exec --namespace ${NAMESPACE} -it svc/${NAMESPACE}-jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
    echo "After setting up a port-forward in a new terminal visit http://127.0.0.1:8080 to use Jenkins"
    echo "run:\n\tkubectl port-forward --namespace ${NAMESPACE} svc/${NAMESPACE}-jenkins 8080:8080"
    echo "Login with the password from above and the username: admin"
    echo "Configure security realm and authorization strategy"
    echo ">> Adding service account for Jenkins"
    ${SCRIPT_PATH}/create-cicd-service-account.sh jenkins ${NAMESPACE}
fi

#export NODE_PORT=$(kubectl get --namespace ${NAMESPACE} -o jsonpath="{.spec.ports[0].nodePort}" services ${NAMESPACE}-devlake-ui)
#export NODE_IP=$(kubectl get nodes --namespace ${NAMESPACE} -o jsonpath="{.items[0].status.addresses[0].address}")

#kubectl port-forward service/devlake-ui --pod-running-timeout=10s 32001:$NODE_PORT & 2>/dev/null
#kubectl port-forward service/devlake-grafana  --pod-running-timeout=10s 3000:80 & 2>/dev/null

#echo "Click http://${NODE_IP}:32001 to view DevLake Config UI (password: ${SECRET})"
echo "DevLake Config UI password: ${SECRET}"

# If any environment variables are modified (e.g. ENABLE_SUBTASKS_BY_DEFAULT) run: 
#helm upgrade --install --create-namespace --namespace ${NAMESPACE} ${NAMESPACE}-devlake devlake/devlake --recreate-pods

echo "> DevLake set up complete!"
