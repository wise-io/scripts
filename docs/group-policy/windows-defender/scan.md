---
description: PowerShell script to run Windows Defender scans.
---

# Run Scans

## Overview

This can be used to run on demand scans with Windows Defender, including offline scans and scans of individual files/folders.&#x20;

_This script can also be run on a schedule with your RMM of choice. Alternatively, let Windows handle scheduled scans with the policies set in the script above._

{% hint style="danger" %}
**Warning:** Using the _offline_ scan type in the below script will restart a user's device and may result in data loss. Use with caution.
{% endhint %}

**Usage Example:** `.\ScanDefender.ps1 -Path 'C:\Users\john.doe\Downloads'`

{% embed url="https://gist.github.com/wise-io/4fa3fc00274a45ffa6b9df1f92126abc" %}

## Learn More

Want to learn more about how this script works? Included below are official documentation links for all cmdlets used in this script, as well as other useful documentation where applicable.

{% embed url="https://docs.microsoft.com/en-us/powershell/module/defender?view=windowsserver2019-ps" %}
