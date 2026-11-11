param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { $failures.Add($Message) }
}

$requiredFiles = @(
    'CampusSchedule.xcodeproj\project.pbxproj',
    'CampusSchedule.xcodeproj\xcshareddata\xcschemes\CampusSchedule.xcscheme',
    'CampusSchedule\App\CampusScheduleApp.swift',
    'CampusSchedule\App\Info.plist',
    'CampusSchedule\Shared\Models\ScheduleModels.swift',
    'CampusSchedule\Shared\Services\ScheduleEngine.swift',
    'CampusSchedule\Shared\Services\ScheduleRepository.swift',
    'CampusSchedule\Resources\schedule.json',
    'CampusScheduleWidget\CampusScheduleWidgetBundle.swift',
    'CampusScheduleWidget\CampusScheduleWidget.swift',
    'CampusScheduleWidget\Info.plist',
    'CampusScheduleTests\ScheduleEngineTests.swift',
    'CampusScheduleTests\ScheduleRepositoryTests.swift',
    'scripts\verify-mac.sh',
    'README.md'
)

foreach ($relativePath in $requiredFiles) {
    Assert-True (Test-Path -LiteralPath (Join-Path $ProjectRoot $relativePath)) "Missing required file: $relativePath"
}

foreach ($plistRelativePath in @('CampusSchedule\App\Info.plist', 'CampusScheduleWidget\Info.plist')) {
    try {
        [xml](Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot $plistRelativePath)) | Out-Null
    } catch {
        $failures.Add("Invalid plist XML: $plistRelativePath")
    }
}

$widgetPlist = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'CampusScheduleWidget\Info.plist')
Assert-True ($widgetPlist.Contains('com.apple.widgetkit-extension')) 'Widget Info.plist is missing the WidgetKit extension point'
$appPlist = Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'CampusSchedule\App\Info.plist')
Assert-True ($appPlist.Contains('<string>campusschedule</string>')) 'App Info.plist is missing the widget deep-link URL scheme'

try {
    [xml](Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'CampusSchedule.xcodeproj\xcshareddata\xcschemes\CampusSchedule.xcscheme')) | Out-Null
} catch {
    $failures.Add('CampusSchedule.xcscheme is not valid XML')
}

try {
    Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'CampusSchedule\Resources\schedule.json') | ConvertFrom-Json | Out-Null
} catch {
    $failures.Add('schedule.json is not valid JSON')
}

$pbxPath = Join-Path $ProjectRoot 'CampusSchedule.xcodeproj\project.pbxproj'
$pbx = Get-Content -Raw -LiteralPath $pbxPath
$definedMatches = [regex]::Matches($pbx, '(?m)^\s*([A-F0-9]{24})\s+/\*.*?\*/\s*=\s*\{')
$definedIds = @($definedMatches | ForEach-Object { $_.Groups[1].Value })
$duplicateDefinitions = @($definedIds | Group-Object | Where-Object Count -gt 1)
Assert-True ($duplicateDefinitions.Count -eq 0) 'project.pbxproj contains duplicate object identifiers'

$allIds = @([regex]::Matches($pbx, '\b[A-F0-9]{24}\b') | ForEach-Object Value | Select-Object -Unique)
$undefinedIds = @($allIds | Where-Object { $_ -notin $definedIds })
Assert-True ($undefinedIds.Count -eq 0) "project.pbxproj references undefined IDs: $($undefinedIds -join ', ')"

Assert-True ($pbx.Contains('dstSubfolderSpec = 13;')) 'Widget embed phase is missing or has the wrong destination'
Assert-True ($pbx.Contains('CodeSignOnCopy')) 'Widget is not configured for code signing when embedded'
Assert-True ($pbx.Contains('CampusScheduleWidgetExtension.appex in Embed App Extensions')) 'Widget product is not embedded in the app'
Assert-True (-not $pbx.Contains('CampusSchedule/Resources/schedule.json')) 'Unexpected absolute-style resource path in pbxproj'
Assert-True ($pbx.Contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.CampusSchedule.widget;')) 'Widget bundle identifier must extend the app bundle identifier'

$appMainCount = ([regex]::Matches((Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'CampusSchedule\App\CampusScheduleApp.swift')), '@main')).Count
$widgetMainCount = ([regex]::Matches((Get-Content -Raw -LiteralPath (Join-Path $ProjectRoot 'CampusScheduleWidget\CampusScheduleWidgetBundle.swift')), '@main')).Count
Assert-True ($appMainCount -eq 1) 'App target must contain exactly one @main entry point'
Assert-True ($widgetMainCount -eq 1) 'Widget target must contain exactly one @main entry point'

$iconPath = Join-Path $ProjectRoot 'CampusSchedule\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png'
Assert-True (Test-Path -LiteralPath $iconPath) '1024×1024 app icon is missing'
if (Test-Path -LiteralPath $iconPath) {
    Add-Type -AssemblyName System.Drawing
    $icon = [System.Drawing.Image]::FromFile($iconPath)
    Assert-True ($icon.Width -eq 1024 -and $icon.Height -eq 1024) "App icon must be 1024×1024, got $($icon.Width)×$($icon.Height)"
    Assert-True (-not [System.Drawing.Image]::IsAlphaPixelFormat($icon.PixelFormat)) 'App icon must be RGB without an alpha channel for App Store validation'
    $icon.Dispose()
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Project contract passed: files, plists, Xcode references, widget embedding, and app icon verified."
