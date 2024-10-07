#!/bin/bash

set -x
set -e

echo "> Installing pipx and graphviz (via homebrew)"
brew install pipx graphviz jupyterlab
brew install --cask jupyter-notebook-ql

echo "> Installing poetry (via pipx)"
pipx ensurepath
pipx install poetry
pipx list

source ~/.bashrc ~/.bash_profile

poetry --version

#git clone git@github.com:apache/incubator-devlake-playground.git
[ -d "./incubator-devlake-playground/notebooks" ] && echo "skipping clone" || git clone https://github.com/apache/incubator-devlake-playground.git

echo "> Running devlake playground Jupyter notebook (via homebrew)"
pushd incubator-devlake-playground/notebooks
git rebase
poetry run jupyter notebook

echo "Vist https://devlake.apache.org/blog/DevLake-Playground-How-to-explore-your-data/ for details on the playground"