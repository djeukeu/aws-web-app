# Scalable Web CI/CD pipeline with AWS services and Github Actions

Deployment of a scalable and resilient web application. This is done using Github Actions and AWS CloudFormation.

## 🚀 Project Overview

This project enables us to deploy a highly available, scalable and secure web application on AWS. For this project, the deployment is divided into two environments: staging and production.

### Staging Environment
Before being deployed in production, the web app is deployed in an EC2 instance launched in a public subnet. This instance is accessible via SSH (port 22) and HTTP (port 80) for testing purposes.

### Production Environment 
To make deployment in production easier, AWS CloudFormation is used to provision the infrastructure and launch the application. The process is divided into two nested stacks.The first stack [prod-stack-1](infrastructure/cloudformation/prod-stack-1.yml) is responsible for provisioning:
- A VPC with 3 public subnets across 3 Availability Zones
- An Internet Gateway with routing for outbound internet access
- An ECS Cluster (Fargate-based) for container orchestration
- An ECR Repository for storing Docker images

Next Github Actions is handles for build, tagging and deployment of the application's container image to AWS ECR. Then [prod-stack-2](infrastructure/cloudformation/prod-stack-2.yml) is responsible for building a containerised web application infrastructure using ECS Fargate, which is hosted on three public subnets and protected by an Application Load Balancer with autoscalable services. ECR and IAM roles are used for pulling the container image and logging.


## 📌 Architecture Diagram

![Staging Architecture Diagram](https://github.com/djeukeu/aws-web-app/blob/master/web-ci-cd-1.png)

![Staging Architecture Diagram](https://github.com/djeukeu/aws-web-app/blob/master/web-ci-cd-2.png)