# Migrating to environment-based layouts

This repository now contains separate Terraform roots for `dev`, `qa` and `prod` under the `environments/` directory. Existing infrastructure was deployed from the repository root and stores its state at `state/terraform.tfstate`. Follow these steps to move it into the new `dev` environment.

1. **Initialize the new backend**
   Ensure the S3 bucket and DynamoDB table defined in `terraform.tfvars` exist. Run the `scripts/setup-backend.sh` script if necessary.

2. **Create the dev state path**
   Copy the current state file to the new key so that resources remain managed:
   ```bash
   aws s3 cp s3://<bucket>/state/terraform.tfstate s3://<bucket>/state/dev/terraform.tfstate
   ```

3. **Move to the dev configuration**
   Change directory to `environments/dev` and run:
   ```bash
   terraform init
   terraform plan
   ```
   Verify no resources will be created or destroyed. If the plan looks correct, apply it:
   ```bash
   terraform apply
   ```

4. **Remove the old state**
   After confirming the dev environment manages all resources, remove the original `state/terraform.tfstate` object from S3.

The infrastructure is now managed from `environments/dev`. The same process can be repeated for other environments using their respective folders and state keys.
