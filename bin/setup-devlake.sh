#!/bin/bash

set -x
set -e

SCRIPT=$(realpath "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
SECRET=AlwaysBeKind
CICD=jenkins
SLEEP_DURATION_SECONDS=180

# TODO: Prompt user for CI/CD platform choice (Jenkins or Concourse)
# TODO: Validate script logic is correct for Concourse installation
echo "> Installing tools..."
brew install minikube helm kubernetes-cli k9s

# For socket_vmnet - See https://minikube.sigs.k8s.io/docs/drivers/qemu/
#brew install socket_vmnet qemu
#brew tap homebrew/services
#HOMEBREW=$(which brew) && sudo ${HOMEBREW} services start socket_vmnet

echo "> Provisioning pods..."
# TODO: detect docker and prompt to start if not running
# TODO: detect minikube and start if not running
#minikube pause
#minikube stop
# TODO: Parameterize --driver= and default to podman
minikube start --kubernetes-version=latest # --driver qemu2 --network socket_vmnet
eval $(minikube -p minikube docker-env)

echo ">> Adding helm repos"
helm repo add devlake https://apache.github.io/incubator-devlake-helm-chart
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube

if [ "$CICD" == "concourse" ] ; then
    helm repo add concourse https://concourse-charts.storage.googleapis.com/
fi

if [ "$CICD" == "jenkins" ] ; then
    helm repo add jenkins https://charts.jenkins.io
fi

helm repo update

# This takes the longest (Due to Elastic Search indexing), fire it up first!
echo ">> Installing SonarQube (via helm)"
helm upgrade --install --namespace default dora-sonarqube sonarqube/sonarqube # --set deploymentType=Deployment


echo ">> Installing DevLake (via helm)"
# Create devlake secret
# TODO: detect pre-existing ENCRYPTION_SECRET
openssl rand -base64 2000 | tr -dc 'A-Z' | fold -w 128 | head -n 1 > ./.secret.txt
echo -e  ">> Adding the following to ~/.zshenv:\n>> export ENCRYPTION_SECRET=`cat ./.secret.txt`"
echo -e  "\nexport ENCRYPTION_SECRET=`cat ./.secret.txt`\n" >> ~/.zshenv
source ~/.zshenv
rm -vf ./.secret.txt
helm upgrade --install --namespace default dora-devlake devlake/devlake \
        --set lake.encryptionSecret.secret=$ENCRYPTION_SECRET \
        --set grafana.adminPassword=$SECRET #\ 
#        --version=1.0.2-beta1

if [ "$CICD" == "concourse" ] ; then
    https://github.com/concourse/concourse-chart
    echo ">> Installing concourse via helm"
    helm upgrade --install --namespace default dora-concourse concourse/concourse
fi

if [ "$CICD" == "jenkins" ] ; then
    # https://github.com/jenkinsci/helm-charts?tab=readme-ov-file
    # https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/README.md
    echo ">> Installing jenkins via helm"
    helm upgrade --install --namespace default dora-jenkins jenkins/jenkins
fi

if [ "$CICD" == "concourse" ] ; then
    export POD_NAME=$(kubectl get pods --namespace default -l "app=dora-concourse-web" -o jsonpath="{.items[0].metadata.name}")
    # Or dora-concourse-web.default.svc.cluster.local
    echo "After setting up a port-forward in a new terminal visit http://127.0.0.1:8080 to use Concourse"
    echo "run:\n\tkubectl port-forward --namespace default ${POD_NAME} 8080:8080"    
    echo ">> Adding service account for Concourse"
    ${SCRIPTPATH}/create-cicd-service-account.sh concourse
fi

if [ "$CICD" == "jenkins" ] ; then
    kubectl exec --namespace default -it svc/dora-jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
    echo ">> Waiting for DevLake pods.."
    kubectl rollout status statefulset dora-jenkins --timeout=${SLEEP_DURATION_SECONDS}s
    echo "After setting up a port-forward in a new terminal visit http://127.0.0.1:8080 to use Jenkins"
    echo "run:\n\tkubectl port-forward --namespace default svc/dora-jenkins 8080:8080"
    echo "Login with the password from above and the username: admin"
    echo "Configure security realm and authorization strategy"
    echo ">> Adding service account for Jenkins"
    ${SCRIPTPATH}/create-cicd-service-account.sh jenkins
fi
echo ">> Waiting for DevLake MySQL pod..."
kubectl rollout status statefulset dora-devlake-mysql --timeout=${SLEEP_DURATION_SECONDS}s

echo ">> Waiting for DevLake Lake pod..."
kubectl rollout status deployment dora-devlake-lake --timeout=${SLEEP_DURATION_SECONDS}s

echo ">> Waiting for DevLake UI pod..."
kubectl rollout status deployment dora-devlake-ui --timeout=${SLEEP_DURATION_SECONDS}s

echo ">> Waiting for DevLake Grafana pod..."
kubectl rollout status deployment dora-devlake-grafana --timeout=${SLEEP_DURATION_SECONDS}s

echo ">> Waiting for SonarQube pods..."
kubectl rollout status statefulset dora-sonarqube-postgresql --timeout=${SLEEP_DURATION_SECONDS}s
kubectl rollout status statefulset dora-sonarqube-sonarqube --timeout=${SLEEP_DURATION_SECONDS}s

export NODE_PORT=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services dora-devlake-ui)
export NODE_IP=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")

#kubectl port-forward service/devlake-ui --pod-running-timeout=10s 32001:$NODE_PORT & 2>/dev/null
#kubectl port-forward service/devlake-grafana  --pod-running-timeout=10s 3000:80 & 2>/dev/null

#echo "Click http://${NODE_IP}:32001 to view DevLake Config UI (password: ${SECRET})"
echo "DevLake Config UI password: ${SECRET}"

# If any environment variables are modified (e.g. ENABLE_SUBTASKS_BY_DEFAULT) run: 
#helm upgrade --install --namespace default devlake devlake/devlake --recreate-pods

echo "> DevLake set up complete!"
