#! /bin/bash
set -euo pipefail
minikube start -m=8G
docker build -t ror-poc:latest -f src/Dockerfile src/
minikube image load ror-poc:latest
cd infra
helmfile apply
export SOPS_AGE_KEY_FILE=~/sops-age-keys.txt
sops -d k8s/overlays/dev/secrets/ror-poc.enc.yaml | minikube kubectl -- apply -f -
minikube kubectl -- apply -k k8s/overlays/dev/
minikube kubectl -- config set-context --current --namespace=ror-poc
