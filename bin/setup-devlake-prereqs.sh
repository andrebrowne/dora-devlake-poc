#!/bin/bash

#set -x

export HOMEBREW_NO_AUTO_UPDATE=1

brew install docker docker-credential-helper docker-completion minikube helm kubernetes-cli k9s podman-desktop
brew install docker qemu socket_vmnet
#brew install hyperkit # Installing hyperkit is optional. Only required for certain, older MacOS versions
#brew update
brew upgrade podman
# NOTE: Compose is now part of the Docker CLI
#brew install docker-compose

# For socket_vmnet - See https://minikube.sigs.k8s.io/docs/drivers/qemu/
brew tap homebrew/services
HOMEBREW=$(which brew) && sudo ${HOMEBREW} services restart socket_vmnet
brew services

export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')

sudo podman-mac-helper install
