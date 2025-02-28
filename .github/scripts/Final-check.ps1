param ( 
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compstatuses
)

Write-Output "Controller Status: $controllerStatus"
Write-Output "Phase Status: $phaseStatus"
Write-Output "Component Statuses: $compStatuses"

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

$compStatuses = $compStatuses.Trim()
# Split the component statuses from $compStatuses into phases and jobs
$compStatusesArray = $compStatuses -split ',\s*'

# Initialize a dictionary to hold component job statuses per phase
foreach ($compStatus in $compStatusesArray) {
    # If the status is enclosed within braces '{}', we want to split accordingly
    if ($compStatus -match "(?<phaseName>deploy-[\w\-]+):\s*{(?<jobStatuses>.*)}") {
        $phaseName = $matches["phaseName"]
        $jobStatuses = $matches["jobStatuses"]
        
        # Split job statuses into individual jobs
        $jobStatusArray = $jobStatuses -split ",\s*"

        # Add each job status to the corresponding phase
        foreach ($jobStatus in $jobStatusArray) {
            $compPhaseJobStatuses[$phaseName] += $jobStatus.Trim()
        }
    }
    else {
        Write-Warning "Skipping invalid component status: $compStatus"
    }
}

# Build the final component phase status with the new format
$finalCompPhaseStatus = ""

foreach ($deployPhase in $compPhaseJobStatuses.Keys) {
    $finalCompPhaseStatus += "$deployPhase:`n"  # Add phase name
    
    # Join the component job statuses for this phase, each on a new line
    $finalCompPhaseStatus += ($compPhaseJobStatuses[$deployPhase] -join "`n") + "`n"  # Each status on a new line
}

# Format final controller job statuses
$finalControllerStatus = $controllerJobStatuses -join "`n"

# Format final phase job statuses
$finalPhaseStatus = $phaseJobStatuses -join "`n"

# Output formatted component phase statuses
Write-Output "Controller Job Statuses:`n$finalControllerStatus"
Write-Output "Phase Job Statuses:`n$finalPhaseStatus"
Write-Output "Component Job Statuses:`n$finalCompPhaseStatus"

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
