# Infrastructure TODO List

This checklist outlines the tasks to provision an environment using Terraform that includes networking, a MySQL 8 database (Flexible Server/cluster), a Kubernetes cluster, and an example nginx-based app exposed via 80/443 at myapp.domain.tld. Bonus: Traefik as ingress.

Note: "Flexible Server" terminology aligns with Azure Database for MySQL Flexible Server; the plan below assumes Azure (AKS for Kubernetes). Adapt names if using another cloud.

Context for this project (decisions provided):
- Provider: Azure
- Region: northeurope
- Project: myapp
- Domain: already registered; app FQDN = myapp.domain.tld
- TLS strategy: Traefik with ACME (Let's Encrypt)

## 0. Prerequisites and Decisions
- [ ] Provider/region: Azure, northeurope (decided).
- [ ] Define naming conventions and tags (project, env, owner, cost-center, compliance scopes).
- [ ] Environments: dev/stg/prod (decided). Choose workspace or separate states.
- [ ] Decide network model (hub-spoke or flat VNet) and address ranges.
- [ ] Domain: already registered. Ensure Azure DNS zone exists and/or delegation is set correctly for domain.tld. Manage A/AAAA for myapp.domain.tld.
- [ ] Cert strategy: Traefik ACME (Let's Encrypt) (decided).
- [ ] Access control approach (Azure RBAC, Kubernetes RBAC) and secret store (Kubernetes Secret, Azure Key Vault).

## 1. Terraform Scaffolding
- [ ] Create Terraform root module structure: envs/(dev|stage|prod), modules/, main providers.
- [ ] Configure backend for remote state (AWS S3 + state locking via DynamoDB).
- [ ] Define providers: azurerm (with features {}), kubernetes, helm (configured post-AKS creation).
- [ ] Create variables.tf and outputs.tf in root and modules. Establish tfvars per environment.
- [ ] Establish workspaces or separate state per environment.
- [ ] Add pre-commit hooks (fmt, validate, tflint, tfsec) and GitHub Actions/Azure DevOps pipeline for plan/apply (manual approval for prod).

## 2. Networking (Azure)
- [x] Create Resource Group(s) (network, data, aks, shared if desired).
- [x] Create VNet with address space, e.g., 10.0.0.0/16.
- [x] Subnets:
  - [x] aks-subnet (e.g., 10.0.1.0/24)
  - [x] db-subnet (delegated for MySQL Flexible Server)
  - [x] pe-subnet for Private Endpoints (if using private access)
- [ ] Network Security Groups (NSGs) and rules; associate to subnets where applicable.
- [ ] Azure Firewall or basic outbound rules as needed.
- [ ] Private DNS zones for MySQL and Private Endpoints if using private networking.
- [ ] Public Static IP for ingress controller.

## 3. MySQL 8 Flexible Server / Cluster
- [ ] Create Azure Database for MySQL Flexible Server (version 8.0), with HA zone-redundant if needed.
- [ ] Configure compute/storage sizing, auto-grow, backup retention, maintenance window.
- [ ] Networking:
  - [ ] Private access via VNet integration (recommended) OR public with firewall rules.
  - [ ] Private Endpoint + Private DNS zone link.
- [ ] Create DB admin credentials via Terraform with sensitive outputs suppressed.
- [ ] Create an application database (e.g., appdb) and a dedicated DB user with least privilege.
- [ ] Store app DB credentials in Key Vault or as Kubernetes Secret data provisioned via Terraform.
- [ ] Optionally set up MySQL Flexible Server High Availability and read replicas for scaling.
- [ ] Outputs: hostname, port, db name, username, secret references.

## 4. Kubernetes Cluster (AKS)
- [ ] Provision AKS cluster with system and user node pools.
- [ ] Enable network plugin (Azure CNI), kube-dns, and specify AKS subnet.
- [ ] Enable AAD integration, RBAC, secrets encryption at rest with CMK if required.
- [ ] Configure cluster autoscaler and node sizing.
- [ ] Outputs: kubeconfig, cluster name, resource group.

## 5. Ingress Controller and TLS
- Option A (Preferred): Traefik
  - [ ] Install Traefik via Helm into traefik namespace.
  - [ ] Allocate a static public IP in Azure and set Service of type LoadBalancer to use it (service.annotations loadBalancerIP or values override).
  - [ ] Configure ACME/Let's Encrypt resolver (HTTP-01) with contact email, storage, and entrypoints web/websecure.
  - [ ] Create IngressRoute (or standard Ingress if preferred) for myapp.domain.tld pointing to the app Service.
  - [ ] Verify automatic certificate provisioning via Traefik ACME for myapp.domain.tld.
  - [ ] Optionally enable dashboard (secured) and middlewares (rate-limit, headers, redirect).
- Option B (Alternative): NGINX Ingress Controller
  - [ ] Install via Helm chart into kube-system or ingress-nginx namespace.
  - [ ] Allocate static public IP from Azure and attach to Service of type LoadBalancer.
  - [ ] Configure IngressClass and default backend.
  - [ ] Install cert-manager and configure ClusterIssuer (ACME HTTP-01) if you choose NGINX path.

## 6. Example App (nginx) and Service
- [ ] Create a Kubernetes Namespace: myapp.
- [ ] Create a ConfigMap for nginx default.conf if custom routing is desired.
- [ ] Create a Deployment using nginx:stable image (or pinned version), replicas >= 2.
- [ ] Create a Service (ClusterIP) exposing port 80.
- [ ] Create an Ingress resource for myapp.domain.tld routing to the Service.
- [ ] Ensure TLS via cert-manager or Traefik ACME with certificate resource.

## 7. App-to-DB Connectivity and Secrets
- [ ] Prepare Kubernetes Secret containing database connection info:
  - [ ] DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD
- [ ] Mount as env variables in a sample sidecar or placeholder container (since nginx alone doesn’t use DB). Alternatively, use a minimal app that verifies DB connectivity.
- [ ] Network controls: allow AKS subnet to reach MySQL (via Private Endpoint or firewall rule).
- [ ] Test connectivity via a Job/Pod that reads the secret and attempts tcp/mysql handshake.

## 8. DNS and Certificates
- [ ] Domain already registered: ensure public DNS zone for domain.tld exists in Azure DNS (or verify delegation from registrar).
- [ ] Create A/AAAA record for myapp.domain.tld pointing to the Traefik LoadBalancer public static IP.
- [ ] Verify issuance of TLS cert for myapp.domain.tld via Traefik ACME (HTTP-01).

## 9. Observability, Security, and Ops
- [ ] Enable Azure Monitor/Container Insights for AKS.
- [ ] Enable MySQL metrics and alert rules (CPU, connections, storage, replication lag).
- [ ] Set up logs and retention policies.
- [ ] Backups and restore testing for MySQL (perform PITR test).
- [ ] Define Network Policies (deny-all default; allow only necessary egress/ingress).
- [ ] Secrets management policy (rotation, RBAC restrictions, audit).
- [ ] Cost monitoring and budgets.

## 10. CI/CD and Automation
- [ ] Pipeline to run terraform fmt/validate/plan/apply per environment with manual gates.
- [ ] Pipeline to deploy Helm charts/manifests to AKS.
- [ ] Store kubeconfig and cloud credentials securely in pipeline secrets.

## 11. Validation
- [ ] terraform validate and tflint clean.
- [ ] terraform plan shows expected changes; apply in dev.
- [ ] kubectl get nodes/pods/services/ingress confirm resources are healthy.
- [ ] Access https://myapp.domain.tld returns nginx welcome page over HTTPS.
- [ ] Database connectivity test pod/job succeeds with secrets.

## 12. Documentation
- [ ] README with architecture diagram and instructions for bootstrap & teardown.
- [ ] Record decisions, defaults, and how to rotate secrets and renew certs.

---

Reminders: Things you might be missing
- [ ] Choose and document whether MySQL is private-only (recommended) and how developers access it (bastion/jumpbox or Data Proxy).
- [ ] Explicitly pin container image versions and Helm chart versions to avoid breaking changes.
- [ ] Disaster Recovery: cross-region failover strategy for MySQL and AKS backups (Velero).
- [ ] Sizing and autoscaling policies (HPA/VPA) for workloads.
- [ ] Compliance requirements (encryption at rest/in transit, key management, policies).
- [ ] Runbooks for on-call, incident management, SLOs/SLIs.
- [ ] Testing strategy: integration tests for DB access, smoke tests for ingress.
- [ ] Access patterns: jumpbox or VPN for private resources if using private endpoints.
- [ ] Quotas and service limits in target subscription.
- [ ] Rotate DB user password and TLS cert automation cadence.
