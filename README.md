# Summary

This is a Cloud Run job that invokes a service to generate a github stats image,
then updates my own github repo with the updated image.

I built this because the github-readme-stats vercel app hosted by Anurag Hazra,
is shared and apparently is experiencing overuse or 503s.

So, I did this:

- cloned https://github.com/anuraghazra/github-readme-stats
- Stood it up as a Cloud Run service
- created this cloud run job, which invokes the service, saves the file, and pushes to my own repo
- configured the job to run on a schedule

## Disclaimer

This example is not an official Google product, nor is it part of an
official Google product.

## License

This material is [Copyright © 2025 Google LLC](./NOTICE).
and is licensed under the [Apache 2.0 License](LICENSE). This includes the Java
code as well as the API Proxy configuration.

