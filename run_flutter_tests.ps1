# run_flutter_tests.ps1
# Runs Flutter tests, preserves the full JSON event stream, and writes a readable
# summary of failed tests including error messages and stack traces where available.

$ErrorActionPreference = "Continue"

$projectRoot = Get-Location
$reportDir = Join-Path $projectRoot "test-reports"
$jsonPath = Join-Path $reportDir "flutter_test_report.json"
$failPath = Join-Path $reportDir "failed_tests.txt"
$summaryPath = Join-Path $reportDir "test_summary.txt"
$rawLogPath = Join-Path $reportDir "flutter_test_console.log"

New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

Write-Host "Running Flutter tests... reports will be saved in: $reportDir" -ForegroundColor Cyan

# Flutter's JSON reporter emits one JSON event per line. Capture stdout and stderr
# separately, then keep the JSON event stream for parsing.
$stdoutTemp = Join-Path $reportDir "flutter_test_stdout.tmp"
$stderrTemp = Join-Path $reportDir "flutter_test_stderr.tmp"

$previousPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& flutter test --reporter json 1> $stdoutTemp 2> $stderrTemp
$flutterExitCode = $LASTEXITCODE

Get-Content $stdoutTemp -ErrorAction SilentlyContinue | Set-Content $jsonPath -Encoding utf8
@(
    "Flutter test command: flutter test --reporter json"
    "Exit code: $flutterExitCode"
    ""
    "----- STDOUT -----"
    (Get-Content $stdoutTemp -Raw -ErrorAction SilentlyContinue)
    ""
    "----- STDERR -----"
    (Get-Content $stderrTemp -Raw -ErrorAction SilentlyContinue)
) | Set-Content $rawLogPath -Encoding utf8

# Parse each JSON line; ignore non-JSON diagnostic lines.
$events = @(
    Get-Content $jsonPath -ErrorAction SilentlyContinue | ForEach-Object {
        try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { $null }
    } | Where-Object { $null -ne $_ }
)

# Keep testDone events that indicate failure/error. Flutter JSON event fields can
# vary by SDK version; testID is the stable identifier in common versions.
$failedEvents = @(
    $events | Where-Object {
        $_.type -eq "testDone" -and
        ($_.result -in @("failure", "error") -or $_.skipped -eq $false -and $_.result -eq "failure")
    }
)

# Error events often contain the testID, error text, and stackTrace.
$errorEvents = @($events | Where-Object { $_.type -eq "error" })

$failureLines = [System.Collections.Generic.List[string]]::new()
$failureLines.Add("FLUTTER TEST FAILURES")
$failureLines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$failureLines.Add("Command: flutter test --reporter json")
$failureLines.Add("Flutter exit code: $flutterExitCode")
$failureLines.Add("Failed tests found: $($failedEvents.Count)")
$failureLines.Add("")

if ($failedEvents.Count -eq 0) {
    $failureLines.Add("No failed testDone events were detected.")
    $failureLines.Add("If Flutter exited with a non-zero code, inspect flutter_test_console.log and flutter_test_report.json.")
} else {
    $index = 0
    foreach ($failure in $failedEvents) {
        $index++
        $testId = if ($failure.testID) { [string]$failure.testID } else { "(test ID unavailable)" }
        $failureLines.Add("============================================================")
        $failureLines.Add("[$index] $testId")
        $failureLines.Add("Result: $($failure.result)")
        if ($failure.time -ne $null) { $failureLines.Add("Duration: $($failure.time) ms") }

        $matchingErrors = @($errorEvents | Where-Object {
            ($_.testID -and [string]$_.testID -eq $testId) -or
            ($_.testID -and [string]$_.testID -like "$testId*")
        })

        if ($matchingErrors.Count -gt 0) {
            foreach ($err in $matchingErrors) {
                $failureLines.Add("")
                $failureLines.Add("ERROR:")
                if ($err.error) { $failureLines.Add([string]$err.error) }
                if ($err.stackTrace) {
                    $failureLines.Add("")
                    $failureLines.Add("STACK TRACE:")
                    $failureLines.Add([string]$err.stackTrace)
                }
            }
        } else {
            $failureLines.Add("No separate error event was matched to this test. See the full JSON report.")
        }
        $failureLines.Add("")
    }
}

$failureLines | Set-Content $failPath -Encoding utf8

# Build a concise summary from testDone events.
$doneEvents = @($events | Where-Object { $_.type -eq "testDone" })
$passedCount = @($doneEvents | Where-Object { $_.result -eq "success" }).Count
$skippedCount = @($doneEvents | Where-Object { $_.skipped -eq $true -or $_.result -eq "skipped" }).Count

@(
    "FLUTTER TEST SUMMARY"
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    "Flutter exit code: $flutterExitCode"
    "Completed test events: $($doneEvents.Count)"
    "Passed: $passedCount"
    "Failed/error: $($failedEvents.Count)"
    "Skipped: $skippedCount"
    ""
    "Detailed failures: $failPath"
    "Full JSON report: $jsonPath"
    "Console log: $rawLogPath"
) | Set-Content $summaryPath -Encoding utf8

Remove-Item $stdoutTemp, $stderrTemp -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Test run finished." -ForegroundColor Cyan
Write-Host "Passed: $passedCount | Failed/error: $($failedEvents.Count) | Skipped: $skippedCount" -ForegroundColor Yellow
Write-Host "Failure report: $failPath" -ForegroundColor Green
Write-Host "Summary: $summaryPath"
Write-Host "Full JSON: $jsonPath"
Write-Host "Console log: $rawLogPath"

exit $flutterExitCode
