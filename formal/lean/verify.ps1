param(
    [string]$LeanBin = '',
    [string]$CheckerExe = 'lean4checker'
)

$ErrorActionPreference = 'Stop'
function Get-InputSha256([string]$file) {
    (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLowerInvariant()
}
$taskPreviousPath = $env:PATH
$taskPreviousLocation = Get-Location
try {
    Set-Location -LiteralPath $PSScriptRoot
    if ($LeanBin) {
        if (-not (Test-Path -LiteralPath $LeanBin -PathType Container)) {
            throw 'LeanBin must name an existing toolchain bin directory.'
        }
        $env:PATH = (Resolve-Path -LiteralPath $LeanBin).Path + [IO.Path]::PathSeparator + $env:PATH
    }
    $lakeCommand = Get-Command lake -CommandType Application -ErrorAction Stop
    $leanCommand = Get-Command lean -CommandType Application -ErrorAction Stop
    $checkerCommand = Get-Command $CheckerExe -CommandType Application -ErrorAction Stop
    $leanVersion = & $leanCommand.Source --version
    if ($LASTEXITCODE -ne 0 -or ($leanVersion -notmatch '^Lean \(version 4\.24\.0,' -or
        $leanVersion -notmatch '797c613eb9b6d4ec95db23e3e00af9ac6657f24b')) {
        throw 'This proof package requires Lean 4.24.0; see lean-toolchain and README.md.'
    }
    $sources = @('Mard.lean','ProofCheck.lean','Audit.lean','lakefile.lean') +
        @(Get-ChildItem -LiteralPath Mard -Filter '*.lean' -File | Sort-Object Name |
            ForEach-Object { 'Mard/' + $_.Name })
    $inputs = $sources + @('lean-toolchain','lake-manifest.json','verify.ps1','reference/ANALYTICAL_NOTE.md')
    $hashes = [ordered]@{}
    foreach ($file in $inputs) { $hashes[$file] = Get-InputSha256 $file }
    foreach ($file in $sources) {
        $body = Get-Content -Raw -LiteralPath $file
        if ($body -match '\b(sorry|admit|native_decide)\b|(?m)^\s*(?:private\s+)?(?:axiom|unsafe)\b|set_option\s+.*(?:skipKernel|trustLevel)') {
            throw ('Unexpected proof construct in ' + $file)
        }
    }
    $runName = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    $runPath = Join-Path (Join-Path $PSScriptRoot '.verification-runs') $runName
    New-Item -ItemType Directory -Path $runPath -Force | Out-Null

    & $lakeCommand.Source build 2>&1 | Tee-Object -FilePath (Join-Path $runPath 'build.log')
    if ($LASTEXITCODE -ne 0) { throw 'Lean compilation failed.' }

    $auditOutput = @(& $lakeCommand.Source env lean -DwarningAsError=true Audit.lean 2>&1)
    if ($LASTEXITCODE -ne 0) { throw ($auditOutput -join "`n") }
    $auditOutput | Set-Content -LiteralPath (Join-Path $runPath 'axioms.log') -Encoding utf8
    $expected = @(Get-Content -LiteralPath Audit.lean | ForEach-Object {
        if ($_ -match '^#print axioms (\S+)$') { $Matches[1] }
    })
    $axiomChecks = [regex]::Matches(($auditOutput -join "`n"),
        "'([^']+)' (?:depends on axioms:\s*\[([^\]]*)\]|does not depend on any axioms)")
    $reported = @($axiomChecks | ForEach-Object { $_.Groups[1].Value })
    if ($expected.Count -ne 42 -or $reported.Count -ne 42 -or (Compare-Object $expected $reported)) {
        throw 'Expected the 42 named transitive axiom reports.'
    }
    $allowedAxioms = @('propext', 'Classical.choice', 'Quot.sound')
    foreach ($axiomCheck in $axiomChecks) {
        foreach ($name in $axiomCheck.Groups[2].Value.Split(',')) {
            if ($name.Trim() -and $name.Trim() -notin $allowedAxioms) {
                throw ('Unexpected axiom: ' + $name)
            }
        }
    }
    Write-Output 'PASS: 42 transitive axiom reports match the allowlist.'

    $timer = [Diagnostics.Stopwatch]::StartNew()
    & $lakeCommand.Source env $checkerCommand.Source --fresh -v ProofCheck 2>&1 |
        Tee-Object -FilePath (Join-Path $runPath 'kernel-replay.log')
    if ($LASTEXITCODE -ne 0) { throw 'Fresh kernel replay failed.' }
    $timer.Stop()
    foreach ($file in $inputs) {
        if ((Get-InputSha256 $file) -ne $hashes[$file]) { throw ('Verified input changed: ' + $file) }
    }
    [ordered]@{
        status = 'PASS'
        date_utc = [DateTime]::UtcNow.ToString('o')
        lean_version = ($leanVersion -join "`n")
        build_exit_code = 0
        scope = 'Analytical note sections 1 through 4, including the two-observation Gaussian model'
        warnings_as_errors = $true
        axiom_declarations = $reported.Count
        sampling_declarations = @($reported | Where-Object { $_ -like 'Mard.Sampling.*' }).Count
        forbidden_source_construct_matches = 0
        allowed_axioms = $allowedAxioms
        fresh_kernel_replay_exit_code = 0
        fresh_kernel_replay_seconds = $timer.Elapsed.TotalSeconds
        target = 'ProofCheck'
        checker_sha256 = Get-InputSha256 $checkerCommand.Source
        inputs_unchanged_during_verification = $true
        input_sha256 = $hashes
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runPath 'RESULT.json') -Encoding utf8
    Write-Output ('PASS: build, axiom audit and fresh kernel replay. Logs: ' + $runPath)
} finally {
    $env:PATH = $taskPreviousPath
    Set-Location -LiteralPath $taskPreviousLocation.Path
}
