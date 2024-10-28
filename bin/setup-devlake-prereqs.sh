#!/bin/bash

set -x

export HOMEBREW_NO_AUTO_UPDATE=1

brew install docker docker-credential-helper docker-completion minikube helm kubernetes-cli k9s podman-desktop

# NOTE: Compose is now part of the Docker CLI
#brew install docker-compose 

export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')

sudo podman-mac-helper install
