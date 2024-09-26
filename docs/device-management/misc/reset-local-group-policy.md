---
description: >-
  PowerShell script to silently backup and reset existing local group policy
  objects.
---

# Reset Local Group Policy

## Overview

This script creates a backup of the files stored in `C:\Windows\System32\GroupPolicy` and `C:\Windows\System32\GroupPolicyUsers`. After the backup is created, the script will delete the existing files to reset all locally set Group Policy Objects to "Not Configured".

By default, backups are stored in `C:\Backups\Group Policy`.&#x20;

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% hint style="info" %}
**Note:** This script has no effect on Group Policy Objects applied from Active Directory.
{% endhint %}

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/ResetLocalPolicies.ps1" %}

## Examples

```powershell
.\ResetLocalPolicies.ps1
```

This example creates a backup of the existing local group policy files (if any) and resets them back to "Not Configured".

***

## Parameters

This script has no parameters.
