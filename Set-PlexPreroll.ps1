# ============================================================
#  Set-PlexPreroll.ps1
#  Automatically sets Plex pre-roll based on upcoming holidays
# ============================================================

# ============================================================
#  CONFIGURATION - Edit these values to match your setup
# ============================================================

# Your Plex token - get this from:
# Plex Web > Account > Troubleshooting > "Your user token"
$PlexToken = "YOURTOKEN"

# Your Plex server URL (usually localhost unless running remotely)
$PlexHost = "http://localhost:32400"

# Root folder where your holiday subfolders live
$PrerollRoot = "C:\XXXX\XXXX"

# Subfolder names for each holiday (must match your actual folder names)
$HolidayFolders = @{
    "NewYears"      = "New Years"
    "Valentines"    = "Valentines"
    "StPatricks"    = "St Patricks"
    "Easter"        = "Easter"
    "FourthOfJuly"  = "4th of July"
    "Halloween"     = "Halloween"
    "Thanksgiving"  = "Thanksgiving"
    "Christmas"     = "Christmas"
}

# Default pre-roll video used when no holiday is within 1 month
$DefaultPreroll = "C:\XXXXX\XXXXX\Plex Preroll.mp4"

# How many days before a holiday to start showing its pre-roll
$DaysBeforeHoliday = 20

# ============================================================
#  HOLIDAY DATE DEFINITIONS
#  Easter is calculated dynamically each year
# ============================================================

function Get-EasterDate($year) {
    # Anonymous Gregorian algorithm
    $a = $year % 19
    $b = [math]::Floor($year / 100)
    $c = $year % 100
    $d = [math]::Floor($b / 4)
    $e = $b % 4
    $f = [math]::Floor(($b + 8) / 25)
    $g = [math]::Floor(($b - $f + 1) / 3)
    $h = (19 * $a + $b - $d - $g + 15) % 30
    $i = [math]::Floor($c / 4)
    $k = $c % 4
    $l = (32 + 2 * $e + 2 * $i - $h - $k) % 7
    $m = [math]::Floor(($a + 11 * $h + 22 * $l) / 451)
    $month = [math]::Floor(($h + $l - 7 * $m + 114) / 31)
    $day = (($h + $l - 7 * $m + 114) % 31) + 1
    return Get-Date -Year $year -Month $month -Day $day
}

function Get-HolidayDates($year) {
    return @{
        "NewYears"     = Get-Date -Year $year -Month 1  -Day 1
        "Valentines"   = Get-Date -Year $year -Month 2  -Day 14
        "StPatricks"   = Get-Date -Year $year -Month 3  -Day 17
        "Easter"       = Get-EasterDate $year
        "FourthOfJuly" = Get-Date -Year $year -Month 7  -Day 4
        "Halloween"    = Get-Date -Year $year -Month 10 -Day 31
        "Thanksgiving" = Get-ThanksgivingDate $year
        "Christmas"    = Get-Date -Year $year -Month 12 -Day 25
    }
}

function Get-ThanksgivingDate($year) {
    # 4th Thursday of November
    $nov1 = Get-Date -Year $year -Month 11 -Day 1
    $daysUntilThursday = (4 - [int]$nov1.DayOfWeek + 7) % 7
    return $nov1.AddDays($daysUntilThursday + 21)
}

# ============================================================
#  CORE LOGIC
# ============================================================

function Get-UpcomingHoliday {
    $today = (Get-Date).Date
    $year  = $today.Year
    $bestKey  = $null
    $bestDiff = [int]::MaxValue

    # Check this year and next year to handle year boundaries
    foreach ($yr in @($year, $year + 1)) {
        $holidays = Get-HolidayDates $yr
        foreach ($key in $holidays.Keys) {
            $holidayDate = $holidays[$key].Date
            $daysUntil   = ($holidayDate - $today).Days

            # Only consider holidays within our window that haven't passed
            if ($daysUntil -ge 0 -and $daysUntil -le $DaysBeforeHoliday) {
                if ($daysUntil -lt $bestDiff) {
                    $bestDiff = $daysUntil
                    $bestKey  = $key
                }
            }
        }
    }

    return $bestKey
}

function Get-RandomVideoFromFolder($folderPath) {
    if (-not (Test-Path $folderPath)) {
        Write-Warning "Folder not found: $folderPath"
        return $null
    }

    $videos = Get-ChildItem -Path $folderPath -File | Where-Object { $_.Extension -in ".mp4",".mkv",".mov",".avi",".wmv",".m4v" }
    if ($videos.Count -eq 0) {
        Write-Warning "No video files found in: $folderPath"
        return $null
    }

    $selected = $videos | Get-Random
    return $selected.FullName
}

function Set-PlexPreroll($videoPath) {
    $encoded = [System.Uri]::EscapeDataString($videoPath)
    $url = "$PlexHost/:/prefs?CinemaTrailersPrerollID=$encoded&X-Plex-Token=$PlexToken"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Put
        Write-Host "SUCCESS: Pre-roll set to: $videoPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to set pre-roll: $_"
        return $false
    }
}

# ============================================================
#  MAIN EXECUTION
# ============================================================

Write-Host "=======================================" -ForegroundColor Cyan
Write-Host " Plex Holiday Pre-roll Scheduler" -ForegroundColor Cyan
Write-Host " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

$upcomingHoliday = Get-UpcomingHoliday

if ($upcomingHoliday) {
    $folderName   = $HolidayFolders[$upcomingHoliday]
    $folderPath   = Join-Path $PrerollRoot $folderName
    $selectedVideo = Get-RandomVideoFromFolder $folderPath

    Write-Host "Upcoming holiday detected: $upcomingHoliday" -ForegroundColor Yellow
    Write-Host "Folder: $folderPath" -ForegroundColor Yellow

    if ($selectedVideo) {
        Set-PlexPreroll $selectedVideo
    } else {
        Write-Warning "Could not find a video for $upcomingHoliday, falling back to default."
        Set-PlexPreroll $DefaultPreroll
    }
} else {
    Write-Host "No upcoming holiday within $DaysBeforeHoliday days. Using default pre-roll." -ForegroundColor Gray
    Set-PlexPreroll $DefaultPreroll
}

Write-Host "Done." -ForegroundColor Cyan
