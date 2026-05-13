# Multi-tier Portfolio App

A 3-tier AWS application (ALB → EC2 → RDS PostgreSQL) deployed with Terraform and GitHub Actions. Portfolio piece demonstrating networking, IAM, IaC, containerized deploys, and CI/CD with OIDC.

## Architecture

- **VPC** with public + private subnets across 2 AZs in `eu-central-1`
- **ALB** (HTTP :80) in public subnets → **EC2** in private subnets running the Flask app in Docker → **RDS PostgreSQL** in private subnets
- **NAT instance** (t2.micro) for private-subnet egress to ECR/SSM/CloudWatch
- **Bastion** (t2.micro) for `psql` admin access via SSH tunnel
- **ECR** holds the app image; **SSM Parameter Store** holds DB credentials and the current image tag

## API

- `GET /health` — `{"status":"ok"}` (or 503 if DB unreachable)
- `GET|POST /authors`, `GET|PUT|DELETE /authors/<id>`
- `GET|POST /books`, `GET|PUT|DELETE /books/<id>`, supports `?author_id=<id>` filter

## Quickstart (cold bring-up)

```bash
# 1. SSH key
ssh-keygen -t ed25519 -f ~/.ssh/multi-tier-app -N ""

# 2. Set your IP and a DB password
export TF_VAR_db_password="$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)"
# Edit infra/terraform.tfvars: admin_cidr = "<your-ip>/32", github_repo = "<owner>/<repo>"

# 3. Apply
cd infra && terraform init && terraform apply

# 4. Push the first image (after this, CI takes over)
gh workflow run app.yml --ref main

# 5. Hit it
curl "http://$(terraform output -raw alb_dns_name)/health"
```

## Tear-down

```bash
cd infra && terraform destroy
```

The S3 backend bucket and CloudWatch log groups survive on purpose; everything else is recreatable.

## DB admin access

```bash
BASTION=$(cd infra && terraform output -raw bastion_public_ip)
RDS=$(cd infra && terraform output -raw rds_endpoint)
ssh -i ~/.ssh/multi-tier-app -L 5432:$RDS:5432 -N ec2-user@$BASTION
# in another shell:
psql -h localhost -U app_user -d multitier
```

## App EC2 access

```bash
aws ssm start-session --target <instance-id>
docker logs $(docker ps -q)
```

## Local development

```bash
python -m venv .venv && .venv/bin/activate
pip install -r requirements-dev.txt
pytest                       # uses testcontainers Postgres
docker build -t mta:dev .    # build the image locally
```

## Production hardening (intentionally out of scope for v1)

This is a portfolio piece. The following would be added in a real deployment:

- **HTTPS on ALB** — request an ACM cert for a Route 53 domain, add an HTTPS listener, redirect 80→443
- **Multi-AZ RDS, ASG, NAT** — currently single-AZ to fit free tier
- **`deletion_protection = true`** on RDS
- **Tighter IAM** — replace `PowerUserAccess` on `gha_infra_role` with a least-privilege policy
- **Alembic** for migrations instead of the idempotent `001_init.sql`
- **CloudWatch alarms** for ALB 5xx, RDS CPU, ASG unhealthy hosts
- **WAF, GuardDuty, Inspector**
- **Secrets rotation** via Secrets Manager + Lambda
- **ECR scan-on-push** result gating in CI

## CI/CD

Two GitHub Actions workflows:

- `.github/workflows/app.yml` — on push to `main` affecting app code: test → build → push to ECR → ASG instance refresh
- `.github/workflows/infra.yml` — on PR: `fmt`/`validate`/`plan` (posted as PR comment); on push to `main`: auto-apply

Both use OIDC federation — no long-lived AWS keys in GitHub.

## Rough running cost (eu-central-1, on-demand)

≈ €0.05/h during free tier, €0.10/h after. Each demo cycle (apply, smoke test, destroy) is well under €1.
