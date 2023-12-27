---
description: >-
  PowerShell script to silently create a System Restore Point of the system
  drive.
---

# Windows Restore Point

## Overview

{% hint style="info" %}
**Dev Insight:** As of Windows 8, the default settings will not allow the creation of more than one system restore point in 24 hours. This script works around this limitation by temporarily modifying this setting.
{% endhint %}

This script can be used to automate the creation of System Restore Points on client machines, or to create a one-off checkpoint before applying changes to a machine.

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/CreateRestorePoint.ps1" %}

## Examples

### Example 1

```powershell
.\CreateRestorePoint.ps1
```

This example creates a checkpoint with the default description of "Scripted Checkpoint".

### Example 2

```powershell
.\CreateRestorePoint.ps1 -Description 'Installed QuickBooks'
```

This example creates a restore point with the description "Installed QuickBooks".

***

## Parameters

`-Description`

Optional string parameter that allows you to set a description for the restore point. If not provided, a default description of "Scripted Checkpoint" will be used.
