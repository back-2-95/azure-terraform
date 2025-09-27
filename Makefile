# Makefile for Terraform/OpenTofu workflows per environment
# Usage examples:
#   make init-dev
#   make plan-stg
#   make apply-prod
#
# You can override the CLI used (terraform/tofu/tf):
#   make CLI=tofu plan-dev

SHELL := /bin/sh
CLI ?= terraform
ENV_DIR := envs
BACKEND_FILE ?= backend.hcl

.PHONY: help init-% plan-% apply-% destroy-% aks-credentials-% kubectl-apply-% helm-install-myapp-% helm-uninstall-myapp-% helm-install-traefik-% helm-uninstall-traefik-%

help:
	@echo "Targets:"
	@echo "  make init-<env>                    # init with backend.hcl (env = dev|stg|prod)"
	@echo "  make plan-<env>                    # terraform plan"
	@echo "  make apply-<env>                   # terraform apply (interactive)"
	@echo "  make destroy-<env>                 # terraform destroy (interactive)"
	@echo "  make aks-credentials-<env>         # fetch AKS kubeconfig via az CLI"
	@echo "  make kubectl-apply-<env>           # kubectl apply k8s/myapp manifests (includes Ingress)"
	@echo "  make helm-install-myapp-<env>      # install myapp via Helm (bitnami/nginx)"
	@echo "  make helm-uninstall-myapp-<env>    # uninstall myapp Helm release"
	@echo "  make helm-install-traefik-<env>    # install Traefik ingress controller via Helm"
	@echo "  make helm-uninstall-traefik-<env>  # uninstall Traefik"
	@echo ""
	@echo "Examples:"
	@echo "  make init-dev"
	@echo "  make plan-stg"
	@echo "  make CLI=tofu apply-prod"

init-%:
	@$(CLI) -chdir=$(ENV_DIR)/$* init -backend-config=$(BACKEND_FILE)

plan-%:
	@$(CLI) -chdir=$(ENV_DIR)/$* plan

apply-%:
	@$(CLI) -chdir=$(ENV_DIR)/$* apply

destroy-%:
	@$(CLI) -chdir=$(ENV_DIR)/$* destroy

# Convenience: get AKS credentials using az CLI (assumes default naming)
aks-credentials-%:
	@az aks get-credentials -g rg-myapp-$* -n aks-myapp-$* --overwrite-existing

# Apply plain Kubernetes manifests (kubectl path)
kubectl-apply-%: aks-credentials-%
	@kubectl apply -f k8s/myapp/namespace.yaml
	@kubectl apply -f k8s/myapp/

# Install myapp using Helm (uses bitnami/nginx chart by default)
helm-install-myapp-%: aks-credentials-%
	@kubectl get ns myapp >/dev/null 2>&1 || kubectl create ns myapp
	@helm repo add bitnami https://charts.bitnami.com/bitnami >/dev/null 2>&1 || true
	@helm repo update >/dev/null
	@helm upgrade --install myapp bitnami/nginx -n myapp -f helm/myapp/values.yaml

helm-uninstall-myapp-%: aks-credentials-%
	@helm uninstall myapp -n myapp || true


# Install Traefik via Helm into traefik namespace
helm-install-traefik-%: aks-credentials-%
	@kubectl get ns traefik >/dev/null 2>&1 || kubectl create ns traefik
	@helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
	@helm repo update >/dev/null
	@helm upgrade --install traefik traefik/traefik -n traefik -f helm/traefik/values.yaml
	@echo "Traefik installed. Get external IP with: kubectl get svc -n traefik"

helm-uninstall-traefik-%: aks-credentials-%
	@helm uninstall traefik -n traefik || true
