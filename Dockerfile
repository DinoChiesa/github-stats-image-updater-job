# a base image with bash, gcloud, and git already installed
FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:slim

WORKDIR /app

COPY update-stats-image.sh .
COPY shlib shlib

RUN chmod +x update-stats-image.sh

CMD ["/bin/bash", "update-stats-image.sh"]
