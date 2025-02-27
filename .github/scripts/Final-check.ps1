param (
    [string]$controllerStatus,
    [string]$phaseStatus
)

# Function to return appropriate emoji based on status
function Get-Icon($status) {
    switch ($status.ToLower()) {
        "success" { return "✅" }  # Green Checkmark
        "failed"  { return "❌" }  # Red Cross
        "skipped" { return "⏭️" }  # Fast-Forward/Skipped Icon
        default   { return "⚪" }  # Default Neutral Circle
    }
}

# Initialize arrays to collect statuses
$controllerJobStatuses = @()
$phaseJobStatuses = @()

# Extract all controller job statuses dynamically
$controllerJobs = [regex]::Matches($controllerStatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")
foreach ($match in $controllerJobs) {
    $jobName = $match.Groups["jobName"].Value
    $jobStatus = $match.Groups["status"].Value
    $icon = Get-Icon $jobStatus  # Call Get-Icon function here
    $statusEntry = "$jobName status: $jobStatus $icon"
    $controllerJobStatuses += $statusEntry
    
    # Export each job's status separately with icon
    "$jobName-status=$jobStatus $icon" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

# Extract all phase job statuses dynamically
$phaseJobs = [regex]::Matches($phaseStatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["jobName"].Value
    $phaseStatusValue = $match.Groups["status"].Value
    $icon = Get-Icon $phaseStatusValue  # Call Get-Icon function here
    $statusEntry = "$phaseName status: $phaseStatusValue $icon"
    $phaseJobStatuses += $statusEntry
    
    # Export each phase's status separately with icon
    "$phaseName-status=$phaseStatusValue $icon" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
}

# Convert collected statuses into multi-line outputs
$finalControllerStatus = $controllerJobStatuses -join "`n"
$finalPhaseStatus = $phaseJobStatuses -join "`n"

# Output multi-line controller statuses with emojis
"controller_jobs_status=$finalControllerStatus" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8

# Output multi-line phase statuses with emojis
"phase_jobs_status=$finalPhaseStatus" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8
