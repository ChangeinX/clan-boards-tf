import boto3
from datetime import datetime, timezone

ECR = boto3.client("ecr")
KEEP = 11

def lambda_handler(event, context):
  repos = []
  paginator = ECR.get_paginator("describe_repositories")
  for page in paginator.paginate():
    repos.extend([r["repositoryName"] for r in page.get("repositories", [])])

  for repo in repos:
    images = []
    paginator = ECR.get_paginator("describe_images")
    for page in paginator.paginate(repositoryName=repo):
      images.extend(page.get("imageDetails", []))

    images.sort(key=lambda x: x.get("imagePushedAt", datetime(1970, 1, 1, tzinfo=timezone.utc)), reverse=True)
    old_images = images[KEEP:]
    image_ids = [{"imageDigest": img["imageDigest"]} for img in old_images if "imageDigest" in img]
    if image_ids:
      ECR.batch_delete_image(repositoryName=repo, imageIds=image_ids)

  return {"status": "ok"}
