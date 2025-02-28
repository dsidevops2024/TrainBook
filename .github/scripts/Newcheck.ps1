param (
    [string]$controllerStatus,
    [string]$phaseStatus
)

# Function to return appropriate emoji based on status
function Get-Icon($status) {
    switch ($status.ToLower()) {
        "success" { return "✅" }  # Green Checkmark
        "failed"  { return "❌" }  # Red Cross
        "skipped" { return "⚠️" }  # Skipped Icon
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
    $icon = Get-Icon $jobStatus  # Get emoji for logs

    # Store for logging purposes (WITH emojis)
    $controllerJobStatuses += "$jobName status: $jobStatus $icon"
}

# Extract all phase job statuses dynamically
$phaseJobs = [regex]::Matches($phaseStatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["jobName"].Value
    $phaseStatusValue = $match.Groups["status"].Value
    $icon = Get-Icon $phaseStatusValue  # Get emoji for logs

    # Store for logging purposes (WITH emojis)
    $phaseJobStatuses += "$phaseName status: $phaseStatusValue $icon"
}

# Convert collected statuses into multi-line outputs for logging (WITH emojis)
$finalControllerStatus = $controllerJobStatuses -join "`n"
$finalPhaseStatus = $phaseJobStatuses -join "`n"

# ✅ Store output in GitHub Actions properly (multi-line format)
Write-Output "controller_jobs_status<<EOF" >> $env:GITHUB_OUTPUT
Write-Output "$finalControllerStatus" >> $env:GITHUB_OUTPUT
Write-Output "EOF" >> $env:GITHUB_OUTPUT

Write-Output "phase_jobs_status<<EOF" >> $env:GITHUB_OUTPUT
Write-Output "$finalPhaseStatus" >> $env:GITHUB_OUTPUT
Write-Output "EOF" >> $env:GITHUB_OUTPUT

# ✅ Print statuses with emojis in logs for better visibility
Write-Output "Controller Job Statuses:`n$finalControllerStatus"
Write-Output "Phase Job Statuses:`n$finalPhaseStatus"
