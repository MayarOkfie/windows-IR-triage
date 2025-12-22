# triage.ps1
# Windows IR Triage Collector (MVP)
# Defensive use only

$global:LastScan = $null

function Invoke-Scan {
    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem

    # Basic system info
    $system = [ordered]@{
        Timestamp      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        ComputerName   = $env:COMPUTERNAME
        Domain         = $cs.Domain
        OS             = $os.Caption
        OS_Version     = $os.Version
        BuildNumber    = $os.BuildNumber
        LastBootUpTime = ([datetime]$os.LastBootUpTime).ToString("yyyy-MM-dd HH:mm:ss")
    }

    # Local users (names only for MVP)
    $users = @()
    try {
        $users = Get-LocalUser | Select-Object -ExpandProperty Name
    } catch {
        $users = @()
    }

    # Registry: Run / RunOnce (basic persistence)
    $autoruns = @()
    $keys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    )

    foreach ($k in $keys) {
        try {
            $p = Get-ItemProperty -Path $k -ErrorAction Stop
            $p.PSObject.Properties |
                Where-Object { $_.Name -notmatch '^PS' } |
                ForEach-Object {
                    $autoruns += [ordered]@{
                        Key   = $k
                        Name  = $_.Name
                        Value = $_.Value
                    }
                }
        } catch { }
    }

    $scan = [ordered]@{
        System   = $system
        Users    = $users
        Autoruns = $autoruns
    }

    $global:LastScan = $scan

    # Print results
    Write-Host "`n=== Scan Completed ===" -ForegroundColor Green
    Write-Host "Timestamp: $($scan.System.Timestamp)"
    Write-Host "Computer:  $($scan.System.ComputerName)"
    Write-Host "OS:        $($scan.System.OS) ($($scan.System.OS_Version))"
    Write-Host "Boot:      $($scan.System.LastBootUpTime)"

    if ($users.Count -gt 0) {
        Write-Host "`nUsers (count: $($users.Count)):" -ForegroundColor Cyan
        $users | ForEach-Object { Write-Host "- $_" }
    } else {
        Write-Host "`nUsers: Could not enumerate (permissions/module)." -ForegroundColor Yellow
    }

    Write-Host "`nAutoruns (Run/RunOnce) entries: $($autoruns.Count)" -ForegroundColor Cyan
    if ($autoruns.Count -gt 0) {
        $autoruns | Format-Table -AutoSize | Out-String | Write-Host
    } else {
        Write-Host "No entries found or access denied."
    }

    Write-Host ""
}

function Export-Scan {
    if (-not $global:LastScan) {
        Write-Host "No scan data to export. Run Scan first." -ForegroundColor Yellow
        return
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $jsonPath = "triage_$stamp.json"
    $txtPath  = "triage_$stamp.txt"
    $autorunsCsvPath = "triage_$stamp_autoruns.csv"
    $usersCsvPath    = "triage_$stamp_users.csv"


    # JSON export
    $global:LastScan | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath -Encoding UTF8

    # TXT export (simple)
    $lines = @()
    $lines += "Windows IR Triage Export"
    $lines += "Timestamp: $($global:LastScan.System.Timestamp)"
    $lines += "ComputerName: $($global:LastScan.System.ComputerName)"
    $lines += "OS: $($global:LastScan.System.OS)"
    $lines += "OS_Version: $($global:LastScan.System.OS_Version)"
    $lines += "LastBootUpTime: $($global:LastScan.System.LastBootUpTime)"
    $lines += ""
    $lines += "Users (count: $($global:LastScan.Users.Count))"
    $global:LastScan.Users | ForEach-Object { $lines += "- $_" }
    $lines += ""
    $lines += "Autoruns (count: $($global:LastScan.Autoruns.Count))"
    $global:LastScan.Autoruns | ForEach-Object { $lines += ($_.Key + " | " + $_.Name + " | " + $_.Value) }

    $lines | Set-Content -Path $txtPath -Encoding UTF8
    # CSV export (easy to review/filter)
    $global:LastScan.Autoruns | Export-Csv -Path $autorunsCsvPath -NoTypeInformation -Encoding UTF8
    $global:LastScan.Users    | ForEach-Object { [pscustomobject]@{ User = $_ } } |
    Export-Csv -Path $usersCsvPath -NoTypeInformation -Encoding UTF8


    Write-Host "Exported: $jsonPath" -ForegroundColor Green
    Write-Host "Exported: $txtPath" -ForegroundColor Green
    Write-Host "Exported: $autorunsCsvPath" -ForegroundColor Green
    Write-Host "Exported: $usersCsvPath" -ForegroundColor Green

}

function Show-Menu {
    Write-Host "============================"
    Write-Host " Windows IR Triage (MVP)"
    Write-Host "============================"
    Write-Host "1) Scan"
    Write-Host "2) Export"
    Write-Host "3) Exit"
}

while ($true) {
    Show-Menu
    $choice = Read-Host "Choose an option (1-3)"
    switch ($choice) {
        "1" { Invoke-Scan }
        "2" { Export-Scan }
        "3" { break }
        default { Write-Host "Invalid choice." -ForegroundColor Red }
    }
}
