---
description: PowerShell script to silently uninstall Microsoft Silverlight (x32 & x64).
---

# Silverlight

## Overview

{% hint style="info" %}
**Dev Insight:** This script was written to help organizations reduce their attack surface by removing Microsoft Silverlight, mitigating multiple known vulnerabilities.
{% endhint %}

On **May 25th, 2022**, the [CISA](https://www.cisa.gov/) added multiple known vulnerabilities in Microsoft Silverlight to their catalog.&#x20;

* [CVE-2016-0034](https://nvd.nist.gov/vuln/detail/CVE-2016-0034)
* [CVE-2015-1671](https://nvd.nist.gov/vuln/detail/CVE-2015-1671)
* [CVE-2013-3896](https://nvd.nist.gov/vuln/detail/CVE-2013-3896)
* [CVE-2013-0074](https://nvd.nist.gov/vuln/detail/CVE-2013-0074)

Microsoft discontinued support of Silverlight on **October 12, 2021**. Unless required, it is recommended to uninstall Silverlight from your client's devices.

{% embed url="https://support.microsoft.com/en-us/windows/silverlight-end-of-support-0a3be3c7-bead-e203-2dfd-74f0a64f1788" %}

**Prerequisites:** This script requires no additional setup. Simply deploy it via your RMM.

## Script

{% embed url="https://gist.github.com/wise-io/13e02861b04073079957d7277e40d768" %}

## Learn More

Want to learn more about how this script works? Included below are official documentation links for all cmdlets used in this script, as well as other useful documentation where applicable.

{% embed url="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/msiexec" %}

**Cmdlet Documentation:**

* [Get-ChildItem](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-childitem?view=powershell-7.2)
* [Get-ItemProperty](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-itemproperty?view=powershell-7.2)
* [Select-Object](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/select-object?view=powershell-7.2)
* [Where-Object](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/where-object?view=powershell-7.2)
* [Write-Output](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-output?view=powershell-7.2)
