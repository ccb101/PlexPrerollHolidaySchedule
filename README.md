# 🎬 Plex Holiday Pre-roll Scheduler

A PowerShell script that automatically updates your Plex server's pre-roll video based on upcoming holidays and the current season. Set it and forget it — your Plex server will always have a themed pre-roll playing without any manual effort.

---

## ✨ Features

- 🎃 **Holiday-aware** — automatically switches to a themed pre-roll up to 30 days before a holiday
- 🍂 **Seasonal fallback** — plays a seasonal pre-roll when no holiday is approaching
- 🎲 **Random selection** — if a folder contains multiple videos, one is picked at random each day
- 🔁 **Daily automation** — runs automatically via Windows Task Scheduler
- 🛡️ **Graceful fallback** — falls back to a default pre-roll if no holiday or seasonal video is found

---

## 📅 Supported Holidays

| Holiday | Starts |
|---|---|
| New Year's Day | December 2nd |
| Valentine's Day | January 15th |
| St. Patrick's Day | February 15th |
| Easter | ~30 days before (calculated dynamically) |
| 4th of July | June 4th |
| Halloween | October 1st |
| Thanksgiving | ~30 days before (calculated dynamically) |
| Christmas | November 25th |

> When two holidays overlap, the **closest** one takes priority.

---

## 🍃 Seasons

Used automatically when no holiday is within 30 days.

| Season | Months |
|---|---|
| Winter | December, January, February |
| Spring | March, April, May |
| Summer | June, July, August |
| Fall | September, October, November |

---

## 📁 Folder Structure

Set up your pre-roll folder like this:

```
C:\Usenet\Preroll\
│   Plex Preroll.mp4          ← default fallback
│
├───New Years\
├───Valentines\
├───St Patricks\
├───Easter\
├───4th of July\
├───Halloween\
├───Thanksgiving\
├───Christmas\
│
├───Winter\
├───Spring\
├───Summer\
└───Fall\
```

You can place **multiple videos** in any folder and the script will pick one at random each day.

**Supported video formats:** `.mp4`, `.mkv`, `.mov`, `.avi`, `.wmv`, `.m4v`

---

## ⚙️ Requirements

- Windows PC running Plex Media Server
- PowerShell 5.1 or later
- Active **Plex Pass** subscription (required for pre-roll functionality)
- Plex must be accessible at `http://127.0.0.1:32400` (default)

---

## 🚀 Setup

### Step 1 — Get Your Plex Token

1. Open Plex Web and play any video
2. Click the **three dots (...)** → **Get Info** → **View XML**
3. Copy the value of `X-Plex-Token=` from the URL in the new tab

### Step 2 — Configure the Script

Open `Set-PlexPreroll.ps1` and edit the configuration section at the top:

```powershell
$PlexToken    = "YOUR_PLEX_TOKEN_HERE"   # Paste your Plex token here
$PlexHost     = "http://127.0.0.1:32400" # Change if Plex runs on a different host/port
$PrerollRoot  = "C:\Usenet\Preroll"      # Root folder containing all your pre-roll subfolders
$DefaultPreroll = "C:\Usenet\Preroll\Plex Preroll.mp4"  # Fallback video
$DaysBeforeHoliday = 30                  # How many days before a holiday to switch pre-rolls
```

If your folders are named differently, update the `$HolidayFolders` or `$SeasonFolders` sections to match your exact folder names.

### Step 3 — Save the Script

Save `Set-PlexPreroll.ps1` to:
```
C:\Usenet\Preroll\Scripts\Set-PlexPreroll.ps1
```

### Step 4 — Register the Scheduled Task

1. Right-click **PowerShell** → **Run as Administrator**
2. Run:
```powershell
& "C:\Usenet\Preroll\Scripts\Register-PlexPrerollTask.ps1"
```
3. The task will be created to run daily at **3:00 AM**
4. You will be asked if you want to run it immediately to test

### Step 5 — Test It

Run the script manually at any time to verify it is working:
```powershell
& "C:\Usenet\Preroll\Scripts\Set-PlexPreroll.ps1"
```

You should see output like:
```
=======================================
 Plex Holiday Pre-roll Scheduler
 2026-06-29 17:50:57
=======================================
Upcoming holiday detected: FourthOfJuly
Folder: C:\Usenet\Preroll\4th of July
SUCCESS: Pre-roll set to: C:\Usenet\Preroll\4th of July\independence.mp4
Done.
```

---

## 🔧 Customization

**Change how early holiday pre-rolls start:**
```powershell
$DaysBeforeHoliday = 14  # Switch to holiday pre-roll 2 weeks before
```

**Add a new holiday:**
1. Create a new subfolder under your `$PrerollRoot`
2. Add an entry to `$HolidayFolders` in the script
3. Add the holiday date to the `Get-HolidayDates` function

**Change the scheduled run time:**
Open Task Scheduler → find **Plex Holiday Pre-roll Updater** → edit the trigger time.

---

## 🗂️ Files

| File | Description |
|---|---|
| `Set-PlexPreroll.ps1` | Main script that detects the holiday/season and updates Plex |
| `Register-PlexPrerollTask.ps1` | One-time setup script that registers the Windows scheduled task |

---

## ❗ Troubleshooting

**Pre-roll is not playing on my device**
Pre-roll only works on native Plex apps such as Roku, Apple TV, Android TV, Fire TV, and Plex HTPC. It does not work in a web browser or on iOS/Android mobile apps.

**401 Unauthorized error**
Your Plex token is incorrect or has expired. Re-fetch it from Plex Web and update `$PlexToken` in the script.

**No video files found in folder**
Make sure your video files use a supported extension (`.mp4`, `.mkv`, `.mov`, `.avi`, `.wmv`, `.m4v`) and are placed directly in the holiday/season folder, not in a subfolder within it.

**Task is not running automatically**
Open Task Scheduler and confirm the **Plex Holiday Pre-roll Updater** task exists and is enabled. Make sure the Plex Media Server is running at the scheduled time.

---

## 📄 License

MIT License — free to use, modify, and share.
