# set these settings for your own project
export CLOUDRUN_PROJECT_ID=my-gcp-project-id
export JOB_REGION=us-west1
export USER_EMAIL=something-appropriate@example.com
export GH_USER=YourGithubUserName

# Probably you can keep these the same:
export JOB_NAME=github-stats-image-updater
export SERVICE_NAME=my-github-stats-service

# try https://crontab.guru/#2_*/3_*_*_* to get a schedule string.
# Eg, every day, at 23:54
export SCHEDULE="54 23 * * *"

# The timezone that this time is relative to
export SCHEDULE_TZ="America/Los_Angeles"
