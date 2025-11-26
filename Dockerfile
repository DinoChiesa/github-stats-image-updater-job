# a base image with bash, gcloud, and git installed
FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:slim

# Set the working directory inside the container
WORKDIR /app

# Copy the bash script into the container
COPY update-stats-image.sh .
COPY shlib shlib

# Make the script executable
RUN chmod +x update-stats-image.sh

# Specify the command to run when the container starts.
# For a Cloud Run Job, this is the main entrypoint.
CMD ["/bin/bash", "update-stats-image.sh"]
