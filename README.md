# tron

## Execution order

- global
  - s3 (remote state bucket)
  - iam (used with cloud watch, not finished yet)
- vpc (dependencies: s3)
- security (dependencies: s3, vpc)
- storage (dependencies: s3, vpc, security)
- app (dependencies: all above)

- Don't forget to create the terraform.tfvars and run infracost
- Explain the account strategy
