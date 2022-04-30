# AWS Scanners

Assembly of Opensource Tools for Auditing and Budget Reporting for AWS Accounts

## Initial Setup

From Terminal Window.
```sh
$ git clone https://github.com/rajasoun/aws-toolz
$ .devcontainer/ci-shell.sh
$ ci-cd config-prerequisite
```

## Getting Started

In Visual Studio Code, DevContainer Terminal Windows and follow the instructions
```sh
$ ci-cd config-prerequisite
```

### Configure gpg, pass and aws-vault

1. Generate a new GPG private key. (Optional if you already have a GPG key setup and trusted on the system)
   > Note: If you set a passphrase, you will be prompted to enter it.

   ```bash
   $ generate_gpg_keys #gpg2 --gen-key
   ```

2. Initialize the password-storage DB using the GPG `public` key ID or the associated email
   ```bash
   $ gpg2 --list-keys
   $ init_pass_store #similar to pass init <email_id> got from previous command
   ```
3. Configure aws-vault through wrapper
   ```bash
   $ aws-env
   ```

## aws-billing
Getting billing

Get Detailed Billing by account
   ```bash
   $ aws-whoami <aws_profile>
   $ aws-bill <aws_profile>
   $ aws-env aws-cost-hub/cost-explorer/spike/lambda.py
   ```

Get Summary Billing for all accounts
   ```bash
   $ aws-whoami <aws_profile>
   ```

## Cloudsplaining

Cloudsplaining is an AWS IAM Security Assessment tool that identifies violations of least privilege and generates a risk-prioritized HTML report.
Refrence: https://github.com/salesforce/cloudsplaining

   ```bash
   $ cd iam
   $ ./cloudsplaining.sh <aws_profile>
   ```

## awsaudit

AWS Audit is a command line utility that will help end-user/application owner to audit the AWS services from the security perspective.

Features of the AWS Audit:
* Command line utility
* Generate report in excel
* No additional setup is required

Select the AWS Profile for AWS Audit
```sh
$ aws-env awsaudit
```

Or Non Interactively
```sh
$ export AWS_PROFILE=<profile_name> && aws-env awsaudit
```

Reference: https://pypi.org/project/aws-audit/

## Prowler

Prowler is a command line tool for AWS Security Best Practices Assessment, Auditing, Hardening and Forensics Readiness Tool.

It follows guidelines of the CIS Amazon Web Services Foundations Benchmark (49 checks) and has 40 additional checks including related to GDPR and HIPAA.

Read more about [CIS Amazon Web Services Foundations Benchmark v1.2.0 - 05-23-2018](https://d0.awsstatic.com/whitepapers/compliance/AWS_CIS_Foundations_Benchmark.pdf)

Configure the utility using below command
```sh
$ aws-env
$ ./setup.sh
```

Run the utility using below command
```sh
$ ./prowler.sh
$ exit
```

Reference: https://github.com/toniblyx/prowler

## komiser
AWS FinOps - Stay under budget by uncovering hidden costs, monitoring increases in spend, and making impactful changes based on custom recommendations.

Reference: https://github.com/mlabouardy/komiser

## Building and Pushing Devcontainers

### Build Dev Container

From Terminal Window - For First Time (If no base Image is Present)
```sh
$ touch .dev
$ source .devcontainer/automator/ghelp.bash
$ ci-cd tools-prerequisite
$ ci-cd build
```

### Push Dev Container

From Terminal Window.
```sh
$ .devcontainer/ci-shell.sh dev
$ devcontainer_signature
$ exit
$ ci-cd build
$ ci-cd push
```
