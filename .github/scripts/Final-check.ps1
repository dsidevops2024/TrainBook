param (
    [string]$controllerStatus,
    [string]$phaseStatus
)

# Function to return appropriate emoji based on status
function Get-Icon($status) {
    switch ($status.ToLower()) {
        "success" { return "✅" }  # Green Checkmark
        "failed"  { return "❌" }  # Red Cross
        "skipped" { return "⏭️" }  # Skipped Icon
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

    # Store for logging purposes with emoji
    $controllerJobStatuses += "$jobName status: $jobStatus $icon"

    # Store GitHub output without emoji (to prevent errors)
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$jobName-status=$jobStatus"
}

# Extract all phase job statuses dynamically
$phaseJobs = [regex]::Matches($phaseStatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["jobName"].Value
    $phaseStatusValue = $match.Groups["status"].Value
    $icon = Get-Icon $phaseStatusValue  # Call Get-Icon function here

    # Store for logging purposes with emoji
    $phaseJobStatuses += "$phaseName status: $phaseStatusValue $icon"

    # Store GitHub output without emoji (to prevent errors)
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-status=$phaseStatusValue"
}

# Convert collected statuses into multi-line outputs for logging
$finalControllerStatus = $controllerJobStatuses -join "`n"
$finalPhaseStatus = $phaseJobStatuses -join "`n"

# Store GitHub output without emojis
Add-Content -Path $env:GITHUB_OUTPUT -Value "controller_jobs_status=$finalControllerStatus"
Add-Content -Path $env:GITHUB_OUTPUT -Value "phase_jobs_status=$finalPhaseStatus"

# Print the statuses with emojis for visibility in logs
Write-Output "Controller Job Statuses:`n$finalControllerStatus"
Write-Output "Phase Job Statuses:`n$finalPhaseStatus"
