param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compStatuses
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
$compJobStatuses = @()

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

# Process component phase statuses and filter 'deploy_' phase jobs
$compPhaseJobStatuses = @{}
$compStatusesArray = $compStatuses -split ',\s*'

# Flag for checking "deploy-single-component"
$deploySingleComponentSkipped = $false

foreach ($compStatus in $compStatusesArray) {
    # Split the component status into phase and job name
    $compParts = $compStatus -split ': '
    
    if ($compParts.Length -eq 2) {
        # Only process if there are exactly two parts (phase and job status)
        $compPhase = $compParts[0].Trim()
        $compJobStatus = $compParts[1].Trim()

        # Check if phase starts with 'deploy_' to only include relevant jobs
        if ($compPhase -like "deploy_*") {
            # If 'deploy-single-component' is found, mark all related jobs as skipped
            if ($compPhase -like "*deploy-single-component*") {
                $deploySingleComponentSkipped = $true
            }

            # If deploy-single-component was found, mark all jobs in the phase as skipped
            if ($deploySingleComponentSkipped) {
                $compJobStatus = "skipped"
            }

            # Add the status to the corresponding phase
            if (-not $compPhaseJobStatuses.ContainsKey($compPhase)) {
                $compPhaseJobStatuses[$compPhase] = @()
            }

            # Add the status to the specific phase in the dictionary with emojis
            $compPhaseJobStatuses[$compPhase] += "$compJobStatus $(Get-Icon $compJobStatus.Split()[-1])"
        }
    }
    else {
        Write-Warning "Skipping invalid component status: $compStatus"
    }
}

# Convert collected statuses into multi-line outputs for logging (WITH emojis)
$finalControllerStatus = $controllerJobStatuses -join "`n"
$finalPhaseStatus = $phaseJobStatuses -join "`n"

# Output formatted component phase statuses
$finalCompPhaseStatus = ""
foreach ($phase in $compPhaseJobStatuses.Keys) {
    $finalCompPhaseStatus += "${phase}:`n"
    $finalCompPhaseStatus += ($compPhaseJobStatuses[$phase] -join "`n") + "`n"
}

# Store output in GitHub Actions properly (multi-line format)
Write-Output "controller_jobs_status<<EOF" >> $env:GITHUB_OUTPUT
Write-Output "$finalControllerStatus" >> $env:GITHUB_OUTPUT
Write-Output "EOF" >> $env:GITHUB_OUTPUT

Write-Output "phase_jobs_status<<EOF" >> $env:GITHUB_OUTPUT
Write-Output "$finalPhaseStatus" >> $env:GITHUB_OUTPUT
Write-Output "EOF" >> $env:GITHUB_OUTPUT

Write-Output "comp_phase_jobs_status<<EOF" >> $env:GITHUB_OUTPUT
Write-Output "$finalCompPhaseStatus" >> $env:GITHUB_OUTPUT
Write-Output "EOF" >> $env:GITHUB_OUTPUT

# Print statuses with emojis in logs for better visibility
Write-Output "Controller Job Statuses:`n$finalControllerStatus"
Write-Output "Phase Job Statuses:`n$finalPhaseStatus"
Write-Output "Component Phase Job Statuses:`n$finalCompPhaseStatus"
