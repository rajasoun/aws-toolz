# Getting started

## Cloudsplaining
Cloudsplaining identifies violations of least privilege in AWS IAM policies and generates a pretty HTML report with a triage worksheet. It can scan all the policies in your AWS account or it can scan a single policy file.

It helps to identify IAM actions that do not leverage resource constraints. It also helps prioritize the remediation process by flagging IAM policies that present the following risks to the AWS account in question without restriction:

* Data Exfiltration (s3:GetObject, ssm:GetParameter, secretsmanager:GetSecretValue)
* Infrastructure Modification
* Resource Exposure (the ability to modify resource-based policies)
* Privilege Escalation (based on Rhino Security Labs research)

Automated Scan:

```sh
./cloudsplaining.sh <profile_name>
```

Manual Steps to generate report:

0. Set AWS environment `aws-env`
1. Downloaded the Account Authorization details JSON file
    ```sh
    cloudsplaining download  --output reports/AWS_PROFILE
    ```   
2. Generate custom exclusions file
    ```sh
        cloudsplaining create-exclusions-file --output-file reports/$AWS_PROFILE-exclusions.yml
    ```   
3. Generate the report 
    ```sh
    cloudsplaining scan --input-file reports/$AWS_PROFILE-account-details.json --exclusions-file reports/$AWS_PROFILE-exclusions.yml
    ```  

This generates The single-file HTML report and the raw JSON data file
