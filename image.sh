#!/bin/bash

# Variables
TENANT_ID=" "      # Your Azure Active Directory tenant ID
CLIENT_ID=" "      # The client ID (application ID) of your service principal
CLIENT_SECRET=""  # The client secret (password) of your service principal
SUBSCRIPTION_ID=" " # Your specific subscription ID
BATCH_SIZE=50 # Number of Batch delete images per RG

# Login to Azure using Service Principal
echo "Logging into Azure..."
az login --service-principal --username "$CLIENT_ID" --password "$CLIENT_SECRET" --tenant "$TENANT_ID"

# Check if login was successful
if [ $? -ne 0 ]; then
  echo "Azure login failed. Exiting..."
  exit 1
fi

# Set the Azure subscription
az account set --subscription "$SUBSCRIPTION_ID"
echo "Azure subscription set to: $SUBSCRIPTION_ID"

# Define the Azure Resource Graph query to find VM images managed by CAST AI
query="resources | where type =~ 'microsoft.compute/galleries/images/versions' and tags['cast-managed-by'] =~ 'cast.ai' | project id, resourceGroup, properties.publishingProfile.publishedDate"

# Run the Azure Resource Graph query using Azure CLI
echo "Running Resource Graph query to fetch VM images..."
results=$(az graph query -q "$query" --query "data[]" -o json)

# Check if any results were returned
if [ -z "$results" ]; then
  echo "No VM images found with 'cast.ai' in tags."
  az logout
  exit 0
fi

# Create a temporary file to store image data
temp_file=$(mktemp)

# Parse the JSON results and write to the temporary file
echo "$results" | jq -c '.[]' | while IFS= read -r image; do
  id=$(echo "$image" | jq -r '.id')
  resourceGroup=$(echo "$image" | jq -r '.resourceGroup')
  publishedDate=$(echo "$image" | jq -r '.properties.publishingProfile.publishedDate')
  
  # Write the data to the temp file
  echo "$resourceGroup,$id,$publishedDate" >> "$temp_file"
done

# Create indexed arrays to hold resource groups and images
declare -a resourceGroups
declare -a images

# Read the temporary file and group images by resource group
while IFS=, read -r resourceGroup id publishedDate; do
  resourceGroups+=("$resourceGroup")
  images+=("$id,$publishedDate")
done < "$temp_file"

# Get unique resource groups
uniqueResourceGroups=($(echo "${resourceGroups[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Process each resource group
for resourceGroup in "${uniqueResourceGroups[@]}"; do
  echo "Processing resource group: $resourceGroup"

  # Filter images for the current resource group
  groupImages=()
  for i in "${!images[@]}"; do
    if [[ "${resourceGroups[$i]}" == "$resourceGroup" ]]; then
      groupImages+=("${images[$i]}")
    fi
  done

  # Sort images by published date
  sortedImages=($(for img in "${groupImages[@]}"; do echo "$img"; done | sort -t, -k3,3))

  # Determine the number of images
  numImages=${#sortedImages[@]}

  if [ "$numImages" -le 2 ]; then
    # Keep all images if there are 2 or fewer
    echo "Keeping all images for resource group: $resourceGroup (Total images: $numImages)"
  else
    # Keep the latest two images
    latestImages=("${sortedImages[@]: -2}")

    # Display the latest images
    echo "Latest images to keep for resource group $resourceGroup:"
    for img in "${latestImages[@]}"; do
      echo "  Keeping image: $img"
    done

    # Determine which images to delete (all except the latest two)
    imagesToDelete=()
    for img in "${sortedImages[@]}"; do
      if [[ ! " ${latestImages[@]} " =~ " ${img} " ]]; then
        imagesToDelete+=("${img%%,*}")
      fi
    done

    # Batch delete images
   
    total=${#imagesToDelete[@]}
    echo "Deleting ${total} images for resource group: $resourceGroup in batches of $BATCH_SIZE"

    for ((i = 0; i < total; i += BATCH_SIZE)); do
      batch=("${imagesToDelete[@]:i:BATCH_SIZE}")
      echo "Deleting batch: ${batch[*]}"
      az resource delete --ids "${batch[@]}" &  # Run deletions in parallel
    done

    # Wait for all deletions to complete
    wait
  fi
done

# Clean up temporary file
rm "$temp_file"

# Logout from Azure
az logout
echo "Logged out from Azure."
