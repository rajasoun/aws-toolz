# AWS Scanners

Assembly of Opensource Tools for Auditing and Budget Reporting for AWS Accounts

## Initial Setup

From Terminal Window.
```sh
$ .devcontainer/ci-shell.sh
$ ci-cd config-prerequisite
```

## Getting Started 

In Visual Studio Code, DevContainer Terminal Windows and follow the instructions
```sh
$ ci-cd config-prerequisite
```

### Configure gpg and pass

1. Generate a new GPG private key. (Optional if you already have a GPG key setup and trusted on the system)
   > Note: If you set a passphrase, you will be prompted to enter it.

   ```bash
   $ gpg2 --gen-key
   ```

2. Configure `GPG_TTY` environment variable by running the following command and also adding it to your `~/.bashrc` file.
   ```bash
   export GPG_TTY="$(tty)"
   ```

3. Initialize the password-storage DB using the GPG `public` key ID or the associated email
   ```bash
   $ gpg2 --list-keys
   /home/user/.gnupg/pubring.gpg
   ------------------------
   pub   2048R/11C90413 2019-03-07
   uid                  foo bar <foo@bar.com>
   sub   2048R/368D4190 2019-03-07
   
   $ pass init bar <foo@bar.com>
   ```


## Building and Pushing Devcontainers

### Build Dev Container

From Terminal Window.
```sh
$ source .devcontainer/automator/ghelp.bash
$ ci-cd tools-prerequisite 
$ ci-cd build
```

### Push Dev Container

From Terminal Window.
```sh
$ .devcontainer/ci-shell.sh
$ devcontainer_signature
$ exit 
$ ci-cd build
$ ci-cd push
```

## awsaudit

AWS Audit is a command line utility that will help end-user/application owner to audit the AWS services from the security perspective.

Features of the AWS Audit:
* Command line utility
* Generate report in excel
* No additional setup is required

Select the AWS Profile for AWS Audit
```sh
$ aws-vault-env
```

Run the utility using below command
```sh
$ awsaudit
```

Or Non Interactively
```sh
$ $AWS_PROFILE=
$ aws-vault exec $AWS_PROFILE --no-session -- awsaudit
```

Reference: https://pypi.org/project/aws-audit/

## Prowler

Prowler is a command line tool for AWS Security Best Practices Assessment, Auditing, Hardening and Forensics Readiness Tool.

It follows guidelines of the CIS Amazon Web Services Foundations Benchmark (49 checks) and has 40 additional checks including related to GDPR and HIPAA.

Read more about [CIS Amazon Web Services Foundations Benchmark v1.2.0 - 05-23-2018](https://d0.awsstatic.com/whitepapers/compliance/AWS_CIS_Foundations_Benchmark.pdf)

Configure the utility using below command
```sh
$ export $(aws-vault exec secops-experiments --no-session -- env | grep AWS | xargs)
$ ./setup.sh
```

Run the utility using below command
```sh
$ ./prowler.sh
```

Reference: https://github.com/toniblyx/prowler

## komiser
AWS FinOps - Stay under budget by uncovering hidden costs, monitoring increases in spend, and making impactful changes based on custom recommendations.

Reference: https://github.com/mlabouardy/komiser
