# IAM Permissions for Terraform State Locking

This document outlines the required IAM permissions for using S3 and DynamoDB as a Terraform backend with state locking.

## Background

Terraform uses S3 to store state files and DynamoDB for state locking. The latter prevents concurrent operations that could corrupt the state. When multiple users or automation systems (like Jenkins) try to modify infrastructure simultaneously, the lock ensures only one operation proceeds at a time.

## Required Permissions

### S3 Bucket Permissions

For storing and retrieving the state file:

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    "arn:aws:s3:::your-terraform-state-bucket",
    "arn:aws:s3:::your-terraform-state-bucket/*"
  ]
}
```

### DynamoDB Table Permissions

For state locking and consistency operations:

```json
{
  "Effect": "Allow",
  "Action": [
    "dynamodb:GetItem",
    "dynamodb:PutItem",
    "dynamodb:DeleteItem",
    "dynamodb:GetRecords",
    "dynamodb:UpdateItem",
    "dynamodb:BatchWriteItem",
    "dynamodb:BatchGetItem",
    "dynamodb:DescribeTable",
    "dynamodb:ListTables"
  ],
  "Resource": [
    "arn:aws:dynamodb:region:account-id:table/your-terraform-lock-table"
  ]
}
```

## Troubleshooting

If you encounter errors related to locking:

1. Check that the IAM role has all necessary permissions for both S3 and DynamoDB
2. Verify the DynamoDB table exists in the specified region
3. Ensure the table has a partition key named `LockID` (string type)
4. If needed temporarily, you can use `-lock=false` with terraform commands, but this should only be used in emergency situations

## Our Configuration

In our project, we use:
- S3 bucket: `projet-c-mohamed`
- DynamoDB table: `projet-c-terraform-locks-app` (for app project)
- DynamoDB table: `terraform-locks` (for devops project)

All IAM permissions are configured in `/projet-c-devops/infra/terraform/iam.tf`.
