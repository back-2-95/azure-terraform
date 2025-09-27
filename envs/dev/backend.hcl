bucket                      = "tfstate"
key                         = "myapp/dev/terraform.tfstate"
region                      = "us-east-1"
endpoint                    = "http://localhost:9000"
access_key                  = "minioadmin"
secret_key                  = "minioadmin123"
skip_credentials_validation = true
skip_requesting_account_id  = true
skip_metadata_api_check     = true
force_path_style            = true
# Note: DynamoDB locking is not available with MinIO; omit dynamodb_table
