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

# Specify the license you with to go to and the one you wish to remove
Write-Host "Enter the SKU you wish to enable. Copy and paste the complete SKU. For example, tennantname:product:"
$SKUTo = Read-Host
$SKUToListLicenseOptions = $SKUTo.Split(':')[-1]
Write-Host "Enter the SKU you wish to disable. Copy and paste the complete SKU. For example, tennantname:product:"
$SKUFrom = Read-Host

# Show the licenseoptions for the SKU you are changing to
$ServicePlans = Get-MsolAccountSku | Where {$_.SkuPartNumber -eq $SKUToListLicenseOptions}
$ServicePlans.ServiceStatus

# Specify the name(s) of the license options you want to disable. For multiple, use a comma with no spaces between each one.
# For example: $NewLicenseOption = New-MsolLicenseOptions -AccountSkuId $SKUTo -DisabledPlans SWAY,Deskless,YAMMER_ENTERPRISE
$LicenseOption = New-MsolLicenseOptions -AccountSkuId $SKUTo -DisabledPlans <replace-with-license-option(s)>

# Get list of users with $SKUFrom and export them to a CSV file
Get-MsolUser -All `
    | Where {$_.isLicensed -eq “TRUE” -and $_.Licenses.AccountSKUID -eq $SKUFrom} `
    | Export-Csv -Path $CSVPath

# Assign the licenses to the user(s), disable any unwanted service plans and disable the previous subscription
$Users = import-csv $CSVPath -delimiter ","
foreach ($User in $Users)
{
    $UserName=$User.UserPrincipalName
    Set-MsolUserLicense -UserPrincipalName $UserName -AddLicenses $SKUTo -LicenseOptions $licenseOption -RemoveLicenses $SKUFrom
}