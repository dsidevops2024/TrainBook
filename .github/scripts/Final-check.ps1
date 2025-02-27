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
$compPhaseJobStatuses = @{}

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

# Extract all deploy phases dynamically from $phaseStatus
$deployPhases = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:") | ForEach-Object { $_.Groups[1].Value }

# Split the component statuses from $compStatuses into an array
$compStatusesArray = $compStatuses -split ',\s*'

# Iterate over each deploy phase extracted from $phaseStatus
foreach ($deployPhase in $deployPhases) {
    # Initially assume the phase is not in $compStatuses
    $foundInCompStatuses = $false

    # Check if the current deploy phase exists in $compStatuses
    foreach ($compStatus in $compStatusesArray) {
        if ($compStatus -like "$deployPhase:*") {
            $foundInCompStatuses = $true
            break
        }
    }

    # If the deploy phase is not found in $compStatuses, dynamically mark the phase and its jobs as skipped
    if (-not $foundInCompStatuses) {
        $compPhaseJobStatuses[$deployPhase] = @()

        # Dynamically generate job names for the phase, marking each job as skipped
        $jobsInPhase = [regex]::Matches($phaseStatus, "$deployPhase:([\w\-]+) status:")
        foreach ($job in $jobsInPhase) {
            $jobName = $job.Groups[1].Value
            $compPhaseJobStatuses[$deployPhase] += "$jobName: skipped $(Get-Icon 'skipped')"
        }
    }
}

# Now process the actual component statuses for deploy phases
foreach ($compStatus in $compStatusesArray) {
    # Split the component status into phase and job status
    $compParts = $compStatus -split ': '

    if ($compParts.Length -eq 2) {
        $compPhase = $compParts[0].Trim()
        $compJobStatus = $compParts[1].Trim()

        # Process only phases starting with 'deploy-'
        if ($compPhase -like "deploy-*") {
            # Add the status to the corresponding deploy phase in the dictionary
            if (-not $compPhaseJobStatuses.ContainsKey($compPhase)) {
                $compPhaseJobStatuses[$compPhase] = @()
            }

            # Add the status with the appropriate emoji for logging
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
