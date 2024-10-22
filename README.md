# AWS Serverless Simple Link Redirector and Tracker

A serverless link redirector and tracker is a system that allows users to create short, manageable links that redirect
to longer URLs while tracking user interactions. This approach leverages serverless architecture, meaning it operates
without the need for dedicated server management, using cloud services to handle the workload.

# How to use it

1) Add your links into the `source/function.py` file
2) Adapt the naming of the lambda function and the log retention in `variables.tf`
3) Deploy the terraform script
4) Have fun!

## Deploy the terraform script

1) Install terraform (https://developer.hashicorp.com/terraform/install)
2) Sign in to AWS using the AWS CLI (https://docs.aws.amazon.com/signin/latest/userguide/command-line-sign-in.html)
3) Run `terraform apply` and if the changes match your expectations press `y`
