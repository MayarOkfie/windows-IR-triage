# windows-IR-triage#
Windows IR Triage (MVP)

A simple defensive PowerShell tool that collects basic Windows triage information
to support incident response and DFIR learning.

## Overview
This project is a menu-driven PowerShell script designed as a **learning-focused**
IR triage tool. It gathers key system and registry-based indicators that are commonly
reviewed during initial incident response.

## Features
- Menu-driven workflow (Scan / Export / Exit)
- Collects basic system information
- Enumerates local users (basic)
- Extracts persistence-related registry keys:
  - Run / RunOnce (HKLM + HKCU)
- Exports results to JSON and TXT formats

## What the Scan collects (MVP)
- System information:
  - Computer name
  - OS version and build
  - Last boot time
- Local user list (names only)
- Registry persistence locations:
  - Run / RunOnce keys

## Export
- JSON file (structured, machine-readable)
- TXT file (human-readable report)

## Sample Output
See: `samples/sample-output.txt`

## Usage
Run PowerShell **as Administrator** (recommended):

```powershell
.\triage.ps1
