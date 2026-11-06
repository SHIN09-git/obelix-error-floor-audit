param(
    [string]$LeanBin = '',
    [string]$CheckerExe = 'lean4checker'
)

$ErrorActionPreference = 'Stop'
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
    if ($LASTEXITCODE -ne 0 -or $leanVersion -notmatch '^Lean \(version 4\.24\.0,') {
        throw 'This proof package requires Lean 4.24.0; see lean-toolchain and README.md.'
    }
    $runName = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    $runPath = Join-Path (Join-Path $PSScriptRoot '.verification-runs') $runName
    New-Item -ItemType Directory -Path $runPath -Force | Out-Null

    & $lakeCommand.Source build 2>&1 | Tee-Object -FilePath (Join-Path $runPath 'build.log')
    if ($LASTEXITCODE -ne 0) { throw 'Lean compilation failed.' }

    $auditOutput = @(& $lakeCommand.Source env lean -DwarningAsError=true Audit.lean 2>&1)
    if ($LASTEXITCODE -ne 0) { throw ($auditOutput -join "`n") }
    $auditOutput | Set-Content -LiteralPath (Join-Path $runPath 'axioms.log') -Encoding utf8
    $axiomChecks = [regex]::Matches(($auditOutput -join "`n"), 'depends on axioms:\s*\[([^\]]*)\]')
    if ($axiomChecks.Count -ne 19) { throw 'Expected 19 transitive axiom reports.' }
    $allowedAxioms = @('propext', 'Classical.choice', 'Quot.sound')
    foreach ($axiomCheck in $axiomChecks) {
        foreach ($name in $axiomCheck.Groups[1].Value.Split(',')) {
            if ($name.Trim() -and $name.Trim() -notin $allowedAxioms) {
                throw ('Unexpected axiom: ' + $name)
            }
        }
    }
    Write-Output 'PASS: 19 transitive axiom reports match the allowlist.'

    $timer = [Diagnostics.Stopwatch]::StartNew()
    & $lakeCommand.Source env $checkerCommand.Source --fresh -v ProofCheck 2>&1 |
        Tee-Object -FilePath (Join-Path $runPath 'kernel-replay.log')
    if ($LASTEXITCODE -ne 0) { throw 'Fresh kernel replay failed.' }
    $timer.Stop()
    [ordered]@{
        status = 'PASS'
        date_utc = [DateTime]::UtcNow.ToString('o')
        lean_version = ($leanVersion -join "`n")
        build_exit_code = 0
        axiom_declarations = 19
        allowed_axioms = $allowedAxioms
        fresh_kernel_replay_exit_code = 0
        fresh_kernel_replay_seconds = $timer.Elapsed.TotalSeconds
        target = 'ProofCheck'
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runPath 'RESULT.json') -Encoding utf8
    Write-Output ('PASS: build, axiom audit and fresh kernel replay. Logs: ' + $runPath)
} finally {
    $env:PATH = $taskPreviousPath
    Set-Location -LiteralPath $taskPreviousLocation.Path
}
