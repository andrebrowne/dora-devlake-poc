# DORA POC

## Prerequisites

- [Docker v19.03.10+](https://docs.docker.com/get-docker)
- [docker-compose v2.2.3+](https://docs.docker.com/compose/install/)
- Helm >= 3.6.0
- Kubernetes >= 1.19.0
- MiniKube

## Installation

### Google FourKeys

TBA

### Apache DevLake

Install Apache DevLake using [Helm](https://devlake.apache.org/docs/GettingStarted/HelmSetup) or [Docker Compose](https://devlake.apache.org/docs/GettingStarted/DockerComposeSetup).

Configuration is pretty easy, you can follow the Apache DevLake Setup Guide or run the scripts and steps documented below.

## CI/CD

### Concourse

TBA

### Jenkins

- Install and configure [plugins](jenkins/plugins.md)
- Add credential for K8S cluster (e.g. [This script](jenkins/bin/create-jenkins-service-account.sh) creates a service account for jenkins on minikube and generates a token)
- Create pipeline (e.g. [This Jenkinsfile](jenkins/Jenkinsfile) creates a pipeline that can build, containerize and install the `dora-poc` branch of [this repo](https://github.com/andrebrowne/spring-petclinic.git))
- Increase jenkins runner agent pod resources

### Github

- Create labels that Apache DevLake uses to track DORA events ![label examples](https://devlake.apache.org/assets/images/github-set-transformation2-8a84153828bfed36f4089019c8059db9.png "Github Labels Setup Example")
- Create a Kanban Project
- Create a Bug Tracking Project
- Associate project with a code repository
  - Create issues, commits, PR, branches that use Apache Dev Lake compatible labels

## Static Analysis

### SonarQube

TBA
