#####################################################################################
#                                                                                   #
# Before you start, ensure that the MSOL PowerShell module is installed.            #
# If not, run install-module msol                                                   #
# You will need to be running powershell via the run as administrator option        #
#                                                                                   #
#####################################################################################

# Check if the PowerShell Module is loaded for MS Office
If ( ! (Get-module MSOnline )) {
    Import-Module MSOnline
    }

# Login to Office 365
Connect-MsolService

# Set path for csv file location
$CSVPath = '~\Desktop\users.csv'

# Get the SKU's that are currently subscribed to on the tennant
Get-MsolAccountSku

$SKUTo = Read-Host -Prompt "Enter the SKU you wish to enable"
$SKUFrom = Read-Host -Prompt "Enter the SKU you wish to disable"

# Show the licenseoptions for the SKU you are changing to
$ServicePlans = Get-MsolAccountSku | Where {$_.SkuPartNumber -eq $SKUTo}
$ServicePlans.ServiceStatus

# Specify the name(s) of the license options you want to disable. For multiple, use a comma with no spaces between each one.
$DisableServicePlan = Read-Host -Prompt "Enter the name for the service plans to disable for the SKU you are changing to. If multiple, seperate by using a comma between each one"
$NewLicenseOption = New-MsolLicenseOptions -AccountSkuId $SKUTo -DisabledPlans $DisableServicePlan

# Get list of users with SKUFrom
Get-MsolUser -All `
    | Where {$_.isLicensed -eq “TRUE” -and $_.Licenses.AccountSKUID -eq $SKUFrom} `
    | Export-Csv -Path $CSVPath

# Assign the licenses to the user(s), disable any unwanted service plans and disable the previous subscription
$users = import-csv $CSVPath -delimiter ","
foreach ($user in $users)
{
    $upn=$user.UserPrincipalName
    Set-MsolUserLicense -UserPrincipalName $upn -AddLicenses $SKUTo -LicenseOptions $NewlicenseOption -RemoveLicenses $SKUFrom
}