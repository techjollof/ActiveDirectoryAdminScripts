# Create-ADGroups Function

## Synopsis
Creates Active Directory (AD) groups in a specified Organizational Unit (OU).

## Description
The `Create-ADGroups` function is designed to facilitate the creation of Active Directory groups within a specified Organizational Unit (OU). This function is versatile, supporting both production and demo environments:

- **Production Mode**: When creating groups in production, users can specify a file that contains the details of the groups to be created. This mode allows for precise and bulk group creation based on predefined settings.
  
- **Demo Mode**: This mode is intended for testing and experimentation. Users can easily generate demo groups without the need for detailed specifications. The function allows the creation of only security groups or only distribution groups, catering to different testing scenarios.

The function also includes robust validation for the number of groups to be created, ensuring that input is either a valid integer or the string "Unlimited". This flexibility allows for both controlled and expansive group creation.

## Parameters

### `-OUPath`
- **Type**: `string`
- **Description**: Specifies the path of the Organizational Unit (OU) where the groups will be created.

### `-GroupCreationFile`
- **Type**: `string`
- **Parameter Set**: `Production`
- **Description**: A file containing the specifications for group creation. This parameter is used only when creating groups in production mode.

### `-NumberOfGroups`
- **Type**: `string`
- **Description**: Specifies the number of groups to create.
  - Can be an integer greater than or equal to 1.
  - Can also be set to "Unlimited" to create an indefinite number of groups.
- **Validation**: Must either be an integer (≥ 1) or the string "Unlimited". 

### `-DemoADGroups`
- **Type**: `switch`
- **Parameter Set**: `DemoObject`
- **Description**: Indicates that demo Active Directory groups should be created.

### `-OnlyScuirtyGroup`
- **Type**: `switch`
- **Parameter Set**: `DemoObject`, `Security`
- **Description**: Specifies that only security groups should be created.

### `-OnlyDistributionGroup`
- **Type**: `switch`
- **Parameter Set**: `DemoObject`, `Distribution`
- **Description**: Specifies that only distribution groups should be created.

## Parameter Sets
The function supports multiple parameter sets:
- **Production**: Requires `-GroupCreationFile` and uses `-NumberOfGroups`.
- **DemoObject**: Uses switches for creating demo groups and allows filtering by group type (`-OnlyScuirtyGroup` and `-OnlyDistributionGroup`).

## Examples

### Example 1: Create groups in production
```powershell
Create-ADGroups -OUPath "OU=Groups,DC=example,DC=com" -GroupCreationFile "C:\groups.txt" -NumberOfGroups 10
```
Creates 10 groups in the specified OU based on the details in the groups.txt file.

### Example 2: Create unlimited demo security groups
```powershell
Create-ADGroups -OUPath "OU=Demo,DC=example,DC=com" -DemoADGroups -OnlyScuirtyGroup -NumberOfGroups "Unlimited"
```
Generates an unlimited number of demo security groups in the specified OU.

### Example 3: Create a specified number of demo distribution groups
```powershell

Create-ADGroups -OUPath "OU=Demo,DC=example,DC=com" -DemoADGroups -OnlyDistributionGroup -NumberOfGroups 5
Creates 5 demo distribution groups in the specified OU.

```
### Example 4: Create 3 demo security groups

```powershell

Create-ADGroups -OUPath "OU=Test,DC=example,DC=com" -DemoADGroups -OnlyScuirtyGroup -NumberOfGroups 3
```

Creates 3 demo security groups in the OU OU=Test.

### Example 5: Create groups from a file in production
```powershell

Create-ADGroups -OUPath "OU=Staff,DC=example,DC=com" -GroupCreationFile "C:\productionGroups.txt" -NumberOfGroups 15
```

Creates 15 groups in the OU=Staff OU based on the definitions provided in productionGroups.txt.

### Example 6: Create unlimited demo distribution groups
```powershell

Create-ADGroups -OUPath "OU=Testing,DC=example,DC=com" -DemoADGroups -OnlyDistributionGroup -NumberOfGroups "Unlimited"
```
Generates an unlimited number of demo distribution groups in the OU=Testing OU.

### Notes
Ensure you have the necessary permissions to create groups in the specified OU.
