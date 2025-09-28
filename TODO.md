# Infrastructure TODO List (Refactored)

This checklist tracks the implementation of an Azure environment via Terraform that includes networking, a MySQL 8 Flexible Server, an AKS cluster, and an example app exposed at https://azure-terraform.ineen.net using Traefik and Let's Encrypt.

Notes:
- Cloud: Azure (AKS for Kubernetes)
- Region: `northeurope`
- Project: `myapp`
- Domain/FQDN: azure-terraform.ineen.net
- TLS/Ingress: Traefik with ACME (Let’s Encrypt). Current values use DNS-01 via Azure DNS and ACME staging.
- Remote state: S3 backend (with optional DynamoDB locking). Local development supported via MinIO.

## 0. Prerequisites and Decisions
- [x] Provider/region decided: Azure, northeurope.
- [x] Naming conventions and baseline tags: project/env plus owner via modules/common.
- [x] Environments: dev, stg, prod. Separate state per environment (env folders + backend configs).
- [x] Network model: flat VNet per environment with aks/db/pe subnets and defined CIDRs.
- [x] Domain: registered; FQDN = azure-terraform.ineen.net. Use Azure DNS zone for records.
- [x] Cert strategy: Traefik ACME. ACME staging server configured in Helm values; switch to prod when ready.
- [ ] Access control approach (Azure RBAC, Kubernetes RBAC hardening) and secret store policy (Key Vault/K8s secrets).

## 1. Terraform Scaffolding
- [x] Root structure: envs/(dev|stg|prod), modules/, providers in place.
- [x] Backend for remote state: backend "s3" with per-env backend.hcl; local MinIO backend supported via compose.minio.yaml and README.
- [x] Providers defined: azurerm (features {}), kubernetes configured from AKS outputs. Helm to be used during Traefik install.
- [ ] variables.tf/outputs.tf at root and standardized tfvars per environment.
- [x] Separate state per environment (no shared workspaces).
- [ ] Pre-commit hooks (fmt, validate, tflint, tfsec) and CI/CD pipeline for plan/apply (manual approval for prod).

## 2. Networking (Azure)
- [x] Resource Group per environment (via modules/network).
- [x] Virtual Network with address space.
- [x] Subnets:
  - [x] aks-subnet
  - [x] db-subnet
  - [x] pe-subnet (for Private Endpoints)
- [ ] Network Security Groups (NSGs) and rules; associate where applicable.
- [ ] Azure Firewall or egress restrictions as needed.
- [ ] Private DNS zones for MySQL/PE if using private networking.
- [ ] Public Static IP for ingress controller (and annotation/assignment on Service).

## 3. MySQL 8 Flexible Server
- [x] Flexible Server module present and enabled in stg/prod (dev pending). Version 8.0.x.
- [x] Compute/storage sizing defined (dev smallest planned, stg/prod GP sizes).
- [ ] Networking:
  - [ ] Private access via VNet/PE (recommended) OR controlled public with firewall.
  - [ ] Private Endpoint + Private DNS zone link.
- [x] Admin credentials sourced from Key Vault (Key Vault module enabled in stg/prod).
- [ ] Application database/user with least privilege.
- [ ] Store app DB connection values for workloads (Key Vault/K8s Secret wiring).
- [ ] Optional HA/read replicas.
- [x] Outputs: hostname (FQDN), port, admin username (password is sensitive).

## 4. Kubernetes Cluster (AKS)
- [x] AKS cluster provisioned via module with Azure CNI; system node pool present.
- [ ] Additional user node pools if needed.
- [x] RBAC enabled (baseline). AAD integration and CMK encryption not configured yet.
- [ ] Cluster autoscaler and final node sizing policies.
- [x] Outputs: kubeconfig connection data available from module.

## 5. Traefik as Ingress Controller and TLS
- [x] Install Traefik via Helm into traefik namespace using helm/traefik/values.yaml (values prepared).
- [x] Allocate a static public IP in Azure and attach to Traefik Service (LoadBalancer).
- [x] ACME configured in values.yaml using Azure DNS (DNS-01) and staging CA; storage at /data/acme.json.
- [ ] Create Ingress or IngressRoute for azure-terraform.ineen.net pointing to app Service (YAML provided under k8s/myapp, apply once Traefik is up).
- [ ] Verify certificate issuance via Traefik ACME and HTTPS routing.
- [x] Optional: Traefik dashboard enabled in values.yaml (secure accordingly).

## 6. Example App and Service
- [x] Kubernetes Namespace: myapp (YAML and Terraform examples exist).
- [x] Deployment: sample app (traefik/whoami) provided in k8s manifests; stg/prod Terraform define nginx deployment with 2 replicas.
- [x] Service: ClusterIP in manifests; stg/prod Terraform example uses LoadBalancer (can switch to ClusterIP when Traefik is used).
- [x] Ingress: k8s/myapp/Ingress.yaml targets azure-terraform.ineen.net with Traefik annotations.
- [ ] Pin container image/chart versions to avoid drift.

## 7. App-to-DB Connectivity and Secrets
- [ ] Kubernetes Secret for DB connection info (DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD).
- [ ] Wire env vars into a test pod or minimal app to verify DB connectivity.
- [ ] Network controls: allow AKS subnet to reach MySQL (via Private Endpoint or firewall rule).
- [ ] Connectivity test via Job/Pod performing MySQL handshake.

## 8. DNS and Certificates
- [x] Azure DNS zone present/managed for ineen.net (assumed). Confirm delegation.
- [x] Create/verify A/AAAA for azure-terraform.ineen.net pointing to Traefik LB public static IP.
- [x] Switch ACME to production CA server and verify cert issuance.

## 9. Observability, Security, and Ops
- [x] Enable Azure Monitor/Container Insights for AKS.
- [ ] MySQL metrics/alerts (CPU, connections, storage, replication lag).
- [ ] Log retention policies.
- [ ] Backups and restore testing for MySQL (PITR test).
- [ ] Network Policies (default deny; allow necessary egress/ingress).
- [ ] Secrets rotation policy and RBAC hardening.
- [ ] Cost monitoring and budgets.

## 10. CI/CD and Automation
- [ ] Pipeline for terraform fmt/validate/plan/apply per environment with manual gates.
- [ ] Pipeline to deploy Helm charts/manifests.
- [ ] Store kubeconfig and cloud credentials in pipeline secrets.

## 11. Validation
- [ ] terraform validate and tflint clean.
- [ ] terraform plan shows expected changes; apply in dev.
- [ ] kubectl get nodes/pods/services/ingress show healthy resources.
- [ ] Access https://azure-terraform.ineen.net returns app over HTTPS.
- [ ] Database connectivity test pod/job succeeds.

## 12. Documentation
- [x] README with decisions, remote state, networking diagram, and local MinIO guide.
- [ ] Record operational runbooks (secret rotation, cert renewal, disaster recovery).

---

Reminders / Nice-to-haves
- [ ] Decide on MySQL private-only access and developer access strategy (bastion/VPN/Data Proxy).
- [ ] Disaster Recovery: cross-region for MySQL and AKS backups (Velero).
- [ ] HPA/VPA policies for workloads.
- [ ] Compliance: encryption at rest/in transit, key management, policies.
- [ ] On-call runbooks, incident management, SLOs/SLIs.
- [ ] Integration tests for DB access, ingress smoke tests.
- [ ] Subscription quotas/service limits review.
- [ ] Rotate DB user passwords and schedule cert renewals.
