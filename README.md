# EC2-Cloudfront-S3-Deploy
This pipeline deploys Cloudfront cache and s3 bucket for storing frontend, and VPC, security group, IAM instance profile and Ec2 instance for running backend containers. Containers are stored in the private ECR, and running using docker compose. For automation is used terraform code running on GitHub Actions.

## Technologies Used:

#### * _AWS Cloud_
#### * _Docker/Docker-Compose_
#### * _Terraform_
#### * _GitHub Actions_

## Requirements to Deploy the Project
#### - AWS Account
#### - Github Account

## Secrets Configuration
The project requires these secrets in your GitHub repository:

```sh
AWS_ACCESS_KEY_ID: IAM access key for AWS API operations.
AWS_SECRET_ACCESS_KEY: Secret key paired with the access key.
AWS_REGION: The AWS region where resources will be created (e.g., us-east-1).
```

Project Overview
Frontend Deployment
Hosted on S3 for static website hosting.
Delivered via CloudFront for low-latency content delivery and caching.
Backend Deployment
Containerized backend services using Docker Compose.
Deployed on EC2 instances within a custom VPC.
Secured with Security Groups for fine-grained access control.
Database
Managed RDS instance for persistent storage.
Networking
Configured VPC, public/private subnets, NAT gateways, and route tables.
Security enhanced with Security Groups and Network ACLs.
CI/CD Pipeline
Terraform configurations stored in the repository.
GitHub Actions automate the deployment and management of the infrastructure.


## Setup steps
Step 1: Fork the Repository 

Step 2: Configure GitHub Secrets
Add the following secrets to your GitHub repository:
```sh
AWS_ACCESS_KEY_ID: IAM access key for AWS API operations.
AWS_SECRET_ACCESS_KEY: Secret key paired with the access key.
AWS_REGION: The AWS region where resources will be created (e.g., us-east-1).
```

Step 3: Run `Deploy Project` workflow to deploy the project
> Note: Feel free to use `Deploy Frontend` or `Deploy Backend` workflows if required. Also you can use `Delete Resources` workflow to remove whole infrastructure including s3 bucket for terraform backend.

Step 4: Access the Deployed Application
Copy CloudFront URL from GitHub Actions output, and open the webpage from your browser.
> Note: Use `http://` connection for this project.

## Key Notes:
> Resource Costs: Ensure you understand AWS pricing to manage project costs effectively.
> Security: Use least privilege access for AWS credentials. `Don't paste AWS credentials anywhere excluding GitHub Secrets`
> Debugging: You can monitor the infrastructure deploying in GitHub Actions logs, and findout errors if present.
> Documentation: Don't foget to update the repository’s README.md to reflect current workflows and configurations.