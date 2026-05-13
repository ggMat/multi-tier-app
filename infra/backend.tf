terraform {
  backend "s3" {
    bucket  = "my-remote-terraform-states-405989524795"
    key     = "portfolio/multi-tier-app/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
    # dynamodb_table = "terraform-locks"  # TODO: enable for team use
  }
}
