---
description: >-
  PowerShell script to check for and install Microsoft Office application
  updates.
---

# Microsoft Office

## Overview

{% hint style="info" %}
**Dev Insight:** This script was extremely useful when patching for [CVE-2020-23397](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2023-23397).
{% endhint %}

This script will check for ClickToRun installations of Microsoft Office. If found, `OfficeC2RClient.exe` will be used to scan for and apply updates. If updates are found, users may be asked to close Microsoft Office applications to complete update installation.

**Prerequisites:** This script has no prerequisites.&#x20;

***

## Script

{% hint style="info" %}
Script will abort if no ClickToRun installations of Microsoft Office are detected.
{% endhint %}

{% @github-files/github-code-block url="https://github.com/redletterone/PowerShell/blob/main/scripts/UpdateOffice.ps1" %}

## Examples

```powershell
.\UpdateOffice.ps1
```

This example checks for ClickToRun installations of Microsoft Office. If found, a Microsoft Office update scan will be initiated.

***

## Parameters

This script has no parameters.
