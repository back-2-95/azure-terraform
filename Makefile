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

.PHONY: help init-% init-local-% plan-% apply-%

help:
	@echo "Targets:"
	@echo "  make init-<env>        # init with backend.hcl (env = dev|stg|prod)"
	@echo "  make plan-<env>        # terraform plan"
	@echo "  make apply-<env>       # terraform apply (interactive)"
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
