<#
.SYNOPSIS
This script creates Active Directory user accounts based on input data, either in demo mode with minimal parameters or in production mode using a CSV file.

.DESCRIPTION
This script allows the creation of Active Directory user accounts either in demo mode or production mode. It supports the creation of multiple user accounts by reading input from a CSV file or from pre-configured demo data. The script supports generating random passwords, User Principal Names (UPN), and more. It also handles the creation of users in a specified organizational unit (OU) and allows for flexible UPN formats.

.PARAMETER IsDemoMode
Specifies whether to run the script in demo mode. When in demo mode, minimal parameters are required, and the script will use predefined data files such as "DemoUsers2100.csv" for user information. This switch is mandatory when in demo mode.

.PARAMETER UserAccountsCsv
Specifies the path to the CSV file containing user account details for production mode. The file should contain information like the user's name, title, department, and other necessary details for creating the account. This parameter is mandatory in production mode.

.PARAMETER PasswordLength
Specifies the length of the generated password. The default length is 12 characters, and the value must be between 10 and 128 characters. This parameter is optional.

.PARAMETER PasswordSpecialCharacters
Specifies the number of special characters to include in the generated password. The default value is 4, and the value must be between 3 and 8. This parameter is optional.

.PARAMETER TargetOU
Specifies the Distinguished Name (DN) of the target Organizational Unit (OU) where the user accounts will be created. This is a mandatory parameter in both demo and production modes.

.PARAMETER UPNDomains
Specifies the list of available UPN (User Principal Name) domains. The script will use this domain for the generated UPN of each user account. This parameter is mandatory.

.PARAMETER SelectedUPNIndex
Specifies the format for generating the UPN based on the user's first and last names. Valid values are:
  1 - <alias>@domain
  2 - %m@domain (First initial of first name)
  3 - %g.%s@domain (First letter of first name and full last name)
  4 - %1g%s@domain (First initial of first name + full last name)
  5 - %g%1s@domain (First initial of first name + first initial of last name)
  6 - %s.%g@domain (Full last name + first initial of first name)
  7 - %1s%g@domain (First initial of last name + first initial of first name)
  8 - %s%1g@domain (Full last name + first initial of first name)
This parameter is mandatory.

.PARAMETER UPNSubStringLength
Specifies the length of substrings used in the UPN when generating first and last initials. The default value is 1. If set to 2, it uses the first two characters of the first name or last name. This parameter is optional.

.PARAMETER UserCount
Specifies the number of users to create. The value can be an integer greater than or equal to 1, or the string "Unlimited" to create users for the entire list in the CSV file. The default value is 5.

.EXAMPLE
# Demo mode example
.\Create-ADUsers.ps1 -IsDemoMode -TargetOU "OU=Users,DC=example,DC=com" -UPNDomains "example.com" -SelectedUPNIndex 3 -UserCount "10"

# Production mode example with a CSV file for user account data
.\Create-ADUsers.ps1 -UserAccountsCsv "C:\path\to\users.csv" -TargetOU "OU=Users,DC=example,DC=com" -UPNDomains "example.com" -SelectedUPNIndex 1 -UserCount "Unlimited"

# Generate random password with specific length and special characters
.\Create-ADUsers.ps1 -IsDemoMode -TargetOU "OU=Users,DC=example,DC=com" -UPNDomains "example.com" -PasswordLength 16 -PasswordSpecialCharacters 6

.NOTES
This script requires the Active Directory module for PowerShell. Ensure the module is installed and you have the necessary privileges to create user accounts.

#>


[CmdletBinding()]
param (
    # Demo mode: Requires minimal parameters
    [Parameter(ParameterSetName = "IsDemoMode", Mandatory = $true)]
    [switch]$IsDemoMode,

    # User account file for production mode
    [Parameter(Mandatory, ParameterSetName = "Production")]
    [string]$UserAccountsCsv,

    # Optional parameter for password length (default: 12)
    [Parameter()]
    [ValidateRange(10, 128)]  # Ensure reasonable password lengths
    [int]$PasswordLength = 12,

    [Parameter()]
    [ValidateRange(3, 8)]  # Validate the number of special characters in the password
    [int]$PasswordSpecialCharacters = 4,

    # Distinguished Name of the target Organizational Unit
    [Parameter(Mandatory, ParameterSetName = "IsDemoMode")]
    [Parameter(ParameterSetName = "Production")]
    [string]$TargetOU,

    # Array of available UPN domains
    [Parameter(Mandatory)]
    [string]$UPNDomains,

    # UPN option for domain selection (validated against a fixed set of values)
    # The format option to use for generating the UPN. Valid values are:
    # 1 - <alias>@domain
    # 2 - %m@domain (First initial of first name)
    # 3 - %g.%s@domain (First letter of first name and full last name)
    # 4 - %1g%s@domain (First initial of first name + full last name)
    # 5 - %g%1s@domain (First initial of first name + first initial of last name)
    # 6 - %s.%g@domain (Full last name + first initial of first name)
    # 7 - %1s%g@domain (First initial of last name + first initial of first name)
    # 8 - %s%1g@domain (Full last name + first initial of first name)
    [Parameter(Mandatory)]
    [ValidateSet(1, 2, 3, 4, 5, 6, 7, 8)]
    [int]$SelectedUPNIndex,

    # This addresses the length selections in the UPN substring if not using the full name
    # If set to 2
    # %2s%g@domain (first 2 initials of last name + first initial of first name)
    # %s%2g@domain (Full last name + first 2 initials of first name)
    [Parameter()]
    [ValidateRange(1, 5)]
    [int]$UPNSubStringLength = 1,

    # Number of users: accepts "Unlimited" or an integer ≥ 1
    [Parameter()]
    [ValidateScript({
            if ($_ -eq "Unlimited") { return $true }
            elseif ($_ -as [int] -and $_ -ge 1) { return $true }
            else { throw "UserCount must be 'Unlimited' or an integer ≥ 1." }
        })]
    [string]$UserCount = "5"  # Default as string for flexibility
)


#...................................
# Functions
#...................................

# Test whether an OU already exists
Function Test-OUPath {
    param(
        [string]$OUPath
    )

    try {
        # Attempt to get the organizational unit
        return  (Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction Stop  | Out-Null)
    }
    catch {
        Write-Error "Error accessing OU: $_"
        return $false  # OU does not exist
    }
}

# Random password generator
Function Get-TempPassword {
    Param(
        [int]$PasswordLength,
        [int]$PasswordSpecialCharacters
    )

    try {
        add-type -AssemblyName System.Web
        $securePassword = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, $PasswordSpecialCharacters)  # 4 special characters
    return $securePassword
        
    }
    catch {
         Log-Error -ErrorMessage "$_"
    }
    
}


# Function to generate User Principal Name (UPN)
Function New-AccountUPN {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FirstName,

        [Parameter(Mandatory = $true)]
        [string]$LastName,

        [Parameter(Mandatory = $true)]
        [string]$Domain,

        [Parameter(Mandatory = $true)]
        [int]$SelectedUPNIndex,

        # this address the lenght selections in the upn subscription if not using the full name
        # If set  to 2
        # %2s%g@domain (first 2 initial of last name + first initial of first name)
        # %s%2g@domain (Full last name + first 2 initial of first name)
        [Parameter()]
        [ValidateRange(1, 5)]
        [int]$UPNSubStringLenght = 1
    )

    # Generate first initial and last initial for various formats
    $FirstInitial = $FirstName.Substring(0, $UPNSubStringLenght).ToLower()
    $LastInitial = $LastName.Substring(0, $UPNSubStringLenght).ToLower()

    # Initialize the UPN variable
    $UPN = ""

    # Format the UPN based on the selected option
    switch ($SelectedUPNIndex) {
        1 { $UPN = "$FirstInitial$LastName@$Domain" }
        2 { $UPN = "$FirstInitial@$Domain" }
        3 { $UPN = "$($FirstName.Substring(0,1).ToLower()).$LastName@$Domain" }
        4 { $UPN = "$FirstInitial$LastName@$Domain" }
        5 { $UPN = "$FirstInitial$LastInitial@$Domain" }
        6 { $UPN = "$LastName.$FirstInitial@$Domain" }
        7 { $UPN = "$LastInitial$FirstInitial@$Domain" }
        8 { $UPN = "$LastName$FirstInitial@$Domain" }
        default { Write-Host "Invalid option selected. Please choose a valid option (1-8)."; return }
    }

    # Output the generated UPN
    return $UPN
}


# Log errors to a file
Function Log-Error {
    param([string]$ErrorMessage)

    $LogFilePath = Join-Path -Path (Join-Path $BaseDirectory "Logs") -ChildPath "ErrorLog_$(Get-Date -Format 'yyyyMMdd').log"
    if (!(Test-Path -Path $LogFilePath)) {
        New-Item -ItemType File -Path $LogFilePath -Force | Out-Null
    }
    Add-Content -Path $LogFilePath -Value "$(Get-Date) - $($ErrorMessage)"
}

# Ensure directory exists
Function Test-DirectoryExists {
    param([string]$DirectoryPath)
    if (!(Test-Path $DirectoryPath)) {
        New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
    }
}

#...................................
# Main Script
#...................................

# Ensure Logs and Results directories exist in the correct location
$BaseDirectory = Split-Path -Parent $PSScriptRoot
Test-DirectoryExists -DirectoryPath (Join-Path $BaseDirectory "Logs")
Test-DirectoryExists -DirectoryPath (Join-Path $BaseDirectory "Results")


#get the list of departments and address
if ($IsDemoMode) {
    $UserAccountsCsv = (Get-ChildItem -Path (Split-Path $PSScriptRoot) -Recurse -Filter "DemoUsers2100.csv").FullName
    $Departments = Get-Content -Path (Get-ChildItem -Path (Split-Path $PSScriptRoot) -Recurse -Filter "departments.json").FullName | ConvertFrom-Json 
    $UserAddressInfo = Import-CSV  (Get-ChildItem -Path (Split-Path $PSScriptRoot) -Recurse -Filter "Addresses2100.csv").FullName 
}


if (!(Test-Path $UserAccountsCsv)) {
    Log-Error -ErrorMessage "The input file name $($UserAccountsCsv) you specified can't be found in the script directory or invalid path. You can add the file ($($UserAccountsCsv)) to the src directory or provide the full path."
    throw "The input file name you specified can't be found in the script directory or invalid path. You can add the file $($UserAccountsCsv) to the 'src' directory or provide the full path."
}

# Test OU, results hasables, load account information, 
# number of users - Convert the UserCount input to an integer or handle the "Unlimited" case
# Password length and character set to use for random password generation
Test-OUPath -OUPath $TargetOU
$CreatedAccounts = @()
$UserAccounts = if ($IsDemoMode) { @(Get-Content $UserAccountsCsv) } else { Import-Csv -Path $UserAccountsCsv }
$UserCount = if ($UserCount -eq "Unlimited") { $UserAccounts.Count - 1 } else { [int]$UserCount - 1 }
$randompassword = Get-TempPassword -PasswordLength $PasswordLength -PasswordSpecialCharacters $PasswordSpecialCharacters


foreach ($UserAccount in $UserAccounts[0..$UserCount]) {

    try {

        $FirstName = if ($IsDemoMode) { ($UserAccount.Trim()).Split(",")[0] }else { $UserAccount.GivenName }
        $LastName = if ($IsDemoMode) { ($UserAccount.Trim()).Split(",")[0] }else { $UserAccount.Surname }

        $UserUPN = if ($IsDemoMode -or -not $UserAccount.UserPrincipalName -or $UserAccount.UserPrincipalName -eq "" -or $UserAccount.UserPrincipalName -notmatch "@" -or $UserAccount.UserPrincipalName -match "@.*\.[a-z]+$") {
            New-AccountUPN -FirstName $(if ($IsDemoMode) { $FirstName } else { $UserAccount.Surname }) -LastName $(if ($IsDemoMode) { $LastName } else { $UserAccount.Surname }) -Domain $UPNDomains -SelectedUPNIndex $SelectedUPNIndex -UPNSubStringLenght $UPNSubStringLenght
        }
        else {
            $UserAccount.UserPrincipalName
        }
    
        $UserSAN = if ($IsDemoMode -or [string]::IsNullOrWhiteSpace($UserAccount.SamAccountName)) { $UserUPN.Split('@')[0].Trim() } else { $UserAccount.SamAccountName }

        $UserAccountPassword = if ($IsDemoMode -or -not $UserAccount.AccountPassword -or [string]::IsNullOrWhiteSpace($UserAccount.AccountPassword)) {
            $randompassword
        }
        else {
            $UserAccount.AccountPassword
        }
    
        # Department & title & other information
        $UserDepartment = if ($IsDemoMode) { ($Departments | Get-Random).Name }else { $UserAccount.Department }
        $UserTitle = if ($IsDemoMode) { $UserDepartment.Positions | Get-Random }else { $UserAccount.Title } 
        $UserInfo = if ($IsDemoMode) { $UserAddressInfo | Get-Random }else {
            @{
                City       = $UserAccount.City
                PostalCode = $UserAccount.PostalCode
                Street     = $UserAccount.StreetAddress
                State      = $UserAccount.State
                Country    = $UserAccount.Country
            } 
        } 

        # Generate the UPN based on the user's information and selected domain
        $UserProperties = @{
            Name                  = "$FirstName $LastName"
            Displayname           = "$FirstName $LastName"
            SamAccountName        = $UserSAN
            GivenName             = $FirstName
            Surname               = $LastName
            Department            = $UserDepartment
            Title                 = $UserTitle
            UserPrincipalName     = $UserUPN
            AccountPassword       = ConvertTo-SecureString ($UserAccountPassword) -AsPlainText -Force
            City                  = $UserInfo.City
            PostalCode            = $UserInfo.PostalCode
            StreetAddress         = $UserInfo.Street
            Country               = $UserInfo.Country
            State                 = $UserInfo.State
            Path                  = $TargetOU
            ChangePasswordAtLogon = $false
            Enabled               = $true
            ErrorAction           = "SilentlyContinue"
        }

        #create user account
        New-ADUser @UserProperties
        
        #Update account passowrd to plain text for export
        $UserProperties.AccountPassword = $UserAccountPassword
        $CreatedAccounts += [PSCustomObject]$UserProperties
    }
    catch {
        Log-Error -ErrorMessage "$_ : $UserSAN "
    }
}




#...................................
# Finished
#...................................
# Define the output CSV file path using PSScriptRoot

if ($CreatedAccounts) {
    # Export created accounts
    $ResultsDir = Join-Path $BaseDirectory "Results"
    $OutputFile = Join-Path -Path $ResultsDir -ChildPath ($(if ($IsDemoMode) { "Demo_" } else { "Prod_" }) + "CreatedAccounts_$(Get-Date -Format 'yyyyMMdd_HH_mm').csv")
    $CreatedAccounts | Export-Csv -Path $OutputFile -NoTypeInformation
    Write-Host "User accounts created and saved to $OutputFile"

    Log-Error -ErrorMessage "$_"
}
