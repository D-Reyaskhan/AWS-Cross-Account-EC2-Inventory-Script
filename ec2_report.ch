#!/bin/bash

# ==============================================================================
# Script: Multi-Account EC2 Inventory Generator
# Description: Fetches a consolidated CSV of all EC2 instances across target AWS 
#              accounts and regions, caching memory to reduce API calls.
# ==============================================================================

# 1. Define target accounts in "AccountID:AccountName" format
ACCOUNTS=(
    "111111111111:Production"
    "222222222222:Development"
    "090069730324:Adapt2 Solutions"
)

# 2. Define the regions you want to query
REGIONS=("us-east-1" "us-west-2") 

# 3. Role to assume in the target accounts
ROLE_NAME="OrganizationAccountAccessRole" 

# Detect the account CloudShell is currently running in to avoid self-assumption errors
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# Print the CSV Header
echo "AccountName,AccountId,Region,InstanceName,InstanceId,InstanceType,State,PrivateIP,PublicIP,AZ,VMCoreSize,MemoryGiB"

# Create a dictionary to cache Memory lookups
declare -A MEM_CACHE

for ACCOUNT_ENTRY in "${ACCOUNTS[@]}"; do
    ACCOUNT_ID="${ACCOUNT_ENTRY%%:*}"
    ACCOUNT_NAME="${ACCOUNT_ENTRY##*:}"

    # ALWAYS clear any previous assumed role credentials before starting a new account
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

    # If the target account is NOT the account we are currently in, assume the cross-account role
    if [ "$ACCOUNT_ID" != "$CURRENT_ACCOUNT" ]; then
        ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

        CREDENTIALS=$(aws sts assume-role \
            --role-arn "$ROLE_ARN" \
            --role-session-name "MultiAccountEC2Report" \
            --output text \
            --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" 2>/dev/null)

        if [ $? -ne 0 ]; then
            echo "$ACCOUNT_NAME,$ACCOUNT_ID,ERROR: Could not assume role,,,,,,,,,"
            continue
        fi

        export AWS_ACCESS_KEY_ID=$(echo "$CREDENTIALS" | awk '{print $1}')
        export AWS_SECRET_ACCESS_KEY=$(echo "$CREDENTIALS" | awk '{print $2}')
        export AWS_SESSION_TOKEN=$(echo "$CREDENTIALS" | awk '{print $3}')
    fi

    # Loop through regions and pull EC2 data
    for REGION in "${REGIONS[@]}"; do
        
        while IFS=$'\t' read -r I_NAME I_ID I_TYPE STATE PRIV_IP PUB_IP AZ CORE; do
            
            if [ -n "$I_ID" ]; then
                if [ -z "${MEM_CACHE[$I_TYPE]}" ]; then
                    MEM_MIB=$(aws ec2 describe-instance-types \
                        --region "$REGION" \
                        --instance-types "$I_TYPE" \
                        --query "InstanceTypes[0].MemoryInfo.SizeInMiB" \
                        --output text 2>/dev/null)
                    
                    if [[ "$MEM_MIB" =~ ^[0-9]+$ ]]; then
                        MEM_GB=$(awk "BEGIN {printf \"%.2f\", $MEM_MIB/1024}")
                        MEM_CACHE[$I_TYPE]=$MEM_GB
                    else
                        MEM_CACHE[$I_TYPE]="N/A"
                    fi
                fi
                
                MEMORY="${MEM_CACHE[$I_TYPE]}"
                echo "$ACCOUNT_NAME,$ACCOUNT_ID,$REGION,$I_NAME,$I_ID,$I_TYPE,$STATE,$PRIV_IP,$PUB_IP,$AZ,$CORE,$MEMORY"
            fi
        done < <(aws ec2 describe-instances \
            --region "$REGION" \
            --query "Reservations[*].Instances[*].[Tags[?Key=='Name'].Value | [0] || 'NoName', InstanceId, InstanceType, State.Name, PrivateIpAddress||'N/A', PublicIpAddress||'N/A', Placement.AvailabilityZone, to_string(CpuOptions.CoreCount)||'N/A']" \
            --output text)

    done
done

echo "Report Complete!" >&2
  
