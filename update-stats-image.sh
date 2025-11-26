#!/bin/bash
# -*- mode:shell-script; coding:utf-8; sh-shell:bash -*-

# To run this locally, this works:
#
# mkdir -p /tmp/gcloudcreds/configurations
# cp ~/.config/gcloud/credentials.db /tmp/gcloudcreds
# cp ~/.config/gcloud/access_tokens.db /tmp/gcloudcreds
# cp ~/.config/gcloud/configurations/config_default /tmp/gcloudcreds/configurations
# cp ~/.config/gcloud/active_config /tmp/gcloudcreds
#
# podman build -t ghub-stats-updater-job:latest .
# 
# podman run -it --rm \
#   -v "/tmp/gcloudcreds:/root/.config/gcloud:rw" \
#   -e RUNNING_LOCALLY=true \
#   -e GH_PAT_SECRET_NAME=GitHub-PAT \
#   -e PROJECT_ID=my-gcp-project \
#   -e TARGET_SA=$TARGET_SA \
#   -e SERVICE_URL=https://my-github-stats-service-1234567890.us-central1.run.app \
#   -e USER_EMAIL=email-for-use-with-git-commit@example.com \
#   -e GH_USER=YourGithubUserName \
#   ghub-stats-updater-job:latest

source ./shlib/utils.sh

# ====================================================================
printf "\nThis script generates a new image for Github Stats, and commits it to the repo.\n"

check_shell_variables GH_PAT_SECRET_NAME SERVICE_URL USER_EMAIL GH_USER

# Check if we are running in local docker
if [[ -n "$RUNNING_LOCALLY" ]]; then
  printf "Running locally; using explicit service account impersonation...\n"
  check_shell_variables PROJECT_ID TARGET_SA
  # Sets the project context for subsequent gcloud commands
  gcloud config set core/project $PROJECT_ID
  ID_TOKEN=$(gcloud auth print-identity-token --impersonate-service-account=$TARGET_SA --audiences=${SERVICE_URL})
else
  echo "Running in Cloud Run or production environment. Using default service identity."
  ID_TOKEN=$(gcloud auth print-identity-token)
fi

# For diagnostics purposes
curl https://www.googleapis.com/oauth2/v3/tokeninfo\?id_token=$ID_TOKEN

# Fetch secret and configure git
GH_TOKEN=$(gcloud secrets versions access latest --secret="$GH_PAT_SECRET_NAME")
git config --global user.name "Github stats updater bot"
git config --global user.email "$USER_EMAIL"

# 2. Clone the repo
git clone https://x-access-token:${GH_TOKEN}@github.com/${GH_USER}/${GH_USER}.git
cd DinoChiesa

mkdir -p img

# generate a new image and save to a file
IMG_FILE=./img/my-statically-generated-stats-image.svg

# In your README.md, you should have:
# ![GitHub stats](./img/my-statically-generated-stats-image.svg)

HTTP_STATUS=$(curl -s -w "%{http_code}" \
  -H "Authorization: Bearer $ID_TOKEN" \
  "${SERVICE_URL}/api?username=${GH_USER}&count_private=true" \
  -o $IMG_FILE)

if [[ "$HTTP_STATUS" -ne 200 ]]; then
  echo "Error: curl command failed to get stats image. status: $HTTP_STATUS"
  exit 1
fi

# Diagnostics
ls -l ./img

# Commit and push the change (if any)
if [[ -n $(git status --porcelain $IMG_FILE) ]]; then
  printf "Committing the updated stats image...\n"
  git add $IMG_FILE
  git commit -m "docs: Update GitHub stats image"
  git push
else
  printf "The stats image has not changed. Nothing to do.\n"
fi
