param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$schedulePath = Join-Path $ProjectRoot 'CampusSchedule\Resources\schedule.json'

if (-not (Test-Path -LiteralPath $schedulePath)) {
    Write-Error "RED: production schedule is missing: $schedulePath"
}

$data = Get-Content -Raw -LiteralPath $schedulePath | ConvertFrom-Json
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-Equal {
    param([object]$Actual, [object]$Expected, [string]$Name)
    if ($Actual -ne $Expected) {
        $failures.Add("$Name — expected '$Expected', got '$Actual'")
    }
}

Assert-Equal $data.semester.startDate '2026-09-07' 'semester start'
Assert-Equal $data.semester.weekCount 17 'week count'
Assert-Equal $data.periods.Count 11 'period count'
Assert-Equal $data.courses.Count 15 'course occurrence count'

$periodNumbers = @($data.periods | ForEach-Object { [int]$_.number })
Assert-Equal ($periodNumbers -join ',') ((1..11) -join ',') 'period numbering'

$weekNine = @($data.courses | Where-Object { 9 -in $_.weeks })
Assert-Equal $weekNine.Count 2 'week 9 occurrence count'
Assert-Equal (@($weekNine | Select-Object -ExpandProperty title -Unique) -join ',') '程序设计基础（含实验）' 'week 9 title'

$psychology = @($data.courses | Where-Object { $_.id -eq 'mental-health-thu' })
Assert-Equal $psychology.Count 1 'mental health occurrence count'
Assert-Equal ($psychology[0].weeks -join ',') '13' 'mental health weeks'

$lab = @($data.courses | Where-Object { $_.id -eq 'programming-lab-tue' })
Assert-Equal $lab[0].location '园东区106栋201' 'lab location transcription'

function Get-CourseTitles {
    param([int]$Week, [int]$Weekday)
    @($data.courses |
        Where-Object { $Week -in $_.weeks -and [int]$_.weekday -eq $Weekday } |
        Sort-Object startPeriod |
        ForEach-Object title) -join '|'
}

Assert-Equal (Get-CourseTitles 1 1) '高等数学一（I）|大学英语|微观经济学' 'week 1 Monday mapping'
Assert-Equal (Get-CourseTitles 9 2) '程序设计基础（含实验）|程序设计基础（含实验）' 'week 9 Tuesday mapping'
Assert-Equal (Get-CourseTitles 10 1) '高等数学一（I）|大学英语|大学物理（工）上|微观经济学' 'week 10 Monday mapping'
Assert-Equal (Get-CourseTitles 13 4) '心理健康教育（上）|体育' 'week 13 Thursday mapping'
Assert-Equal (Get-CourseTitles 14 5) '会计学原理' 'week 14 Friday mapping'

$invalidWeeks = @($data.courses | Where-Object { @($_.weeks | Where-Object { $_ -lt 1 -or $_ -gt 17 }).Count -gt 0 })
Assert-Equal $invalidWeeks.Count 0 'out-of-range course weeks'

$unknownPeriods = @($data.courses | Where-Object {
    $_.startPeriod -notin $periodNumbers -or $_.endPeriod -notin $periodNumbers
})
Assert-Equal $unknownPeriods.Count 0 'courses referencing unknown periods'

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Schedule contract passed: 17 weeks, 11 periods, 15 course occurrences."
