# ============================================================
#  Set-PlexPreroll.ps1
#  Automatically sets Plex pre-roll based on upcoming holidays
#  and current season when no holiday is within range
# ============================================================

# ============================================================
#  CONFIGURATION - Edit these values to match your setup
# ============================================================

# Your Plex token - get this from:
# Plex Web > Account > Troubleshooting > "Your user token"
$PlexToken = "YOUR_PLEX_TOKEN_HERE"

# Your Plex server URL (usually localhost unless running remotely)
$PlexHost = "http://127.0.0.1:32400"

# Root folder where your holiday and season subfolders live
$PrerollRoot = "C:\XXXX\XXXXXX"

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

# Subfolder names for each season (must match your actual folder names)
# Used when no holiday is within range
$SeasonFolders = @{
    "Winter" = "Winter"
    "Spring" = "Spring"
    "Summer" = "Summer"
    "Fall"   = "Fall"
}

# Default pre-roll used only if no holiday AND no season video is found
$DefaultPreroll = "C:\XXXXXXX\XXXXXXX\Plex Preroll.mp4"

# How many days before a holiday to start showing its pre-roll
$DaysBeforeHoliday = 30

# ============================================================
#  SEASON DETECTION
#  Spring: Mar 1 - May 31
#  Summer: Jun 1 - Aug 31
#  Fall:   Sep 1 - Nov 30
#  Winter: Dec 1 - Feb 28/29
# ============================================================

function Get-CurrentSeason {
    $month = (Get-Date).Month
    switch ($month) {
        { $_ -in 3, 4, 5 }        { return "Spring" }
        { $_ -in 6, 7, 8 }        { return "Summer" }
        { $_ -in 9, 10, 11 }      { return "Fall"   }
        { $_ -in 12, 1, 2 }       { return "Winter" }
    }
}

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

function Get-ThanksgivingDate($year) {
    # 4th Thursday of November
    $nov1 = Get-Date -Year $year -Month 11 -Day 1
    $daysUntilThursday = (4 - [int]$nov1.DayOfWeek + 7) % 7
    return $nov1.AddDays($daysUntilThursday + 21)
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
    $url  = "$PlexHost/:/prefs"
    $body = "CinemaTrailersPrerollID=$([System.Uri]::EscapeDataString($videoPath))"

    try {
        $response = Invoke-RestMethod `
            -Uri $url `
            -Method Put `
            -Body $body `
            -ContentType "application/x-www-form-urlencoded" `
            -Headers @{
                "X-Plex-Token"             = $PlexToken
                "X-Plex-Client-Identifier" = "PlexPrerollScript"
                "X-Plex-Product"           = "Plex Preroll Scheduler"
            }
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
    # --- Holiday mode ---
    $folderName    = $HolidayFolders[$upcomingHoliday]
    $folderPath    = Join-Path $PrerollRoot $folderName
    $selectedVideo = Get-RandomVideoFromFolder $folderPath

    Write-Host "Upcoming holiday detected: $upcomingHoliday" -ForegroundColor Yellow
    Write-Host "Folder: $folderPath" -ForegroundColor Yellow

    if ($selectedVideo) {
        Set-PlexPreroll $selectedVideo
    } else {
        Write-Warning "Could not find a video for $upcomingHoliday, falling back to season."
        # Fall through to seasonal logic below
        $upcomingHoliday = $null
    }
}

if (-not $upcomingHoliday) {
    # --- Seasonal mode ---
    $currentSeason = Get-CurrentSeason
    $seasonFolder  = $SeasonFolders[$currentSeason]
    $seasonPath    = Join-Path $PrerollRoot $seasonFolder
    $selectedVideo = Get-RandomVideoFromFolder $seasonPath

    if ($selectedVideo) {
        Write-Host "No upcoming holiday. Using season: $currentSeason" -ForegroundColor Magenta
        Write-Host "Folder: $seasonPath" -ForegroundColor Magenta
        Set-PlexPreroll $selectedVideo
    } else {
        # --- Final fallback to default ---
        Write-Warning "No season video found either. Falling back to default pre-roll."
        Set-PlexPreroll $DefaultPreroll
    }
}

Write-Host "Done." -ForegroundColor Cyan
