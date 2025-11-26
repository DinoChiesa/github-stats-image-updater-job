#!/bin/bash
# -*- mode:shell-script; coding:utf-8; sh-shell:bash -*-

set -e

GH_PAT_SECRET_NAME=GitHub-PAT

source ./shlib/utils.sh

# ====================================================================

check_shell_variables CLOUDRUN_PROJECT_ID JOB_NAME JOB_REGION
check_required_commands gcloud

printf "\nThis script creates the GH Stats Image Updater Job.\n"

# allow a cloud run job to invoke this service
PROJECT_NUMBER=$(gcloud projects describe $CLOUDRUN_PROJECT_ID --format="value(projectNumber)")
SA_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  printf "The Service Account '%s' does not exist!\n" "$SA_EMAIL"
  printf "Cannot continue. Exiting.\n\n"
fi

gcloud run jobs deploy "${JOB_NAME}" \
  --source . \
  --tasks 1 \
  --set-env-vars GH_PAT_SECRET_NAME="${GH_PAT_SECRET_NAME}" \
  --max-retries 0 \
  --region "${JOB_REGION}" \
  --project="${CLOUDRUN_PROJECT_ID}"

printf "\nOK.\n\n"
printf "To execute the job, _right now_, you can use:\n\n"
printf "   gcloud run jobs execute ${JOB_NAME} --project=\"\${CLOUDRUN_PROJECT_ID}\"\n\n"
