####################################################
#                                                  #
# Migrate managed to unmanaged disks for migration #
# Create a new VM with unmanaged disks attached    #
# Migrate unmanaged disks to managed disks again   #
# This is mostly for moving between subscriptions  #
#                                                  #
####################################################

# Login using your Azure Account.
Login-AzureRmAccount

# Prior to starting this, you need to have a storage account created to copy the VHD files to. It is recommended to do this in the Azure Portal.

# Set global variables used in this script.
$ResourceGroup = 'Neil-Allwood-North-EU'
$VMName = 'neil-test-md'
$StorageAccount = 'neilallwoodtestmd'
$StorageAccountKey = 'fut3dDg35j4Kd9IME3WbcbAPpaWxM2DO8MrgGDHd2mHGc6wDIshnt/6H/g+Ugxgseaj/U7+p7iDtkcwCzGNFYg=='

#################################################################
# Copy a managed disk to an unmanaged disk in a storage account #
#################################################################

# List all managed disks for the given VM
$vm = Get-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName
$vm.StorageProfile.OsDisk | Where-Object {$_.ManagedDisk -ne $null} | Select-Object Name
$vm.StorageProfile.DataDisks | Where-Object {$_.ManagedDisk -ne $null} | Select-Object Name
$DiskName = Read-Host -Prompt 'Enter the name of the disk to copy'

# Grant access to the Storage Account and begin copying the VHD.
# Perform this step for each managed disk.
$sas = Grant-AzureRmDiskAccess -ResourceGroupName $ResourceGroup -DiskName $DiskName -Access Read -DurationInSecond 45000
$context = New-AzureStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccountKey
$blobcopyresult = Start-AzureStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestinationContainer 'vhds' -DestinationBlob '$VMName-drive-c.vhd' -DestinationContext $context -Verbose

# Note: 10GB = ~7mins 30secs transfer time.
# Note: white space is not copied, therefor saving time. Only consumed space is copied.

# Get the status of the VHD copy. Keep running this until the copy operation is completed.
$blobcopyresult | Get-AzureStorageBlobCopyState

# Delete the source VM.
# This will not delete the managed disk(s), the NSG's or the vNic and Public IP address settings
Remove-AzureRMVM -ResourceGroupName $ResourceGroup -Name $VMName
# We need to remove the managed disk as it will not be needed. Make sure you have a backup before doing this bit, just in case :-)
Remove-AzureRmDisk -ResourceGroupName -DiskName $DiskName

# Once the copy operation is completed for all the VHD's, you can then perform your move of the subscription / resource to
# another subscription or resource group.

# Once you have moved the VHD's to the new subscription / resource group, you will then need 
# to create a new VM from those disks.
# Once the VM is created and the disks attached, you can then migrate the disks back to managed disks.

####################
#  create a new VM #
####################

# Get Azure VM SKU List
$Location = 'West Europe'
$WindowsPublisherName = "MicrosoftWindowsServer"
$WindowsOffer = "WindowsServer"

Get-AzureRmVMImageSku -Location $Location -PublisherName $WindowsPublisherName -Offer $WindowsOffer | Select-Object -Property "Skus","Offer","PublisherName" `
| Export-CSV -Path ~\Desktop\$Location-WindowsSKUs.csv

Get-AzureRmVMSize -Location $Location | Select-Object -Property "Name","NumberOfCores","MemoryInMB","MaxDataDiskCount","OSDiskSizeInMB","ResourceDiskSizeInM" `
| Export-CSV -Path ~\Desktop\$Location-WindowsSKUs.csv

# Create VM
$vmconfig = New-AzureRmVMConfig -VMName $VMName -VMSize "VMSIZE"
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id (Get-AzureRmNetworkInterface -Name NICNAME -ResourceGroupName RESOURCEGROUPNAME).Id
$vm = Set-AzureRmVMBootDiagnostics -VM $vm -Enable -ResourceGroupName RESOURCEGROUPNAME-StorageAccountName BOOTDIAGNOSTICSSTORAGEACCOUNTNAME
$vm = Set-AzureRmVMOSDisk -VM $vm -VhdUri (Get-AzureStorageBlob -Context $context -Blob "YOURDISKNAME.vhd" -Container "vhds").ICloudBlob.uri.AbsoluteUri -CreateOption Attach -Name "YOURDISKNAME"
New-AzureRmVM -ResourceGroupName RESOURCEGROUPNAME -Location westeurope -VM $vm

# Add additional VHD files to the VM.
Add-AzureRmVMDataDisk -VM $VMName -

# Migrate the unmanaged disks to managed disks.
Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name $VMName -Force
ConvertTo-AzureRmVMManagedDisk -ResourceGroupName $ResourceGroup -VMName $VMName
