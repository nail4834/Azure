#!/bin/bash

# AWS Region
REGION="us-west-2"
OUTPUT_FILE="sg_readable_output.txt"

# Check dependencies
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed."
    exit 1
fi

# Clear previous output
> "$OUTPUT_FILE"

# Fetch security groups JSON
SG_JSON=$(aws ec2 describe-security-groups --region "$REGION" --output json)
SG_COUNT=$(echo "$SG_JSON" | jq '.SecurityGroups | length')

COUNTER=1

# Loop through each security group
for (( i=0; i<SG_COUNT; i++ ))
do
  SG=$(echo "$SG_JSON" | jq ".SecurityGroups[$i]")
  GROUP_NAME=$(echo "$SG" | jq -r '.GroupName')
  GROUP_ID=$(echo "$SG" | jq -r '.GroupId')
  OWNER_ID=$(echo "$SG" | jq -r '.OwnerId')

  echo "${COUNTER}. Group_ID- ${GROUP_ID}" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  PERMS=$(echo "$SG" | jq '.IpPermissions')
  PERM_COUNT=$(echo "$PERMS" | jq 'length')

  for (( j=0; j<PERM_COUNT; j++ ))
  do
    PERM=$(echo "$PERMS" | jq ".[$j]")
    FROM_PORT=$(echo "$PERM" | jq -r '.FromPort // "all"')
    TO_PORT=$(echo "$PERM" | jq -r '.ToPort // "all"')
    PORT_INFO="port-$FROM_PORT"

    # IPv4 rules
    IPV4_COUNT=$(echo "$PERM" | jq '.IpRanges | length')
    for (( k=0; k<IPV4_COUNT; k++ ))
    do
      CIDR=$(echo "$PERM" | jq -r ".IpRanges[$k].CidrIp")
      DESC=$(echo "$PERM" | jq -r ".IpRanges[$k].Description // \"\"")
      echo "$PORT_INFO | group_name- $GROUP_NAME | source-$CIDR | Description-$DESC | owner_id-$OWNER_ID" >> "$OUTPUT_FILE"
    done

    # IPv6 rules
    IPV6_COUNT=$(echo "$PERM" | jq '.Ipv6Ranges | length')
    for (( k=0; k<IPV6_COUNT; k++ ))
    do
      CIDR6=$(echo "$PERM" | jq -r ".Ipv6Ranges[$k].CidrIpv6")
      DESC=$(echo "$PERM" | jq -r ".Ipv6Ranges[$k].Description // \"\"")
      echo "$PORT_INFO | group_name- $GROUP_NAME | source-$CIDR6 | Description-$DESC | owner_id-$OWNER_ID" >> "$OUTPUT_FILE"
    done

    # SG references
    SGREF_COUNT=$(echo "$PERM" | jq '.UserIdGroupPairs | length')
    for (( k=0; k<SGREF_COUNT; k++ ))
    do
      SRC_SG=$(echo "$PERM" | jq -r ".UserIdGroupPairs[$k].GroupId")
      DESC=$(echo "$PERM" | jq -r ".UserIdGroupPairs[$k].Description // \"\"")
      echo "$PORT_INFO | group_name- $GROUP_NAME | source-$SRC_SG | Description-$DESC | owner_id-$OWNER_ID" >> "$OUTPUT_FILE"
    done
  done

  echo "--------------------------------------------------------------------------------" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  ((COUNTER++))
done

echo "Security Group details saved to $OUTPUT_FILE"

