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

.PHONY: help init-% plan-% apply-% destroy-% aks-credentials-% kubectl-apply-% helm-install-traefik-% helm-uninstall-traefik-% traefik-dashboard-% traefik-dashboard-stop traefik-force-cert-% traefik-dns-check-%

help:
	@echo "Targets:"
	@echo "  make init-<env>                    # init with backend.hcl (env = dev|stg|prod)"
	@echo "  make plan-<env>                    # terraform plan"
	@echo "  make apply-<env>                   # terraform apply (interactive)"
	@echo "  make destroy-<env>                 # terraform destroy (interactive)"
	@echo "  make aks-credentials-<env>         # fetch AKS kubeconfig via az CLI"
	@echo "  make kubectl-apply-<env>           # kubectl apply k8s/myapp manifests (includes Ingress)"
	@echo "  make helm-install-traefik-<env>    # install Traefik ingress controller via Helm"
	@echo "  make helm-uninstall-traefik-<env>  # uninstall Traefik"
	@echo "  make traefik-dashboard-<env>       # port-forward Traefik service to localhost:8080 and open dashboard"
	@echo ""
	@echo "Examples:"
	@echo "  make init-dev"
	@echo "  make plan-stg"
	@echo "  make CLI=tofu apply-prod"
	@echo "  make traefik-dashboard-dev"

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

shell-%:
	$(eval POD := $(shell kubectl get pods -n myapp -l app=myapp -o name | head -n1))
	kubectl exec -n myapp -it $(POD) -- sh

mysql-shell-%:
	$(eval POD := $(shell kubectl get pods -n myapp -l app=mysql -o name | head -n1))
	kubectl exec -n myapp -it $(POD) -- sh
#	kubectl exec -n myapp -t $(POD) -- printenv

# Install Traefik via Helm into traefik namespace
helm-install-traefik-%: aks-credentials-%
	@kubectl get ns traefik >/dev/null 2>&1 || kubectl create ns traefik
	@helm repo add traefik https://traefik.github.io/charts >/dev/null 2>&1 || true
	@helm repo update >/dev/null
	@helm upgrade --install traefik traefik/traefik -n traefik -f helm/traefik/values.yaml
	@echo "Traefik installed. Get external IP with: kubectl get svc -n traefik"

helm-uninstall-traefik-%: aks-credentials-%
	@helm uninstall traefik -n traefik || true

traefik-dashboard-%: aks-credentials-%
	$(eval PODS := $(shell kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name -n traefik))
	kubectl port-forward $(PODS) 8080:8080 -n traefik
