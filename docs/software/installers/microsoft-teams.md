---
description: >-
  PowerShell script to silently install the new Microsoft Teams client machine
  wide.
---

# Microsoft Teams

## Overview

This script downloads and installs the latest Microsoft Teams (New) machine wide. If the Teams (Classic) Machine-Wide installer is present, it will be uninstalled. With its removal, Teams (Classic) will also be removed from all user profiles on their next login.

{% embed url="https://learn.microsoft.com/en-us/microsoftteams/new-teams-bulk-install-client" %}

**Prerequisites:** None

***

## Script

{% @github-files/github-code-block url="https://github.com/wise-io/scripts/blob/main/scripts/InstallTeams.ps1" %}

***

## Parameters

`-Force`

Optional switch parameter - attempts install even if an existing installation is detected.
