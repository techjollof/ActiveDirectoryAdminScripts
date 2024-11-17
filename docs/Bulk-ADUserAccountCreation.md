### Bulk-ADUserAccountCreation

## Synopsis
Automates the creation of Active Directory user accounts in bulk, with support for both demo and production modes. The script generates random user attributes or uses a CSV input file for user data and customizes the user principal name (UPN), password, and other details.

## Description
This script provides an automated solution for creating multiple Active Directory (AD) user accounts. It offers two operation modes:
- **Demo Mode**: Requires minimal input, using predefined demo data files to simulate user creation.
- **Production Mode**: Requires an input CSV file containing user account details and generates AD users based on that data.

Key features include the generation of secure random passwords, customizable UPN formats, and the option to specify different Organizational Units (OUs) for user account creation.

---

## Syntax

```powershell
Bulk-ADUserAccountCreation
    [-IsDemoMode] 
    [-UserAccountsCsv <string>] 
    [-PasswordLength <int>] 
    [-PasswordSpecialCharacters <int>] 
    [-TargetOU <string>] 
    [-UPNDomains <string>] 
    [-SelectedUPNIndex <int>] 
    [-UPNSubStringLenght <int>] 
    [-UserCount <string>]
```

## Parameters

### `-IsDemoMode`
- **Description**: Specifies that the script should run in demo mode. This option generates random demo data for testing and does not require an input file.
- **Type**: `switch`
- **Required**: Yes, if demo mode is selected.

### `-UserAccountsCsv`
- **Description**: Specifies the path to the CSV file containing user account details (such as first name, last name, department, etc.). This parameter is required in production mode.
- **Type**: `string`
- **Required**: Yes, if not in demo mode.

### `-PasswordLength`
- **Description**: Defines the length of the randomly generated password for user accounts. The default is 12.
- **Type**: `int`
- **Required**: No
- **Valid Range**: 10 to 128

### `-PasswordSpecialCharacters`
- **Description**: Specifies the number of special characters to include in the generated password. The default is 4.
- **Type**: `int`
- **Required**: No
- **Valid Range**: 3 to 8

### `-TargetOU`
- **Description**: Specifies the Distinguished Name (DN) of the Organizational Unit (OU) where the user accounts will be created.
- **Type**: `string`
- **Required**: Yes, in both demo and production modes.

### `-UPNDomains`
- **Description**: A comma-separated list of valid domains for generating User Principal Names (UPNs).
- **Type**: `string`
- **Required**: Yes

### `-SelectedUPNIndex`
- **Description**: Specifies the UPN format to use for generating the User Principal Name (UPN). 
    - 1: `<alias>@domain` (First.LastName)
    - 2: `%m@domain` (First initial of first name)
    - 3: `%g.%s@domain` (First letter of first name and full last name)
    - 4: `%1g%s@domain` (First initial of first name + full last name)
    - 5: `%g%1s@domain` (First initial of first name + first initial of last name)
    - 6: `%s.%g@domain` (Full last name + first initial of first name)
    - 7: `%1s%g@domain` (First initial of last name + first initial of first name)
    - 8: `%s%1g@domain` (Full last name + first initial of first name)
- **Type**: `int`
- **Required**: Yes
- **Valid Values**: 1-8

### `-UPNSubStringLenght`
- **Description**: Adjusts the length of initials used in the UPN. If set to 2, the format will use the first two initials of the last name or first name.
- **Type**: `int`
- **Required**: No
- **Valid Range**: 1 to 5
- **Default**: 1

### `-UserCount`
- **Description**: Defines the number of user accounts to be created. Can be set to "Unlimited" or any integer greater than or equal to 1.
- **Type**: `string`
- **Required**: No
- **Default**: "5"
- **Valid Values**: "Unlimited" or any integer ≥ 1

---

## How It Works
1. **Demo Mode**: In demo mode, the script uses predefined demo files for departments, addresses, and user account information. Random values are generated for user details such as names, titles, and departments. It does not require an external input CSV file for user data.
   
2. **Production Mode**: In production mode, the script expects a CSV file containing user account information (e.g., first name, last name, department). The script uses this data to create user accounts in Active Directory, assigning them random passwords, and generating their UPNs based on the selected format.

3. The script validates all input parameters and ensures the specified Organizational Unit (OU) exists in Active Directory before attempting to create users.

4. User accounts are created using the `New-ADUser` cmdlet. If an error occurs during account creation, it is logged to an error file.

5. At the end of the process, the script exports the details of created accounts to a CSV file.

---

## Example Usage

### Example 1: Create 5 users with default settings
```powershell
.\Bulk-ADUserAccountCreation.ps1 -IsDemoMode -TargetOU "OU=Users,DC=domain,DC=com" -UPNDomains "domain.com" -SelectedUPNIndex 1
```

### Example 2: Create 10 users with custom password length
```powershell
.\Bulk-ADUserAccountCreation.ps1 -UserAccountsCsv "C:\path\to\user_accounts.csv" -TargetOU "OU=Users,DC=domain,DC=com" -UPNDomains "domain.com" -SelectedUPNIndex 2 -PasswordLength 16
```

### Example 3: Create all users in the list (unlimited) with custom account file
```powershell
.\Bulk-ADUserAccountCreation.ps1 -UserAccountsCsv "C:\path\to\user_accounts.csv" -TargetOU "OU=Users,DC=domain,DC=com" -UPNDomains "domain.com" -SelectedUPNIndex 3 -UserCount "Unlimited"
```

## Error Handling
- **Missing OU**: If the specified Organizational Unit (OU) does not exist, an error will be logged, and the script will terminate.
- **Invalid CSV File**: If the input CSV file cannot be found or is incorrectly formatted, an error will be logged.
- **Invalid Parameters**: If invalid values are provided for parameters such as `UserCount` or `SelectedUPNIndex`, an error will be thrown with a description of the issue.

## Requirements
- **Active Directory Module**: The script requires the Active Directory PowerShell module to interact with the AD environment.
- **Permissions**: The user running the script must have sufficient permissions to create accounts in the specified Organizational Unit (OU).

## Known Limitations
- The script currently supports only a subset of common UPN formats. Users may need to manually customize UPN generation formats if other patterns are needed.
- **CSV Input File**: The CSV input file should include required fields such as `GivenName` and `Surname`. Additional fields such as `UserPrincipalName`, `Department` and `AccountPassword` are optional.

## Troubleshooting
- **Error Log**: If an error occurs, check the log file generated in the `Logs` directory for details.
- **Missing Fields in CSV**: Ensure the CSV file has the required columns for the script to correctly generate user accounts. If columns are missing, the script may fail to create users.

---

## Authors
- **Author**: LastStopIT
- **Contact**: techjollof@gmail.com

---

## License
This script is provided under the MIT License. You may use, modify, and distribute it in accordance with the terms of this license.