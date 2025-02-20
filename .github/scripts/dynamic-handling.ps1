param (
    [string]$controllerStatus,
    [string]$phaseStatus
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

# Extract all phases dynamically
$allPhaseJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\.\-]+) status:") | ForEach-Object { $_.Groups[1].Value }

# ✅ Dynamically extract and process each phase's status
foreach ($phase in $allPhaseJobs) {
    $phaseStatusValue = Get-JobStatus -statusString $phaseStatus -jobName $phase
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-status=$phaseStatusValue"

    # ✅ Dynamically extract component statuses within each phase
    $compStatusMatch = [regex]::Match($phaseStatus, "$phase.*status: ([\w\.\-\s]+)(,|$)")
    $compStatus = $compStatusMatch.Success ? $compStatusMatch.Groups[1].Value.Trim() : "not available"

    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-component-status=$compStatus"

    # ✅ Dynamically extract jobs associated with the phase
    $jobMatches = [regex]::Matches($phaseStatus, "$phase.*?([\w\.\-]+) status: ([\w\.\-\s]+)(,|$)")

    if ($jobMatches.Count -gt 0) {
        foreach ($jobMatch in $jobMatches) {
            $jobName = $jobMatch.Groups[1].Value
            $jobStatus = $jobMatch.Groups[2].Value.Trim()
            Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${jobName}-status=$jobStatus"
        }
    } else {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job-statuses=No jobs found"
    }
}
