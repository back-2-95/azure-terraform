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
- Terraform CLI 1.6+
- AWS S3 bucket for storing Terraform state
- (Recommended) DynamoDB table for state locking
  - Table name of your choice; primary key: LockID (String)
- AWS credentials available to Terraform when initializing (e.g., environment variables, AWS profile)

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

2) Initialize Terraform in the environment directory
- cd envs/dev
- terraform init -backend-config=backend.hcl

3) Plan/apply as you add real resources
- terraform plan
- terraform apply

Notes
- Backends cannot use Terraform variables; that’s why we provide backend.hcl files and pass them at init time.
- Although we deploy Azure resources, using S3 for state is fully supported and keeps state external to the Azure subscription.
- Keep backend.hcl values generic and do not commit credentials; authentication to AWS should come from your environment or configured profile.

Next steps (see TODO.md)
- Add actual Terraform code for networking, AKS, MySQL Flexible Server, and ingress.
- Introduce modules and per-environment variables/outputs as the implementation progresses.
- Add CI/CD to run fmt/validate/plan and to gate prod applies.
