bucket         = "CHANGE_ME_state_bucket"
key            = "myapp/dev/terraform.tfstate"
region         = "eu-north-1"
encrypt        = true
# Optional, recommended for state locking
# Create the table with primary key LockID (string)
dynamodb_table = "CHANGE_ME_tf_lock"
