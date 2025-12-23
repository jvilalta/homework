# Environment Setup and Deployment Instructions

## Setting Up the Environment
I set up a local Kubernetes cluster using Minikube running on a Ubuntu 24 VM with 10 GB memory and 2 CPUs, and assigned 8GB memory to minikube (minikube start -m=8G). Clone the repository to the VM running Minikube. We will use this for building and deploying the application. Install the prerequisites listed below on the VM.

## Prerequisites
- Docker
- Minikube
- Helm
- Helmfile
- SOPS
- AGE 


## Building the Docker Image
Clone the repository and navigate to the root directory of the repo.

Build the container image with:
```bash
# run this from the root directory or adjust the path accordingly
docker build -t ror-poc:latest -f src/Dockerfile src/
```

Load the image into Minikube:
```bash
minikube image load ror-poc:latest
```

### Deploying the Application Dependencies
Install the helm charts for prometheus, grafana, postgres, and redis:
```bash
# Run this from the infra directory
helmfile apply
```
Install the Dashboards in Grafana:
PostgreSQL Overview
https://grafana.com/grafana/dashboards/9628-postgresql-database/

Redis Overview
https://grafana.com/grafana/dashboards/11835-redis-dashboard-for-prometheus-redis-exporter-helm-stable-redis-ha/

### Deploying the Application
I used sops to encrypt the secrets for dev, but I also committed the decrypted version for ease of testing. I have described how to run sops to decrypt the secrets below and apply them, but you can skip that step and just apply the manifests directly if you want to use the committed decrypted files. If you have an AGE key pair, you can use that to encrypt/decrypt the secrets.

Encrypting secrets with sops and AGE:
```bash
# Generate AGE key pair if you don't have one
age-keygen -o ~/sops-age-keys.txt

# Encrypt the secrets file, use the public key from the generated key pair
sops --encrypt --age age14elm7mh8cvjujj5wtzl74ykqka5n82f569xl8284ajmv57424urslyyljz k8s/overlays/dev/secrets/ror-poc.yaml > k8s/overlays/dev/secrets/ror-poc.enc.yaml
``` 

The application manifests are located in the `k8s` directory. Apply them with:
```bash
# Run this from the infra directory
# First the secrets
export SOPS_AGE_KEY_FILE=~/sops-age-keys.txt
sops -d k8s/overlays/dev/secrets/ror-poc.enc.yaml | kubectl apply -f -
# Then the rest of the manifests
kubectl apply -k k8s/overlays/dev/
```
You'll get this warning:
```
Warning: resource namespaces/ror-poc is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
```
This is because the namespace was created by helm, but it can be ignored. I put everything in the `ror-poc` namespace, but likely you'd deploy prometheus/grafana/pg/redis in their own/separate namespace in a production setup.

Swtich to the namespace and check the deployed resources:
```bash
kubectl config set-context --current --namespace=ror-poc
```
At this point, the application should be deployed. There are exporters for Postgres and Redis included in their respective helm charts, and Prometheus is configured to scrape them. There is also an application metrics endpoint at `/metrics` that Prometheus is scraping.

## Metrics Used for Alerts
I have created some basic alerting rules for both the application and the database/cache layers.

### Application Layer (ror-poc-prometheusrule.yaml)
HTTP Error Rate: 5xx responses >5% - detects application failures
Response Time: 95th percentile >2s - identifies performance degradation
Memory Usage: Container memory >85% - prevents OOM crashes
Pod Restarts: >0.1/hour - catches application instability
CPU Usage: Container CPU >80% - detects performance bottlenecks and resource constraints
CPU Throttling: Detects when containers hit CPU limits - indicates undersized resource requests

### Database/ Cache Layer (helmfile.yaml)
PostgreSQL:

Cache Hit Ratio: <95% - indicates inefficient queries or insufficient memory
Connection Usage: >80% - prevents connection exhaustion
Replication Lag: >30s - ensures data consistency in HA setups
Disk Usage: >85% - prevents database outages from storage exhaustion
CPU Usage: >80% - indicates expensive queries or insufficient resources
Redis:

Cache Hit Rate: <80% - monitors caching effectiveness
Memory Usage: >85% - prevents cache evictions and performance loss
Key Eviction Rate: >100 keys/5min - indicates memory pressure
Connection Rejections: Any rejections - catches connectivity issues
CPU Usage: >70% - detects inefficient operations (lower threshold since Redis should be CPU-light)

## AI Usage
Used ChatGPT and the Anthropic Claude models to help with the following:
- All of the ruby related code including the Rails application and Dockerfile were generated with the help of GitHub Copilot.
- Copilot was also used to help write this file, including reading through the codebase to understand how the application is instrumented for metrics and generating the relevant sections.
- The syntax of the alerting rules for Prometheus was generated with the help of Claude.
- Troubleshooting of the Rails app and instrumentation issues was done with the help of Copilot.

## Notes
There is a setup script in the scripts folder that runs through most of the steps described here. You can run that to set up the environment and deploy the application quickly, but you will need to manually install the prerequisites on the VM first and setup the AGE keys if you want to use sops for secrets management.
