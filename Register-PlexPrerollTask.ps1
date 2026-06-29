# ============================================================
#  Register-PlexPrerollTask.ps1
#  Run this ONCE as Administrator to set up the scheduled task
# ============================================================

# ============================================================
#  CONFIGURATION - Edit to match your setup
# ============================================================

# Full path to the Set-PlexPreroll.ps1 script
$ScriptPath = "C:\XXXXX\XXXXX\Scripts\Set-PlexPreroll.ps1"

# Task name as it will appear in Task Scheduler
$TaskName = "Plex Holiday Pre-roll Updater"

# What time of day should the script run?
$RunAtTime = "03:00"   # 3:00 AM daily

# ============================================================
#  TASK REGISTRATION
# ============================================================

# Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Error "Please run this script as Administrator."
    exit 1
}

Write-Host "Registering Plex Pre-roll Scheduled Task..." -ForegroundColor Cyan

# Action: run PowerShell with the script
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

# Trigger: run daily at the specified time
$trigger = New-ScheduledTaskTrigger -Daily -At $RunAtTime

# Settings
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable

# Run as SYSTEM so it works even when no user is logged in
$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

# Register the task (replace if it already exists)
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Automatically updates Plex pre-roll video based on upcoming holidays." `
    -Force

Write-Host ""
Write-Host "Task registered successfully!" -ForegroundColor Green
Write-Host "Name   : $TaskName" -ForegroundColor Green
Write-Host "Runs at: $RunAtTime daily" -ForegroundColor Green
Write-Host "Script : $ScriptPath" -ForegroundColor Green
Write-Host ""
Write-Host "You can view/edit it in Task Scheduler under 'Task Scheduler Library'." -ForegroundColor Gray
Write-Host ""

# Ask if user wants to run the task immediately to test it
$runNow = Read-Host "Would you like to run the task now to test it? (y/n)"
if ($runNow -eq "y" -or $runNow -eq "Y") {
    Start-ScheduledTask -TaskName $TaskName
    Write-Host "Task started! Check your Plex server settings to confirm the pre-roll was updated." -ForegroundColor Cyan
}
