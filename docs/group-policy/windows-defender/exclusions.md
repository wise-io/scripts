---
description: PowerShell script to manage Windows Defender exclusions.
---

# Exclusions

## Overview

This script can be used to add, remove, or audit exclusions for Windows Defender.&#x20;

**Prerequisites:** This script requires no additional setup. Simply deploy it via your RMM.

{% embed url="https://gist.github.com/wise-io/7d82c4216c5007a5be70c15699d338ff" %}

## Parameters

**`-Audit`**

Displays a list of all currently applied exclusions rules after any new rules have been applied. If no parameters are passed to the script, `-Audit` is used.

**Usage:** `.\ManageDefenderExclusions.ps1 -Audit`



**`-ASR`**

Specifies the files and paths to exclude from Attack Surface Reduction (ASR) rules. Specify the folders or files and resources that should be excluded from ASR rules. Enter a folder path or a fully qualified resource name. For example, "C:\Windows" will exclude all files in that directory. "C:\Windows\App.exe" will exclude only that specific file in that specific folder.

**Usage:** `.\ManageDefenderExclusions.ps1 -ASR C:\Users\john.doe\dev`



**`-Ext`**

Specifies an array of file name extensions, such as obj or lib, to exclude from scheduled, custom, and real-time scanning.

**Usage:** `.\ManageDefenderExclusions.ps1 -Ext ost, pst`



**`-IP`**

Specifies an array of IP addresses to exclude from scheduled and real-time scanning.

**Usage:** `.\ManageDefenderExclusions.ps1 -IP 127.0.0.1`



**`-Path`**

Specifies an array of file paths to exclude from scheduled and real-time scanning.&#x20;

**Usage:** `.\ManageDefenderExclusions.ps1 -Path "C:\Utilities"`



**`-Process`**

Specifies an array of processes, as paths to process images.&#x20;

**Usage:** `.\ManageDefenderExclusions.ps1 -Process Code.exe`



**`-Remove`**

Removes the exclusions that you specify.

**Usage:** `.\ManageDefenderExclusions.ps1 -Remove -Ext ost, pst -Path "C:\Utilities"`

## Learn More

Want to learn more about how this script works? Included below are official documentation links for all cmdlets used in this script, as well as other useful documentation where applicable.

{% embed url="https://docs.microsoft.com/en-us/powershell/module/defender?view=windowsserver2019-ps" %}

{% embed url="https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/common-exclusion-mistakes-microsoft-defender-antivirus?view=o365-worldwide" %}
