param(
    [string]$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    [string]$OutDir = "$PSScriptRoot\..\responsive_fix",
    [string]$Package = "com.example.logisticsmobile",
    [int]$LaunchWaitSeconds = 25
)

$ErrorActionPreference = "Stop"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Wait-App([int]$Seconds = 3) {
    Start-Sleep -Seconds $Seconds
}

function Tap-Tab([int]$Index, [int]$Width, [int]$Height) {
    $x = [int]($Width * (($Index + 0.5) / 5))
    $y = $Height - 60
    cmd /c "`"$Adb`" shell input tap $x $y >nul 2>nul"
}

function Capture-Screen([string]$File) {
    $remote = "/sdcard/cap.png"
    cmd /c "`"$Adb`" shell screencap -p $remote >nul 2>nul"
    cmd /c "`"$Adb`" pull $remote `"$File`" >nul 2>nul"
    Write-Host "Captured $File"
}

$sizes = @(
    @{ Label = "360x640"; W = 360; H = 640 },
    @{ Label = "393x852"; W = 393; H = 852 },
    @{ Label = "412x915"; W = 412; H = 915 }
)

$tabs = @(
    @{ Name = "dashboard"; Index = 0 },
    @{ Name = "inventory"; Index = 1 },
    @{ Name = "orders"; Index = 2 },
    @{ Name = "notifications"; Index = 3 },
    @{ Name = "profile"; Index = 4 }
)

foreach ($size in $sizes) {
    cmd /c "`"$Adb`" shell wm size $($size.Label) >nul 2>nul"
    Wait-App 1
    cmd /c "`"$Adb`" shell am force-stop $Package >nul 2>nul"
    cmd /c "`"$Adb`" shell am start -n `"$Package/.MainActivity`" >nul 2>nul"
    Wait-App $LaunchWaitSeconds

    foreach ($tab in $tabs) {
        Tap-Tab $tab.Index $size.W $size.H
        Wait-App 4
        $file = Join-Path $OutDir "$($size.Label)_$($tab.Name).png"
        Capture-Screen $file
    }
}

cmd /c "`"$Adb`" shell wm size reset >nul 2>nul"
Write-Host "Done. Screenshots in $OutDir"
