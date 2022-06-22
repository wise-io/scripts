---
description: PowerShell script to manage local administrators security group members.
---

# Manage Local Admins

## Overview

{% hint style="info" %}
**Note:** This script should be run with administrator or system privileges.
{% endhint %}

**Prerequisites:**&#x20;

Add your list of admin users to the script in the `$Admins` array declaration. You will need to list the user principal source as well.&#x20;

**Examples:**

* `'$env:computername\Administrator'`
* `'AzureAD\Administrator'`
* `'DOMAIN\Administrator'`

Alternatively, you can pass your admin users at runtime using the `-admins` parameter.

## Script

**Usage:** `.\ManageLocalAdmins.ps1 -Admins "$env:computername\MSP Name"`

{% embed url="https://gist.github.com/wise-io/8b97ea4023d7799b1ef610ee18b15cbd" %}

## Learn More

Want to learn more about how this script works? Included below are official documentation links for all cmdlets used in this script, as well as other useful documentation where applicable.

**Cmdlet Documentation:**

* [Add-LocalGroupMember](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/add-localgroupmember?view=powershell-5.1)
* [Get-LocalGroupMember](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/get-localgroupmember?view=powershell-5.1)
* [Remove-LocalGroupMember](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.localaccounts/remove-localgroupmember?view=powershell-5.1)
* [Write-Output](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-output?view=powershell-5.1)
