# AWS Multi-Account EC2 Inventory Script 🛡️

A lightweight, native Bash script that leverages the AWS CLI and STS to generate a unified, multi-account inventory of EC2 instances. It extracts data across multiple accounts and regions directly into a clean CSV format without relying on heavy third-party tools.

## 🎯 Features
- **Cross-Account Automation:** Dynamically loops through AWS accounts using `sts:AssumeRole`.
- **Smart Execution:** Automatically detects the execution environment (Management/Hub account) to prevent self-assumption `AccessDenied` errors.
- **API Optimization:** Caches `describe-instance-types` memory (GiB) lookups using Bash associative arrays, dramatically reducing execution time and preventing API throttling.
- **Data Sanitization:** Uses strict Internal Field Separators (`IFS=$'\t'`) to handle instance names with spaces, ensuring perfect CSV alignment.

## 🔍 Prerequisites
1. **AWS CLI** configured, or run directly within **AWS CloudShell**.
2. An IAM Role (e.g., `OrganizationAccountAccessRole`) in target accounts with `AmazonEC2ReadOnlyAccess`.
3. A Trust Policy on that role allowing the central/management account to assume it.

## ⚙️ Configuration
Before running the script, update the following variables at the top of `ec2_report.sh`:
- `ACCOUNTS`: Array of your target accounts in `"AccountID:AccountName"` format.
- `REGIONS`: Array of target AWS regions (e.g., `"us-east-1" "us-west-2"`).
- `ROLE_NAME`: The cross-account IAM role name to assume.

## 🚀 Usage
1. Make the script executable:
   ```bash
   chmod +x ec2_report.sh
   
