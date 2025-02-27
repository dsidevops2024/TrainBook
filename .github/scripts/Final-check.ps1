param (
    [string]$controllerStatus,
    [string]$phaseStatus
)

# Initialize arrays to collect statuses
$controllerJobStatuses = @()
$phaseJobStatuses = @()

# Extract all controller job statuses dynamically
$controllerJobs = [regex]::Matches($controllerStatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")
foreach ($match in $controllerJobs) {
    $jobName = $match.Groups["jobName"].Value
    $jobStatus = $match.Groups["status"].Value
    $statusEntry = "$jobName status: $jobStatus"
    $controllerJobStatuses += $statusEntry
    
    # Export each job's status separately
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$jobName-status=$jobStatus"
}

# Extract all phase job statuses dynamically
$phaseJobs = [regex]::Matches($phaseStatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["jobName"].Value
    $phaseStatusValue = $match.Groups["status"].Value
    $statusEntry = "$phaseName status: $phaseStatusValue"
    $phaseJobStatuses += $statusEntry
    
    # Export each phase's status separately
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-status=$phaseStatusValue"
}

# Convert collected statuses into multi-line outputs
$finalControllerStatus = $controllerJobStatuses -join "`n"
$finalPhaseStatus = $phaseJobStatuses -join "`n"

# Output multi-line controller statuses
"[controller_jobs_status]<<EOF`n$finalControllerStatus`nEOF" | Out-File -FilePath $env:GITHUB_OUTPUT -Append

# Output multi-line phase statuses
"[phase_jobs_status]<<EOF`n$finalPhaseStatus`nEOF" | Out-File -FilePath $env:GITHUB_OUTPUT -Append
