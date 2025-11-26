#!/bin/bash
# -*- mode:shell-script; coding:utf-8; sh-shell:bash -*-

set -e

GH_PAT_SECRET_NAME=GitHub-PAT

source ./shlib/utils.sh

# ====================================================================

check_shell_variables CLOUDRUN_PROJECT_ID JOB_NAME JOB_REGION USER_EMAIL GH_USER
check_required_commands gcloud

printf "\nThis script creates the GH Stats Image Updater Job.\n"

# allow a cloud run job to invoke this service
PROJECT_NUMBER=$(gcloud projects describe $CLOUDRUN_PROJECT_ID --format="value(projectNumber)")
SA_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
  printf "The Service Account '%s' does not exist!\n" "$SA_EMAIL"
  printf "Cannot continue. Exiting.\n\n"
fi

if [[ -z "$SERVICE_URL" ]]; then
  SERVICE_URL="https://${SERVICE_NAME}-${PROJECT_NUMBER}.${JOB_REGION}.run.app"
  printf "using service URL: %s\n" "${SERVICE_URL}"
  printf "\nNB: The above will be right, if the service is deployed in the same project and region as the job.\n"
  printf "If not you must explicitly set the SERVICE_URL variable.\n\n"
else
  printf "using service URL: %s\n\n" "${SERVICE_URL}"
fi

gcloud run jobs deploy "${JOB_NAME}" \
  --source . \
  --tasks 1 \
  --set-env-vars GH_PAT_SECRET_NAME="${GH_PAT_SECRET_NAME}" \
  --set-env-vars SERVICE_URL=$SERVICE_URL \
  --set-env-vars USER_EMAIL=$USER_EMAIL \
  --set-env-vars GH_USER=$GH_USER \
  --max-retries 0 \
  --region "${JOB_REGION}" \
  --project="${CLOUDRUN_PROJECT_ID}"

printf "\nOK.\n\n"
printf "To execute the job, _right now_, you can use:\n\n"
printf "   gcloud run jobs execute ${JOB_NAME} --project=\"\${CLOUDRUN_PROJECT_ID}\"\n\n"
