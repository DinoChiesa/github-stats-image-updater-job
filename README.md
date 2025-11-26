# Summary

This is a Cloud Run job that invokes a service to generate a github stats image,
then updates my own (or your own) GitHub repo with the updated image.

I built this because the [github-readme-stats vercel app](https://github-readme-stats.vercel.app) hosted by Anurag Hazra,
is shared and apparently is experiencing overuse or 503s.

Anurag had (has?) a service that generates an image that you can include in your own personal README.md,
available at github.com/YourUserName/YourUserName . The markup you need to use that service is:

```
  ![GitHub stats](https://github-readme-stats.vercel.app/api?username=YourGithubUserName&count_private=true)
```

But the service is shared and currently (2025 November) is returning 503, which means you get no image.

So, I did this:

- Cloned Anurag's repo https://github.com/anuraghazra/github-readme-stats

- Made a few changes (See [this repo](https://github.com/DinoChiesa/github-readme-stats)) to
  stand it up as Cloud Run SERVICE, which requires authentication, and scales to 0.

- Created this Cloud Run JOB, which invokes the service, saves the generated svg
  file, and pushes the updated image to my own repo.

- Configured the job to run on a schedule, once nightly.


Now, instead of
```
  ![GitHub stats](https://github-readme-stats.vercel.app/api?username=DinoChiesa&count_private=true)
```

...my Readme has this markup:
```
  ![GitHub stats](./img/my-statically-generated-stats-image.svg)
```

And I get the correct image.

Example (this image is not up to date!):

  ![GitHub stats](./img/my-statically-generated-stats-image.svg)



## Details

The job is just [a shell script](./update-stats-image.sh). It follows this logic:

- Get an Identity Token suitable for use with the Cloud Run service
- git clone my own personal GH Repo
- Invoke the service with the identity token, saving the generated svg file.
- If changed, commit the changed image

## Setup

You can configure this job yourself, for your own repo. 
It  depends on an image generation service as provided by [this repo](https://github.com/DinoChiesa/github-readme-stats).
So you need to first set that up! 

Once you do that, then...:

1. Set up your environment. Edit [the env-sample file](./env-sample.sh).
   Save it as "env.sh".

2. Open a bash terminal. Make the environment variables current:
   ```
   source ./env.sh
   ```

3. Provision the shell script as a Cloud Run job. Do this with:
   ```
   1-create-job.sh
   ```

4. Configure Cloud Scheduler to run the job on a schedule, eg, nightly.
   ```
   2-create-scheduler.sh
   ```

That's it!


## Testing locally

To test the container locally, you must have [gcloud CLI](https://docs.cloud.google.com/sdk/docs/install) installed.

1. Open a bash terminal.

2. Login for gcloud
   ```sh
   gcloud auth login
   ```

3. Grant yourself "serviceAccountTokenCreator" on the default compute service account.
   ```sh
   PROJECT_ID=your-gcp-project-id
   PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
   SA_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
   GWHOAMI=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

   gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
     --member="user:$GWHOAMI" \
     --role="roles/iam.serviceAccountTokenCreator"
   ```

4. Build the container.

   If using docker CLI:
   ```sh
   docker build -t ghub-stats-updater-job:latest .
   ```

   If using [podman](https://podman.io/) CLI:
   ```sh
   podman build -t ghub-stats-updater-job:latest .
   ```

5. Make a read+write copy of some essential credentials that will be used by the `gcloud`  tool within the container.

   The following assumes `gcloud config configurations list` returns "default" as the name of the active gcloud configuration.

   ```sh
   mkdir -p /tmp/gcloudcreds/configurations
   cp ~/.config/gcloud/credentials.db /tmp/gcloudcreds
   cp ~/.config/gcloud/access_tokens.db /tmp/gcloudcreds
   cp ~/.config/gcloud/configurations/config_default /tmp/gcloudcreds/configurations
   cp ~/.config/gcloud/active_config /tmp/gcloudcreds
   ```

6. Create a Github PAT with read+write access to your home repo. And register it as a Google Cloud Secret.
   ```sh
   SECRET_NAME=GitHub-PAT-1
   gcloud secrets create $SECRET_NAME \
     --replication-policy="automatic" \
     --project=$PROJECT_ID \
     --labels=env=dev,type=pat

   GITHUB_PAT=...your-PAT-from-github....

   gcloud secrets versions add $SECRET_NAME \
     --data-file=<(echo -n "$GITHUB_PAT") \
     --project=$PROJECT_ID
   ```

   Grant permissions to the Service account to access this secret:
   ```sh
   gcloud secrets add-iam-policy-binding $SECRET_NAME \
     --role="roles/secretmanager.secretAccessor" \
     --member="serviceAccount:$SA_EMAIL" \
     --project=$PROJECT_ID
   ```

6. Run the container, providing the required inputs. Use either `podman` or `docker`.

   ```sh
   podman run -it --rm \
     -v "/tmp/gcloudcreds:/root/.config/gcloud:rw" \
     -e RUNNING_LOCALLY=true \
     -e GH_PAT_SECRET_NAME=$SECRET_NAME \
     -e PROJECT_ID=$PROJECT_ID \
     -e TARGET_SA=$SA_EMAIL \
     -e SERVICE_URL=https://my-github-stats-service-12345667890.us-central1.run.app \
     -e USER_EMAIL=your-email-for-git-commit@example.com \
     -e GH_USER=YourGithubUserName \
     ghub-stats-updater-job:latest
   ```


## Disclaimer

This example is not an official Google product, nor is it part of an
official Google product.

## License

This material is [Copyright © 2025 Google LLC](./NOTICE).
and is licensed under the [Apache 2.0 License](LICENSE). This includes the Java
code as well as the API Proxy configuration.

## Support

This example is open-source software, and is not a supported part of Google
Cloud.  If you need assistance, you can try inquiring on [the Google Cloud
Community forums dedicated to Cloud
Run](https://discuss.google.dev/c/google-cloud/cloud-serverless/83) There is no
service-level guarantee for responses to inquiries posted to that site.

