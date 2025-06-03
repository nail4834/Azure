#!/bin/bash

# Configuration
SUBSCRIPTION_ID="0a701e06-76b1-4951-b7f5-1c539ca9e529"
RESOURCE_GROUP="SHIFTPOC"
OUTPUT_FILE="/mnt/c/Users/rajeshkan/Desktop/Desktop/nsg_readable_output.txt"

# Check dependencies
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI is not installed."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed."
    exit 1
fi

# Ensure logged in to Azure CLI
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo "Error: Not logged into Azure CLI."
    exit 1
fi

# Set subscription context
az account set --subscription "$SUBSCRIPTION_ID"

# Clear previous output file
> "$OUTPUT_FILE"

# Get all NSGs in the resource group
NSGS=$(az network nsg list --resource-group "$RESOURCE_GROUP" --output json)
NSG_COUNT=$(echo "$NSGS" | jq 'length')

COUNTER=1

for (( i=0; i<NSG_COUNT; i++ ))
do
  NSG=$(echo "$NSGS" | jq ".[$i]")
  NSG_NAME=$(echo "$NSG" | jq -r '.name')
  LOCATION=$(echo "$NSG" | jq -r '.location')

  echo "${COUNTER}. NSG_Name: $NSG_NAME" >> "$OUTPUT_FILE"
  echo "   ResourceGroup: $RESOURCE_GROUP" >> "$OUTPUT_FILE"
  echo "   Location: $LOCATION" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"

  # Use []? to avoid null errors
  RULES=$(echo "$NSG" | jq '.securityRules[]?')
  RULE_NUM=1

  # Count rules safely
  RULE_COUNT=$(echo "$NSG" | jq '[.securityRules[]?] | length')

  for (( j=0; j<RULE_COUNT; j++ ))
  do
    RULE=$(echo "$NSG" | jq ".securityRules[$j]")
    NAME=$(echo "$RULE" | jq -r '.name')
    DIR=$(echo "$RULE" | jq -r '.direction')
    ACCESS=$(echo "$RULE" | jq -r '.access')
    PRIORITY=$(echo "$RULE" | jq -r '.priority')
    PORTS=$(echo "$RULE" | jq -r '.destinationPortRange // "all"')
    PROTOCOL=$(echo "$RULE" | jq -r '.protocol')
    DEST=$(echo "$RULE" | jq -r '.destinationAddressPrefix // "*"')

    # Collect sources safely
    SOURCES=()

    # Single source prefix
    SINGLE_SRC=$(echo "$RULE" | jq -r '.sourceAddressPrefix // empty')
    [ -n "$SINGLE_SRC" ] && SOURCES+=("$SINGLE_SRC")

    # Multiple source prefixes, safe iteration
    PREFIXES=$(echo "$RULE" | jq -r '.sourceAddressPrefixes[]?')
    while IFS= read -r prefix; do
      [ -n "$prefix" ] && SOURCES+=("$prefix")
    done <<< "$PREFIXES"

    # Application Security Groups (ASGs), safe iteration
    ASGS=$(echo "$RULE" | jq -r '.sourceApplicationSecurityGroups[]?.id // empty')
    while IFS= read -r asg; do
      [ -n "$asg" ] && SOURCES+=("ASG:$asg")
    done <<< "$ASGS"

    # If no sources, assume ANY
    [ ${#SOURCES[@]} -eq 0 ] && SOURCES+=("*")

    for src in "${SOURCES[@]}"; do
      if [[ "$src" == ASG:* ]]; then
        LABEL="$src"
      elif [[ "$src" == "*" ]]; then
        LABEL="ANY"
      else
        LABEL="CIDR:$src"
      fi

      echo "   ${RULE_NUM}) Rule: $NAME | $DIR | $ACCESS | $PROTOCOL | port-$PORTS | source-$LABEL -> destination-$DEST | priority-$PRIORITY" >> "$OUTPUT_FILE"
      ((RULE_NUM++))
    done
  done

  echo "--------------------------------------------------------------------------------" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  ((COUNTER++))
done

echo "NSG details saved to $OUTPUT_FILE"
