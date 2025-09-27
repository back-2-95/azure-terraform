# myapp Azure Terraform scaffolding (envs + remote state)

This repository currently contains multi-environment scaffolding, remote Terraform state, and baseline Azure networking (resource group + VNet + subnets) provisioned via a reusable Terraform module. See TODO.md for the full implementation plan.

Context and decisions
- Cloud: Azure (AKS, MySQL Flexible Server planned)
- Region: northeurope
- Project: myapp
- Domain: myapp.domain.tld (already registered)
- Ingress/TLS preference: Traefik with ACME
- Environments: dev, stg, prod
- Terraform state: stored in external AWS S3 bucket with optional DynamoDB table for state locking

What’s included now
- Environment folders: envs/dev, envs/stg, envs/prod
  - Each environment has:
    - main.tf with: 
      - Terraform core configuration and an S3 backend stub (empty body; configured at init time)
      - AzureRM provider (features {})
    - backend.hcl with placeholders for S3 bucket, key, region, and optional DynamoDB table
- Updated TODO.md to reflect:
  - Environments decided (dev/stg/prod)
  - Remote state via S3 + DynamoDB (instead of Azure Storage)

Prerequisites for using the current scaffolding
- Terraform CLI 1.6+ or OpenTofu CLI 1.6+
- AWS S3 bucket for storing Terraform state
- (Recommended) DynamoDB table for state locking
  - Table name of your choice; primary key: LockID (String)
- AWS credentials available to the chosen CLI (Terraform/OpenTofu) when initializing (e.g., environment variables, AWS profile)

How remote state works here
- The backend is defined as backend "s3" {} in main.tf for each environment.
- Actual backend values are supplied at init time using the environment-specific backend.hcl files.
- This allows different buckets/keys per environment and avoids hardcoding credentials.

Setup instructions per environment
Example below uses dev; stg/prod are identical with their own backend.hcl.

1) Edit envs/dev/backend.hcl
- Set:
  - bucket = "<your-s3-bucket>"
  - key    = "myapp/dev/terraform.tfstate" (you can keep this default)
  - region = "<s3-bucket-region>" (example: eu-north-1)
  - dynamodb_table = "<your-dynamodb-table>" (optional but recommended)

2) Initialize in the environment directory
- cd envs/dev
- With Terraform: terraform init -backend-config=backend.hcl
- With OpenTofu: tofu init -backend-config=backend.hcl
- With tf wrapper: tf init -backend-config=backend.hcl

3) Create a plan
- With Terraform: terraform plan
- With OpenTofu: tofu plan
- With tf wrapper: tf plan

4) Apply (optional)
- With Terraform: terraform apply
- With OpenTofu: tofu apply
- With tf wrapper: tf apply

Notes
- Backends cannot use Terraform variables; that’s why we provide backend.hcl files and pass them at init time.
- Although we deploy Azure resources, using S3 for state is fully supported and keeps state external to the Azure subscription.
- Keep backend.hcl values generic and do not commit credentials; authentication to AWS should come from your environment or configured profile.

Next steps (see TODO.md)
- Add actual Terraform code for networking, AKS, MySQL Flexible Server, and ingress.
- Introduce modules and per-environment variables/outputs as the implementation progresses.
- Add CI/CD to run fmt/validate/plan and to gate prod applies.


## How to use backend.local.hcl files (quick guide)
backend.local.hcl files in each env directory are pre-configured to use the local MinIO S3-compatible service from compose.minio.yaml. Use them when you want to run Terraform without a real AWS S3 bucket.

Use with Makefile:
- Start MinIO: docker compose -f compose.minio.yaml up -d
- Initialize per env with the local backend:
  - make init-local-dev
  - make init-local-stg
  - make init-local-prod
- Then run plan/apply as usual, e.g.: make plan-dev, make apply-dev

Use directly with the CLI:
- cd envs/dev && terraform init -backend-config=backend.local.hcl

Switching between backends:
- If you previously initialized against a different backend, run init with -migrate-state to move state safely:
  - terraform init -migrate-state -backend-config=backend.local.hcl
  - terraform init -migrate-state -backend-config=backend.hcl

Notes:
- Do not commit credentials; backend.local.hcl uses example credentials valid only for the local MinIO container.
- State locking via DynamoDB is not available with MinIO. For teams or locking tests, use real AWS (backend.hcl) or LocalStack with DynamoDB.

## Using a local S3 backend with Docker (MinIO)
You can simulate an S3 backend locally using MinIO. This is useful for development or demos when you don’t want to use a real AWS S3 bucket.

What you’ll get
- A local S3-compatible endpoint at http://localhost:9000
- A MinIO web console at http://localhost:9001
- An S3 bucket named tfstate created automatically

Start MinIO
1) From the repository root, start the stack:
   - docker compose -f compose.minio.yaml up -d
2) Open the console at http://localhost:9001 (user: minioadmin, password: minioadmin123) if you want to browse objects.

Use the local backend.hcl (per environment)
- We’ve added backend.local.hcl in each environment folder configured for MinIO.
- Example for dev:
  - cd envs/dev
  - terraform init -backend-config=backend.local.hcl
  - terraform plan

Notes and limitations
- MinIO does not provide DynamoDB; state locking via DynamoDB is therefore not available. For solo development, this is fine.
- If you need to test state locking locally, consider LocalStack (S3 + DynamoDB). In that case your backend config would include dynamodb_table and point the endpoint to LocalStack. If you want, we can add a ready-made docker-compose for LocalStack as well.
- The S3 backend requires force_path_style = true and several skip_* checks when using MinIO. These are already set in backend.local.hcl.
- The example credentials in backend.local.hcl are for the local MinIO container only. Do not reuse them elsewhere.

Troubleshooting
- If terraform init cannot connect, ensure the MinIO container is running and port 9000 is free.
- If you previously initialized the backend against a different remote, run: terraform init -migrate-state -backend-config=backend.local.hcl
- To reset the local MinIO data, stop the stack and remove the named volume: docker compose -f docker-compose.minio.yml down -v
