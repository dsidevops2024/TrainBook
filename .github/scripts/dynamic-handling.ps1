param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3
)

# Helper function to extract job status dynamically using regex
function Get-JobStatus {
    param (
        [string]$statusString,
        [string]$jobName
    )
    $match = [regex]::Match($statusString, "$jobName status: ([\w\.\-\s]+)(,|$)")
    return $match.Success ? $match.Groups[1].Value.Trim() : "not available"
}

# ✅ Extract and process controller jobs dynamically
Add-Content -Path $env:GITHUB_OUTPUT -Value "controller-status=$controllerStatus"

$controllerJobs = [regex]::Matches($controllerStatus, "(?<jobName>[\w\.\-]+) status:")
foreach ($match in $controllerJobs) {
    $jobName = $match.Groups["jobName"].Value
    $jobStatus = Get-JobStatus -statusString $controllerStatus -jobName $jobName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$jobName-status=$jobStatus"
}

# ✅ Set overall phase status
Add-Content -Path $env:GITHUB_OUTPUT -Value "overall-phase-status=$phaseStatus"

# ✅ Extract and process phases dynamically
$phaseJobs = [regex]::Matches($phaseStatus, "(?<jobName>[\w\.\-]+) status:")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["jobName"].Value
    $phaseStatusValue = Get-JobStatus -statusString $phaseStatus -jobName $phaseName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phaseName}-status=$phaseStatusValue"
}


# Collect all phases
$allPhaseJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\.\-]+) status:") | ForEach-Object { $_.Groups[1].Value }
$compStatuses = @($compStatusPhase1, $compStatusPhase2, $compStatusPhase3)

foreach ($index in 0..($allPhaseJobs.Count - 1)) {
    $phase = $allPhaseJobs[$index]
    $compStatus = ($index -lt $compStatuses.Count) ? $compStatuses[$index] : "not available"

    # Phase status
    $phaseStatusValue = Get-JobStatus -statusString $phaseStatus -jobName $phase
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-status=$phaseStatusValue"

    # Component status
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-component-status=$compStatus"

    # Extract job statuses
    $jobMatches = [regex]::Matches($phaseStatus, "$phase.*?([\w\.\-]+) status: ([\w\.\-\s]+)(,|$)")

    if ($jobMatches.Count -gt 0) {
        foreach ($jobMatch in $jobMatches) {
            $jobName = $jobMatch.Groups[1].Value
            $jobStatus = $jobMatch.Groups[2].Value.Trim()
            $outputName = "${phase}-${jobName}-status"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "$outputName=$jobStatus"
        }
    } else {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job-statuses=No jobs found"
    }
}
