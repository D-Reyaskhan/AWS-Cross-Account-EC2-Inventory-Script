# AWS Multi-Account EC2 Inventory Script 🛡️

A lightweight, native Bash script that leverages the AWS CLI and AWS Security Token Service (STS) to generate a unified, multi-account inventory of EC2 instances. It extracts data across multiple accounts and regions directly into a clean CSV format without relying on heavy third-party tools.

## 🎯 Features
* **Cross-Account Automation:** Dynamically loops through AWS accounts using `sts:AssumeRole`.
* **Smart Execution:** Automatically detects the execution environment (Management/Hub account) to prevent self-assumption `AccessDenied` errors.
* **API Optimization:** Caches `describe-instance-types` memory (GiB) lookups using Bash associative arrays, dramatically reducing execution time and preventing API throttling.
* **Data Sanitization:** Uses strict Internal Field Separators (`IFS=$'\t'`) to handle instance names with spaces, ensuring perfect CSV alignment.

## 🔍 Prerequisites
1.  **AWS CLI** configured, or run directly within **AWS CloudShell**.
2.  An IAM Role (e.g., `OrganizationAccountAccessRole`) in target accounts with `AmazonEC2ReadOnlyAccess` (or AdministratorAccess).
3.  A Trust Policy on that role allowing the central/management account to assume it.

## ⚙️ Configuration
Before running the script, open `ec2_report.sh` and update the following variables at the top of the file:
* `ACCOUNTS`: Array of your target accounts in `"AccountID:AccountName"` format. *(Note: Ensure 12-digit Account IDs, including leading zeros).*
* `REGIONS`: Array of target AWS regions (e.g., `"us-east-1" "us-west-2"`).
* `ROLE_NAME`: The cross-account IAM role name to assume.

## 🚀 Usage Steps

**Step 1: Make the script executable**
```bash
chmod +x ec2_report.sh

**Step 2: Execute and output to CSV**
Run the script and redirect the output to a CSV file.

./ec2_report.sh > all_accounts_ec2_inventory.csv

Step 3: Download and View
If running in CloudShell, use the Actions -> Download file menu in the top right corner to download all_accounts_ec2_inventory.csv and open it in your preferred spreadsheet application.

📊 Output Fields

AccountName AccountId Region InstanceName InstanceId InstanceType State PrivateIP PublicIP AZ VMCoreSize MemoryGiB
Production 111111111111 us-east-1 Web-Server-01 i-0abcd1234efgh5678 t3.medium running 10.0.1.50 203.0.113.5 us-east-1a 2 4.00

💡 Troubleshooting
ERROR: Could not assume role: Verify that your 12-digit Account ID is correct, the role exists in the target account, and the Trust Policy correctly whitelists the account you are executing the script from.
