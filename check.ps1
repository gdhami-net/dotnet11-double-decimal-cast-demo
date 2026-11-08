#!/usr/bin/env pwsh
# Builds the one program four ways and asserts every number the post and the README quote.
#
#   pwsh -NoProfile -File check.ps1
#
# "dotnet" on PATH has to offer SDK 10.0.201 or later in the 10.0 band and a .NET 10 runtime.
# If the .NET 11 SDK sits in a folder of its own, set DOTNET11 to its dotnet executable.

$ErrorActionPreference = 'Stop'
$env:DOTNET_NOLOGO = '1'
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'

$root = $PSScriptRoot
$artifacts = Join-Path $root 'artifacts'
$dotnet10 = 'dotnet'
$dotnet11 = if ($env:DOTNET11) { $env:DOTNET11 } else { 'dotnet' }
$script:failures = 0
$script:passes = 0

$Long = '1.2299999999999999822364316060'
$LongFloat = '1.230000019073486328125'
$Invariant = [Globalization.CultureInfo]::InvariantCulture

function Report([bool]$ok, [string]$name, [string]$shown) {
    if ($ok) { $script:passes++; Write-Output "PASS  $name  =>  $shown" }
    else { $script:failures++; Write-Output "FAIL  $name  =>  $shown" }
}

function Same([string]$name, [string]$actual, [string]$expected) {
    $shown = if ($actual -ceq $expected) { $actual } else { "got '$actual', expected '$expected'" }
    Report ($actual -ceq $expected) $name $shown
}

function Starts([string]$name, [string]$actual, [string]$prefix) {
    Report $actual.StartsWith($prefix, [StringComparison]::Ordinal) $name $actual
}

function With-Dotnet11([scriptblock]$body) {
    if (-not $env:DOTNET11) { return & $body }
    $savedPath = $env:PATH
    $savedRoot = $env:DOTNET_ROOT
    $folder = Split-Path $env:DOTNET11
    $env:PATH = $folder + [IO.Path]::PathSeparator + $savedPath
    $env:DOTNET_ROOT = $folder
    try { & $body }
    finally { $env:PATH = $savedPath; $env:DOTNET_ROOT = $savedRoot }
}

function Build([string]$name, [string]$dotnet, [string]$sdkFolder, [string]$tfm) {
    Push-Location (Join-Path $root $sdkFolder)
    try {
        $sdk = & $dotnet --version
        $log = & $dotnet build (Join-Path $root 'src/CastDemo.csproj') -c Release "-p:Tfm=$tfm" `
            --artifacts-path (Join-Path $artifacts $name) -v q --nologo 2>&1
        if ($LASTEXITCODE -ne 0) { $log | Write-Output; throw "build $name failed" }
        return "$sdk"
    }
    finally { Pop-Location }
}

function Dll([string]$name) { Join-Path $artifacts "$name/bin/CastDemo/release/CastDemo.dll" }

function Read-Values([string[]]$lines) {
    $values = @{}
    foreach ($line in $lines) {
        if ($line -match '^(.+?)\s{2,}(\S.*)$') { $values[$Matches[1]] = $Matches[2] }
    }
    return $values
}

function Run-Program([string]$dotnet, [string]$dll) {
    $lines = & $dotnet $dll
    if ($LASTEXITCODE -ne 0) { throw "run of $dll failed" }
    return ,(Read-Values $lines)
}

# ---- four builds, four runs ----------------------------------------------------------------

$sdkA = Build 'sdk10-net10' $dotnet10 'sdk10' 'net10.0'
$sdkB = With-Dotnet11 { Build 'sdk11-net11' $dotnet11 'sdk11' 'net11.0' }
$sdkC = With-Dotnet11 { Build 'sdk11-net10' $dotnet11 'sdk11' 'net10.0' }

$A = Run-Program $dotnet10 (Dll 'sdk10-net10')
$B = With-Dotnet11 { Run-Program $dotnet11 (Dll 'sdk11-net11') }
$C = Run-Program $dotnet10 (Dll 'sdk11-net10')

$env:DOTNET_ROLL_FORWARD = 'LatestMajor'
$env:DOTNET_ROLL_FORWARD_TO_PRERELEASE = '1'
try { $D = With-Dotnet11 { Run-Program $dotnet11 (Dll 'sdk10-net10') } }
finally { $env:DOTNET_ROLL_FORWARD = $null; $env:DOTNET_ROLL_FORWARD_TO_PRERELEASE = $null }

Write-Output '--- which build is which'
Starts 'SDK of the .NET 10 build' $sdkA '10.0.'
Starts 'SDK of the .NET 11 build' $sdkB '11.0.'
Starts 'SDK of the net10.0 build made by the .NET 11 SDK' $sdkC '11.0.'
Same 'that build targets .NET 10' $C['built for'] '.NETCoreApp,Version=v10.0'
Starts 'and runs on .NET 10' $C['runtime'] '.NET 10.'
Starts 'the .NET 10 build runs on .NET 10' $A['runtime'] '.NET 10.'
Starts 'the .NET 11 build runs on .NET 11' $B['runtime'] '.NET 11.'
Same 'the rolled-forward build still targets .NET 10' $D['built for'] '.NETCoreApp,Version=v10.0'
Starts 'and runs on .NET 11' $D['runtime'] '.NET 11.'

Write-Output '--- the cast at run time'
Same '.NET 10: converted' $A['converted'] '1.23'
Same '.NET 11: converted' $B['converted'] $Long
Same 'every digit the double holds' $B['every digit of the double'] '1.229999999999999982236431605997495353221893310546875'
Same '.NET 11: converted, G29 (the form on the docs page)' $B['converted, shown with G29'] '1.229999999999999982236431606'
Same '.NET 10: 0.1 + 0.2' $A['sum'] '0.3'
Same '.NET 11: 0.1 + 0.2' $B['sum'] '0.3000000000000000166533453694'
Same '.NET 10: equals 0.3m' $A['sum == 0.3m'] 'True'
Same '.NET 11: equals 0.3m' $B['sum == 0.3m'] 'False'
Same '.NET 11: equals 1.23m' $B['converted == 1.23m'] 'False'
Same '.NET 10: F2 hides nothing to hide' $A['converted, shown with F2'] '1.23'
Same '.NET 11: F2 still prints 1.23' $B['converted, shown with F2'] '1.23'

Write-Output '--- const against run time'
foreach ($row in @(
        @('.NET 10 SDK, net10.0', $A, '1.23', '1.23', 'True', 'True'),
        @('.NET 11 SDK, net11.0', $B, $Long, $Long, 'True', 'False'),
        @('.NET 11 SDK, net10.0', $C, $Long, '1.23', 'False', 'False'),
        @('.NET 10 SDK, net10.0, rolled forward to .NET 11', $D, '1.23', $Long, 'False', 'True'))) {
    $name, $values, $folded, $runtime, $same, $expr = $row
    Same "${name}: const" $values['const'] $folded
    Same "${name}: literal cast" $values['literal cast'] $folded
    Same "${name}: cast of a variable" $values['cast of a variable'] $runtime
    Same "${name}: same value" $values['same value'] $same
    Same "${name}: const 0.1 + 0.2 == 0.3m" $values['const 0.1 + 0.2 == 0.3m'] $expr
}

Write-Output '--- every form changes'
foreach ($form in 'cast', 'nullable cast', 'capitalised cast', 'full name cast', 'Convert', 'Convert as a method group',
    'constructor', 'CreateChecked', 'CreateTruncating', 'CreateSaturating', 'IConvertible', 'target-typed new',
    'generic math', 'alias cast', 'ChangeType') {
    Same ".NET 10: $form" $A[$form] '1.23'
    Same ".NET 11: $form" $B[$form] $Long
}
foreach ($form in 'cast of float', 'Convert of float', 'constructor of float', 'CreateChecked of float',
    'CreateTruncating of float', 'CreateSaturating of float') {
    Same ".NET 10: $form" $A[$form] '1.23'
    Same ".NET 11: $form" $B[$form] $LongFloat
}
foreach ($form in 'cast of int', 'cast of long', 'constructor of int', 'Convert of int', 'Convert of string') {
    Same "unchanged: $form" $A[$form] $B[$form]
}

Write-Output '--- the search'
$script = Get-Content (Join-Path $root 'find-casts.sh') -Raw
$patterns = [regex]::Matches($script, "-e '([^']+)'") | ForEach-Object { $_.Groups[1].Value }
Same 'patterns in find-casts.sh' $patterns.Count 4
$grepArgs = @('-C', $root, 'grep', '--no-index', '-nE') + ($patterns | ForEach-Object { '-e', $_ }) + @('--', 'src/Forms.cs')
$hits = & git @grepArgs | ForEach-Object { [int]($_ -split ':')[1] }
$source = Get-Content (Join-Path $root 'src/Forms.cs')
$wrong = @()
$found = 0
$missed = 0
for ($i = 0; $i -lt $source.Count; $i++) {
    $isHit = $hits -contains ($i + 1)
    if ($source[$i] -match '// FOUND$') { $found++; if (-not $isHit) { $wrong += $i + 1 } }
    elseif ($source[$i] -match '// MISSED$') { $missed++; if ($isHit) { $wrong += $i + 1 } }
    elseif ($isHit) { $wrong += $i + 1 }
}
Same 'lines where the search and the comments disagree' ($wrong -join ',') ''
Starts 'forms the search finds' "$found" '2'
Starts 'forms it misses' "$missed" '3'

Write-Output '--- getting a stable number'
Same '2.675 rounded after the cast, .NET 10' $A['2.675: round after the cast'] '2.68'
Same '2.675 rounded after the cast, .NET 11' $B['2.675: round after the cast'] '2.67'
Same '1.23 rounded before the cast, .NET 11' $B['1.23: round before the cast'] $Long
Same '19.99 rounded before the cast, .NET 11' $B['19.99: round before the cast'] '19.989999999999998436805981328'
foreach ($value in '1.23', '2.675', '1.005', '19.99', '19.9') {
    Same "${value}: G15 and parse is the same on both" $A["${value}: G15 and parse"] $B["${value}: G15 and parse"]
    Same "${value}: G15, parse, round is the same on both" $A["${value}: G15, parse, then round"] $B["${value}: G15, parse, then round"]
}
Same '2.675 through G15 then rounded, .NET 11' $B['2.675: G15, parse, then round'] '2.68'
Same '1.23 rounded after the cast, .NET 11' $B['1.23: round after the cast'] '1.23'
Same '19.99 rounded after the cast, .NET 11' $B['19.99: round after the cast'] '19.99'
Same '19.9 rounded after the cast, .NET 10' $A['19.9: round after the cast'] '19.9'
Same '19.9 rounded after the cast, .NET 11 (same value, a trailing zero)' $B['19.9: round after the cast'] '19.90'

Write-Output '--- extras for the README'
Same 'Math.Round(655.925), .NET 10' $A['Math.Round(655.925, 2, AwayFromZero)'] '655.93'
Same 'Math.Round(655.925), .NET 11' $B['Math.Round(655.925, 2, AwayFromZero)'] '655.92'
Same 'decimal to double, .NET 10' $A['(double) of 10000000000000.099609375m'] '10000000000000.09765625'
Same 'decimal to double, .NET 11' $B['(double) of 10000000000000.099609375m'] '10000000000000.099609375'
Same 'an exact tie at the 15th digit, cast, .NET 10' $A['tie: cast only'] '1000000000000.12'
Same 'an exact tie at the 15th digit, cast, .NET 11' $B['tie: cast only'] '1000000000000.125'
Same 'an exact tie, G15 and parse, .NET 11' $B['tie: G15 and parse'] '1000000000000.12'
Same '14.1f, cast, .NET 11' $B['14.1f: cast only'] '14.1000003814697265625'
Same '14.1f, G7 and parse, .NET 11' $B['14.1f: G7 and parse'] '14.1'

Write-Output '--- 150,000 doubles, compared value by value'
$fileA = Join-Path $artifacts 'sweep-net10.tsv'
$fileB = Join-Path $artifacts 'sweep-net11.tsv'
& $dotnet10 (Dll 'sdk10-net10') --dump $fileA
With-Dotnet11 { & $dotnet11 (Dll 'sdk11-net11') --dump $fileB }
$rowsA = [IO.File]::ReadAllLines($fileA)
$rowsB = [IO.File]::ReadAllLines($fileB)
Same 'rows on each side' "$($rowsA.Count)/$($rowsB.Count)" '150000/150000'

$stats = @{}
foreach ($set in 'cents', 'thousandths', 'wide') {
    $stats[$set] = @{ count = 0; cast = 0; roundValue = 0; roundText = 0; g15 = 0; g15Round = 0; g15VsOldCast = 0 }
}
for ($i = 0; $i -lt $rowsA.Count; $i++) {
    $a = $rowsA[$i].Split("`t")
    $b = $rowsB[$i].Split("`t")
    if ($a[1] -cne $b[1]) { throw "the inputs differ on row $i" }
    $s = $stats[$a[0]]
    $s.count++
    if ([decimal]::Parse($a[2], $Invariant) -ne [decimal]::Parse($b[2], $Invariant)) { $s.cast++ }
    if ($a[3] -cne $b[3]) { $s.roundText++ }
    if ([decimal]::Parse($a[3], $Invariant) -ne [decimal]::Parse($b[3], $Invariant)) { $s.roundValue++ }
    if ($a[4] -cne $b[4]) { $s.g15++ }
    if ($a[5] -cne $b[5]) { $s.g15Round++ }
    if ([decimal]::Parse($b[4], $Invariant) -ne [decimal]::Parse($a[2], $Invariant)) { $s.g15VsOldCast++ }
}
foreach ($set in 'cents', 'thousandths', 'wide') {
    $s = $stats[$set]
    Write-Output ("      {0,-12} values {1}, cast differs {2}, rounded after the cast differs in value {3} (in text {4}), G15 differs {5}, G15 then rounded differs {6}, G15 on .NET 11 against the old cast differs {7}" -f `
            $set, $s.count, $s.cast, $s.roundValue, $s.roundText, $s.g15, $s.g15Round, $s.g15VsOldCast)
    Report ($s.g15 -eq 0) "${set}: G15 and parse matches across runtimes" "$($s.g15) differences"
    Report ($s.g15Round -eq 0) "${set}: G15, parse, round matches across runtimes" "$($s.g15Round) differences"
    Report ($s.cast -gt 0) "${set}: the plain cast changes" "$($s.cast) of $($s.count)"
}
Report ($stats.cents.roundValue -eq 0) 'cents: rounding after the cast gives the same value on both' "$($stats.cents.roundValue) differences"
Report ($stats.thousandths.roundValue -gt 0) 'thousandths: rounding after the cast does flip at a half' "$($stats.thousandths.roundValue) of $($stats.thousandths.count)"
Report ($stats.cents.g15VsOldCast -eq 0) 'cents: G15 and parse reproduces the old cast' "$($stats.cents.g15VsOldCast) differences"
Report ($stats.thousandths.g15VsOldCast -eq 0) 'thousandths: G15 and parse reproduces the old cast' "$($stats.thousandths.g15VsOldCast) differences"
Report ($stats.wide.g15VsOldCast -gt 0) 'wide: G15 and parse is not always the old cast on long doubles' "$($stats.wide.g15VsOldCast) of $($stats.wide.count)"

Write-Output ''
if ($script:failures -eq 0) { Write-Output "ALL CHECKS PASSED ($script:passes)"; exit 0 }
Write-Output "$script:failures CHECK(S) FAILED, $script:passes passed"
exit 1
