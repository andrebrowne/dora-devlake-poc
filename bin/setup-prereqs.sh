#!/bin/bash

set -x

brew install docker docker-credential-helper docker-completion minikube qemu helm kubernetes-cli k9s socket_vmnet podman-desktop

# NOTE: Compose is now part of the Docker CLI
#brew docker-compose 

# For socket_vmnet - See https://minikube.sigs.k8s.io/docs/drivers/qemu/
brew tap homebrew/services
HOMEBREW=$(which brew) && sudo ${HOMEBREW} services restart socket_vmnet
brew services
# Installing hyperkit is optional. Only required for certian, older MacOS versions
#brew install hyperkit
export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')

sudo podman-mac-helper install