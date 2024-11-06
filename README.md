

# README for CAST AI Image Management Script

## Overview
This script is designed to manage CAST AI images in Azure by retrieving, sorting, and deleting images based on their published dates. The script ensures that the latest two images per resource group are retained while older images are deleted.

## Prerequisites
- Azure CLI installed and configured on your machine.
- jq installed for JSON processing.
- Access to an Azure subscription with permissions to manage resources.

## Creating a Service Principal with Limited Permissions

To run this script securely, create a Service Principal (SP) with limited permissions. Follow the steps below:

### Step 1: Create a Service Principal
1. Open your terminal and run the following command to create a new Service Principal:

   ```bash
   az ad sp create-for-rbac --name "<SP_NAME>" --role "Custom Image Management Role" --scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
   ```

   Replace `<SP_NAME>` with a desired name for the Service Principal and `<YOUR_SUBSCRIPTION_ID>` with your actual subscription ID.

### Step 2: Assign Limited Permissions
Create a custom role that allows managing CAST AI images with the least privilege:

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

### Step 3: Retrieve Service Principal Credentials
Once the Service Principal is created, save the output, which includes:
- App ID (Client ID)
- Password (Client Secret)
- Tenant ID

### Step 4: Assign the Custom Role to the Service Principal
You may need to assign the custom role to the SP explicitly if it wasn’t done in Step 1. Use the following command:

```bash
az role assignment create --assignee "<SP_APP_ID>" --role "Custom Image Management Role" --scope "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
```

Replace `<SP_APP_ID>` with the App ID of your Service Principal.

## Running the Script

### Step 1: Prepare the Script
1. Ensure the script is saved in a file, e.g., `manage_castai_images.sh`.
2. Update the script variables at the top:
   - `TENANT_ID`: Your Azure Active Directory tenant ID.
   - `CLIENT_ID`: The App ID of the Service Principal you created.
   - `CLIENT_SECRET`: The password of the Service Principal.
   - `SUBSCRIPTION_ID`: Your Azure subscription ID.

### Step 2: Execute the Script
Run the script using the following command:

```bash
bash manage_castai_images.sh
```

### Important Note
**Test in Lower Environment First**: Before running the script in a production environment, ensure you test it in a lower environment. This will help you verify its functionality without risking disruption to critical services or data.

## Output
The script will provide output indicating:
- All found images.
- Images being kept.
- Images marked for deletion.
- Status of deletion operations.

## Troubleshooting
If you encounter issues:
- Verify that the Service Principal has the necessary permissions.
- Ensure that the Azure CLI is properly configured and you can access your subscription.
- Check the format of the published date in your images to ensure sorting works as expected.

## Conclusion
This README provides a step-by-step guide to set up a Service Principal with limited permissions, execute the CAST AI image management script, and the importance of testing in lower environments first. For any additional questions, please refer to the Azure documentation or consult with your Azure administrator.

