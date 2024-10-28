#!/bin/bash

set -x

sudo podman-mac-helper install

# https://github.com/containers/podman/issues/17560
podman machine start --userns=keep-id:uid=${UID}
podman machine list
podman machine info
