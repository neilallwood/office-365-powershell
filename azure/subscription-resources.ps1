# This script will show what resources have been consumed by a given subscription
# and then export that list to a CSV file
#
# Date created: 29/11/2018
#
# When opening PowerShell, ensure you run it as an Administrator.
#
# Step 0. Check if the AzureRM PowerShell Module is installed.
# If not, it will be installed.
if (Get-Module -ListAvailable -Name AzureRM) {
# Import the Module
    Write-Host "AzureRM Module is installed."
    Import-Module -Name AzureRM
} else {
    Write-Host "Module does not exist. Installing Module AzureRM."
    Install-Module -Name AzureRM
    Import-Module -Name AzureRM
}

# Step 1. Login to the Azure tenant using your username and password.
# The user must have permissions on the subscription.
Login-AzureRmAccount

# Step 2. List all the current subscriptions for the tenant.
Get-AzureRmSubscription

# Step 3. Specify the subscription to list the resources for and your company name.
# When prompted, copy and paste (or type in) the name of the subscription.
# The company name is only used for the file name.
$subscription = Read-Host =Prompt 'Enter the name of the subscription'
$company = Read-Host =Prompt 'Enter your company name'

# Step 4. Run the report and export it as a CSV file.
# 4.1. Sets the subscription to use.
Select-AzureRmSubscription -Subscription $subscription
# 4.2. Get all the resources that are consumed by the subscription.
Get-AzureRmResource -ExpandProperties | Export-CSV ~\Desktop\$company-$subscription-All-Resources.CSV -NoTypeInfo -Verbose
# 4.3. Get all of the VM's consumed by the subscription in more detail.
Get-AzureRMVM -Status | Export-CSV ~\Desktop\$company-$subscription-All-VMs.CSV -NoTypeInfo -Verbose
# 4.4. Get all of the managed disks consumed by the subscription in more detail.
Get-AzureRmDisk | Export-CSV ~\Desktop\$company-$subscription-All-VMs.CSV -NoTypeInfo -Verbose