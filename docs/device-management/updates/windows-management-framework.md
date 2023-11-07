---
description: PowerShell script to update WMF to 5.1 for easier management.
---

# Windows Management Framework

## Overview

{% hint style="info" %}
**Dev Insight:** Hopefully you won't find yourself needing to manage EOL operating systems with PowerShell, but if you do, having access to PowerShell 5.1 helps!
{% endhint %}

This script downloads and installs the necessary Windows Update files to update the Windows Management Framework to 5.1. The necessary .NET Framework version will also be installed if not already present.

**Prerequisites:** This script has no prerequisites.&#x20;

**Notes:**

* This script requires at least PowerShell 4.0 (meaning Windows 7 SP1 is the oldest supported OS).
* This script will abort if it detects it is running in PowerShell 5.1 (meaning WMF 5.1 is already installed).

***

## Script

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/UpdateWMF.ps1" %}

## Examples

```powershell
.\UpdateWMF.ps1
```

This example downloads and installs the necessary Windows Update files to update the Windows Management Framework to 5.1.

***

## Parameters

This script has no parameters.

