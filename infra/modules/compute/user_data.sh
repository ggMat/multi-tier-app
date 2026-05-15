#!/bin/bash
set -euxo pipefail
trap 'echo "ERROR at line $LINENO: $BASH_COMMAND" >&2' ERR
exec > >(tee -a /var/log/user-data.log) 2>&1
echo "=== App EC2 bootstrap: $(date) ==="

PROJECT="${project_name}"
REGION="${region}"
ECR_REPO_URL="${ecr_repo_url}"
SSM_PREFIX="${ssm_prefix}"
LOG_GROUP="${log_group}"
APP_PORT="${app_port}"

# Install Docker (awscli and amazon-cloudwatch-agent ship pre-installed on AL2023)
dnf install -y docker
systemctl enable --now docker

# Fetch SSM params
DB_HOST=$(aws ssm get-parameter --region "$${REGION}" --name "$${SSM_PREFIX}db/host"      --query Parameter.Value --output text)
DB_PORT=$(aws ssm get-parameter --region "$${REGION}" --name "$${SSM_PREFIX}db/port"      --query Parameter.Value --output text)
DB_NAME=$(aws ssm get-parameter --region "$${REGION}" --name "$${SSM_PREFIX}db/name"      --query Parameter.Value --output text)
DB_USER=$(aws ssm get-parameter --region "$${REGION}" --name "$${SSM_PREFIX}db/user"      --query Parameter.Value --output text)
DB_PASSWORD=$(aws ssm get-parameter --region "$${REGION}" --name "$${SSM_PREFIX}db/password" --with-decryption --query Parameter.Value --output text)
IMAGE_TAG=$(aws ssm get-parameter --region "$${REGION}" --name "$${SSM_PREFIX}app/image_tag" --query Parameter.Value --output text 2>/dev/null || echo "latest")

# Log into ECR
aws ecr get-login-password --region "$${REGION}" \
  | docker login --username AWS --password-stdin "$${ECR_REPO_URL%%/*}"

# Pull and run
docker pull "$${ECR_REPO_URL}:$${IMAGE_TAG}"

DATABASE_URL="postgresql://$${DB_USER}:$${DB_PASSWORD}@$${DB_HOST}:$${DB_PORT}/$${DB_NAME}"

docker run -d --name app --restart unless-stopped \
  -p $${APP_PORT}:$${APP_PORT} \
  -e DB_HOST="$${DB_HOST}" \
  -e DB_PORT="$${DB_PORT}" \
  -e DB_NAME="$${DB_NAME}" \
  -e DB_USER="$${DB_USER}" \
  -e DB_PASSWORD="$${DB_PASSWORD}" \
  -e DATABASE_URL="$${DATABASE_URL}" \
  -e APP_PORT="$${APP_PORT}" \
  --log-driver=awslogs \
  --log-opt awslogs-region="$${REGION}" \
  --log-opt awslogs-group="$${LOG_GROUP}" \
  --log-opt awslogs-create-group=true \
  "$${ECR_REPO_URL}:$${IMAGE_TAG}"

# Wait for /health to come up
for i in {1..24}; do
  if curl -fs "http://localhost:$${APP_PORT}/health" >/dev/null 2>&1; then
    echo "App healthy"; exit 0
  fi
  sleep 5
done

echo "App failed to become healthy" >&2
docker logs app >&2 || true
exit 1
