# function Create-ADGroups {
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$OUPath, # The path of the OU where groups will be created
    
    [Parameter(ParameterSetName = "Production")]
    [string]$GroupCreationFile,
    
    [ValidateScript({
            if ($_ -eq "Unlimited") {
                return $true
            }
            elseif ($_ -as [int] -and $_ -ge 1) {
                return $true
            }
            else {
                throw "NumberOfGroups must be an integer greater than or equal to 1 or the string 'Unlimited'."
            }
        })]
    [string]$NumberOfGroups, # The number of groups to create
    
    [Parameter(ParameterSetName = "DemoObject")]
    [switch]$DemoADGroups,
    
    [Parameter()]
    [switch]$OnlyScuirtyGroup, # Specifies that only security groups should be created
    
    [Parameter()]
    [switch]$OnlyDistributionGroup # Specifies that only distribution groups should be created
)
    
# Check for mutual exclusivity at runtime
if ($OnlyDistributionGroup -and $OnlyScuirtyGroup) {
    throw "OnlyDistributionGroup and OnlyScuirtyGroup cannot both be enabled. Please select only one."
}
    
# Check if the OU exists
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'")) {
    throw "The specified OU does not exist: $OUPath"
}

# Load group names
if (!$GroupCreationFile) {
    if (!$DemoADGroups) {
        throw "The GroupCreationFile parameter is empty or DemoADGroups has NOT been provided. Specify the GroupCreationFile (txt or csv) or use DemoADGroups for testing."
    }
    else {
        $groupNames = Import-Csv -Path ".\src\DemoGroups.csv"
    }
}
else {
    if (Test-Path $GroupCreationFile) {
        $groupNames = Import-Csv -Path $GroupCreationFile 
    }
    else {
        throw "The GroupCreationFile path is invalid, check and use the full path."
    }
}

# Convert the NumberOfGroups input to an integer or handle the "Unlimited" case
$MaxGroups = if ($NumberOfGroups -eq "Unlimited") { $groupNames.Count } else { [int]$NumberOfGroups }
# Select random group names without duplicates
$selectedGroups = if ($NumberOfGroups -eq "Unlimited") { $groupNames } else { $groupNames | Get-Random -Count ([math]::Min($MaxGroups, $groupNames.Count)) }

$groupTypeselection = if (!$OnlyScuirtyGroup) {
    if (!$OnlyDistributionGroup) {
        "Distribution"
    }
    "Security"
}

foreach ($groupName in $selectedGroups) {
    # Ensure group properties are properly defined
    $name = $groupName.Name.Trim()
    $groupScope = if ($groupName.GroupScope) { $groupName.GroupScope.Trim() } else { "Global" }
    $groupType = if ($groupTypeselection) { $groupTypeselection } elseif ($groupName.GroupType) { $groupName.GroupType.Trim() } else { "Security" }
        

    $groupInfo = @{
        Name          = $name
        GroupScope    = $groupScope
        GroupCategory = $groupType
        Path          = $OUPath # Ensure group is created in the specified OU
    }

    # Create the group
    try {
        New-ADGroup @groupInfo
    }
    catch {
        Write-Error "Failed to create group '$name'. Error: $_"
    }
}
# }