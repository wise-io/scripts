---
description: PowerShell script to silently install Microsoft Defender for Endpoint (MDE).
---

# Microsoft Defender for Endpoint

## Overview

{% hint style="info" %}
**Dev Insight:** This script can be used to deploy Microsoft Defender for Endpoint to domain joined devices seamlessly from your RMM of choice while you plan your migrations from Active Directory to Entra joined devices.
{% endhint %}

This script utilizes the onboarding package script provided by Microsoft to install Microsoft Defender for Endpoint (MDE) on Windows devices, including Windows 10 - 11 and Windows Server 2012 R2 - 2025.

{% embed url="https://learn.microsoft.com/en-us/defender-endpoint/mde-planning-guide" %}

**Prerequisites:**

* Microsoft user licenses that include MDE (such as Microsoft 365 Business Premium)
* Microsoft Defender for Endpoint server licenses (such as Microsoft Defender for Business servers)
* The MDE Onboarding Package for the M365 tenant being onboarded

***

## Setup

{% hint style="warning" %}
**Note:** Each M365 tenant will have a different onboarding package. **You should not use the same onboarding package for multiple organizations.**
{% endhint %}

To retrieve the necessary onboarding package:

1. Login to the M365 tenant&#x20;
2. Navigate to the Security portal
3. Click Settings > Endpoints > Onboarding
4. Select Windows 10 / 11 as OS type
5. Download the Onboarding Package and save at a location accessible to the script

***

## Script

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/InstallMicrosoftDefenderForEndpoint.ps1" %}

***

## Parameters

`-OnboardingPackage`

Path to the onboarding package. File extension should be `.zip`.
