#!/bin/bash
# -*- mode:shell-script; coding:utf-8; sh-shell:bash -*-

source ./shlib/utils.sh

# ====================================================================
printf "\nThis script generates a new image for Github Stats, and commits it to the repo.\n"

check_shell_variables GH_PAT_SECRET_NAME

# --- Impersonation Logic Start ---
# Check if we are running in local docker (i.e., if the mounted ADC file exists)
if [[ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then

  printf "We think we are running locally...\n"
  printf "\nADC:\n"
  cat "$GOOGLE_APPLICATION_CREDENTIALS"
  printf "\n\n"
  check_shell_variables PROJECT_ID TARGET_SA

  # --- 1. Use ADC to Generate the Impersonated Token ---

  # once for diagnostics
  gcloud auth print-access-token \
    --impersonate-service-account="$TARGET_SA" \
    --lifetime=180s

  # second time to capture the token
  IMPERSONATED_ACCESS_TOKEN=$(gcloud auth print-access-token \
    --impersonate-service-account="$TARGET_SA" \
    --lifetime=180s)

  if [ -z "$IMPERSONATED_ACCESS_TOKEN" ]; then
    echo "FATAL: Could not generate impersonated token. Check 'Service Account Token Creator' role on user."
    exit 1
  fi

  echo "Impersonated token generated successfully."

  # --- 2. Force gcloud CLI to use the Token and Project ID ---
  # Sets the token for all subsequent gcloud commands
  gcloud config set access_token $IMPERSONATED_ACCESS_TOKEN

  # Sets the project context for subsequent gcloud commands
  gcloud config set core/project $PROJECT_ID

  echo "THiS NEVER WoRKeD"
  # I guess I still need this?
  gcloud config set auth/impersonate_service_account $TARGET_SA
  echo "Successfully set impersonation for gcloud commands."
else
  echo "Running in Cloud Run or production environment. Using default service identity."
fi
# --- Impersonation Logic End ---

# 1. Fetch secret and configure git
TOKEN=$(gcloud secrets versions access latest --secret="$GH_PAT_SECRET_NAME")
git config --global user.name "Github stats updater bot"
git config --global user.email "dpchiesa@hotmail.com"

# 2. Clone the repo
git clone https://x-access-token:${TOKEN}@github.com/DinoChiesa/DinoChiesa.git
cd DinoChiesa

mkdir -p img
# generate a new image and save to a file
SERVICE_URL=https://my-github-stats-service-511582533367.us-west1.run.app
TOKEN=$(gcloud auth print-identity-token)

# For diagnostics purposes
# curl -i https://www.googleapis.com/oauth2/v3/tokeninfo\?id_token=$TOKEN

HTTP_STATUS=$(curl -s -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" \
  "${SERVICE_URL}/api?username=DinoChiesa&count_private=true" \
  -o ./img/my-statically-generated-stats-image.svg)

if [[ "$HTTP_STATUS" -ne 200 ]]; then
    echo "Error: curl command failed to get stats image. status: $HTTP_STATUS"
    exit 1
fi

ls -l ./img

# 4. Commit and push the change (if any)
if [[ -n $(git status --porcelain ./img/my-statically-generated-stats-image.svg) ]]; then
  printf "The stats image has changed. Committing...\n"
  git add ./img/my-statically-generated-stats-image.svg
  git commit -m "docs: Update GitHub stats image" && git push
else
  printf "The stats image has not changed. Nothing to do.\n"
fi
