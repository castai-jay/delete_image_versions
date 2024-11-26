Here’s the complete and updated **README** for the CAST AI Image Management Script:

---

# README for CAST AI Image Management Script

## Overview

This script automates the management of CAST AI-managed VM images in Azure. It retrieves all images, sorts them by their publishing dates, and deletes older images while retaining the two most recent ones per resource group. The script supports batch deletion to optimize performance and minimize Azure API calls.

---

## Features

1. **Batch Deletion**:
   - Deletes resources in batches to improve efficiency.
   - The number of resources in a batch is configurable using the `BATCH_SIZE` variable.

2. **Parallel Execution**:
   - Batch deletion commands are executed in parallel for faster processing.

3. **Resource Group Awareness**:
   - Processes images by resource group, ensuring only outdated images within the same group are deleted.

4. **Retains Latest Images**:
   - Always retains the two most recent images in each resource group.

5. **Secure Execution**:
   - Designed to run with a Service Principal that has limited permissions for enhanced security.

---

## Prerequisites

- **Azure CLI**:
  - Ensure Azure CLI is installed and configured on your machine.
  - Install Azure CLI: [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
  
- **jq**:
  - The script uses `jq` for JSON processing.
  - Install jq: [Install jq](https://stedolan.github.io/jq/download/)

- **Service Principal**:
  - Create a Service Principal with limited permissions (see below for steps).

---

## Creating a Service Principal with Limited Permissions

Follow these steps to create a secure Service Principal (SP) with only the necessary permissions to manage CAST AI images:

### 1. Create the Service Principal

Run the following command to create a new Service Principal:

```bash
az ad sp create-for-rbac --name "<SP_NAME>" --role "Custom Image Management Role" --scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
```

Replace:
- `<SP_NAME>`: A descriptive name for the Service Principal.
- `<YOUR_SUBSCRIPTION_ID>`: Your Azure subscription ID.

---

### 2. Assign a Custom Role

Create a custom role with the least privilege required for image management. Run the following command:

```bash
az role definition create --role-definition '{
  "Name": "Custom Image Management Role",
  "IsCustom": true,
  "Description": "Allows managing CAST AI images with least privilege.",
  "Actions": [
    "Microsoft.Compute/galleries/images/versions/read",
    "Microsoft.Compute/galleries/images/versions/delete"
  ],
  "NotActions": [],
  "AssignableScopes": [
    "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
  ]
}'
```

---

### 3. Assign the Role to the Service Principal

Explicitly assign the custom role to the Service Principal:

```bash
az role assignment create --assignee "<SP_APP_ID>" --role "Custom Image Management Role" --scope "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
```

Replace `<SP_APP_ID>` with the App ID of the Service Principal.

---

### 4. Save Credentials

Save the Service Principal credentials (App ID, Client Secret, Tenant ID) securely. These will be used in the script.

---

## Configuration

### Script Variables

Update the following variables in the script before execution:

- **`TENANT_ID`**: Your Azure Active Directory tenant ID.
- **`CLIENT_ID`**: The App ID of the Service Principal.
- **`CLIENT_SECRET`**: The password of the Service Principal.
- **`SUBSCRIPTION_ID`**: Your Azure subscription ID.
- **`BATCH_SIZE`**: The number of resources to delete in one batch. Default is `50`.

---

## How to Use the Script

### Step 1: Prepare the Script
1. Save the script as `manage_castai_images.sh`.
2. Ensure the script is executable:

   ```bash
   chmod +x manage_castai_images.sh
   ```

---

### Step 2: Execute the Script
Run the script with:

```bash
bash manage_castai_images.sh
```

---

## Script Workflow

1. **Login to Azure**:
   - Authenticates using the Service Principal credentials.

2. **Fetch VM Images**:
   - Retrieves CAST AI-managed VM images using Azure Resource Graph.

3. **Sort and Filter**:
   - Groups images by resource group and sorts them by publishing date.
   - Retains the two most recent images per resource group.

4. **Batch Deletion**:
   - Deletes older images in configurable batch sizes.
   - Executes deletions in parallel for better performance.

5. **Clean Up**:
   - Deletes temporary files and logs out from Azure.

---

## Output

The script provides detailed logs indicating:
- All found images.
- Images retained (latest two per resource group).
- Images marked for deletion.
- Progress of batch deletions.

---

## Adjusting Batch Size

To modify the batch size, update the `BATCH_SIZE` variable in the script. For example:

- **Set batch size to 100**:
  ```bash
  BATCH_SIZE=100
  ```

- **Set batch size to 20**:
  ```bash
  BATCH_SIZE=20
  ```

Larger batch sizes reduce the number of API calls but may hit Azure API rate limits. Adjust based on your environment.

---

## Testing and Validation

**Test in Lower Environment First**: Always test the script in a non-production environment to ensure it behaves as expected.

---

## Troubleshooting

1. **Authentication Issues**:
   - Verify the Service Principal credentials are correct.
   - Ensure the Service Principal has the required permissions.

2. **API Rate Limits**:
   - Reduce the `BATCH_SIZE` if Azure API rate limits are encountered.

3. **jq Errors**:
   - Ensure `jq` is installed and available in your PATH.

---

## Best Practices

1. **Use Least Privilege**:
   - Ensure the Service Principal only has permissions to manage CAST AI images.

2. **Review Logs**:
   - Monitor the output to confirm deletions were successful.

3. **Regular Maintenance**:
   - Schedule this script to run periodically (e.g., via cron) to maintain a clean environment.

---

## Example Output

```text
Logging into Azure...
Azure subscription set to: bd59edc0-99be-4f1e-bb31-ae4ebe41ab10
Running Resource Graph query to fetch VM images...
Processing resource group: my-resource-group
Keeping all images for resource group: my-resource-group (Total images: 2)
Processing resource group: another-resource-group
Deleting 20 images for resource group: another-resource-group in batches of 5
Deleting batch: /resource1 /resource2 /resource3 /resource4 /resource5
...
Logged out from Azure.
```

---

This README provides a complete guide to setting up and executing the CAST AI Image Management Script. Let me know if you need further assistance!