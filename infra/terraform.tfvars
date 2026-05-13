region = "eu-central-1"

tags = {
  Project = "portfolio-multi-tier-app"
  Env     = "production"
  Owner   = "luigi.matera"
}

admin_cidr  = "0.0.0.0/32"           # OVERRIDE with `curl ifconfig.me/32` before apply
github_repo = "luigi-matera/multi-tier-app"   # adjust to actual repo
