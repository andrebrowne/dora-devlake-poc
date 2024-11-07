# DORA POC

## Prerequisites

- [Docker v19.03.10+](https://docs.docker.com/get-docker)
- [Homebrew](https://brew.sh/)
- [Minikube Docker Driver](https://minikube.sigs.k8s.io/docs/drivers/) - Any driver compatible with your Mac and Minikube's drivers [listed here](https://minikube.sigs.k8s.io/docs/drivers/)

__NOTE:__ The scripts provided in this repo assume the Minikube Podman driver is bound to the Minikube machine

## Quickstart

Run:

```shell
git clone https://github.com/andrebrowne/dora-devlake-poc
cd dora-devlake-poc
./bin/setup-devlake-prereqs.sh
./bin/setup-devlake.sh
./jenkins/bin/get-jenkins-password.sh
```

## Installation

### Apache DevLake

To install an instance of Apache DevLake use either [Helm](https://devlake.apache.org/docs/GettingStarted/HelmSetup) or [Docker Compose](https://devlake.apache.org/docs/GettingStarted/DockerComposeSetup).

Configuration is simple. Follow the [Apache DevLake Setup Guide](https://devlake.apache.org/docs/Configuration/Tutorial) or run the scripts and steps documented below.

## CI/CD

### Jenkins

- Install and configure [plugins](jenkins/plugins.md)
- Add a credential for the K8s cluster (e.g. [This script](bin/create-cicd-service-account.sh) can create a `jenkins-robot` service account for jenkins on minikube and generates a token for the service account in the `devlake` namespace)
- Create a pipeline (e.g. This [Jenkinsfile](jenkins/Jenkinsfile) creates a pipeline that will build, containerize and install the `dora-poc` branch of this [Spring Pet Clinic](https://github.com/andrebrowne/spring-petclinic.git) repo)
- Increase jenkins runner agent pod resources
- Update the Cloud Pod Template to use the `jenkins-robot` service account

### Github

- Create labels that Apache DevLake uses to track DORA events ![label examples (DevLake)](https://devlake.apache.org/assets/images/github-set-transformation2-8a84153828bfed36f4089019c8059db9.png "Github Labels Setup Example")
- Create a Kanban Project
- Create a Bug Tracking Project (Optional)
- Associate project with a code repository
  - Create issues, commits, PR, branches that use Apache Dev Lake compatible labels

### Concourse

TBA

## Static Analysis

### SonarQube

TBA
