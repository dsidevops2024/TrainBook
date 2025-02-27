param ( 
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compStatuses    
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

# Extract all deploy jobs dynamically from phaseStatus, including deploy-single-component, deploy-phase-one, deploy-phase-two, etc.
$deployPhases = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:") | ForEach-Object { $_.Groups[1].Value }

# Debugging: Check what deploy phases we found
Write-Output "Deploy Phases: $deployPhases"

# Split the component statuses from $compStatuses into an array
$compStatusesArray = $compStatuses -split ',\s*'

# Debugging: Output component statuses array
Write-Output "Component Statuses Array: $compStatusesArray"

# Initialize a dictionary to hold component job statuses per phase
foreach ($deployPhase in $deployPhases) {
    $compPhaseJobStatuses[$deployPhase] = @()
}

# Process the component statuses correctly
foreach ($compStatus in $compStatusesArray) {
    # Extract phase and job statuses from component status
    $compParts = $compStatus -split ": " 
    
    if ($compParts.Length -eq 2) {
        $compPhase = $compParts[0].Trim()
        $compJobStatus = $compParts[1].Trim()

        # Debugging: Output each component phase and job status
        Write-Output "Processing: $compPhase -> $compJobStatus"

        # Process only phases starting with 'deploy-'
        if ($compPhase -like "deploy-*") {
            # Add the job status to the corresponding phase
            if (-not $compPhaseJobStatuses.ContainsKey($compPhase)) {
                $compPhaseJobStatuses[$compPhase] = @()
            }

            # Add the job status with the appropriate emoji for logging
            $compPhaseJobStatuses[$compPhase] += "$compJobStatus $(Get-Icon $compJobStatus)"
        }
    }
    else {
        Write-Warning "Skipping invalid component status: $compStatus"
    }
}

# Now, iterate through each deploy phase and check if all its jobs are present in compStatuses
$finalCompPhaseStatus = ""

foreach ($deployPhase in $deployPhases) {
    $finalCompPhaseStatus += "${deployPhase}:`n"

    # Extract job names for the phase dynamically from the phaseStatus (jobs are those under 'deploy-' phases)
    $jobsInPhase = [regex]::Matches($phaseStatus, "${deployPhase}:(.*?)status:") | ForEach-Object { $_.Groups[1].Value.Trim() }

    # Debugging: Output jobs in phase
    Write-Output "Jobs in ${deployPhase}: $jobsInPhase"

    # Check each job dynamically for the phase
    foreach ($job in $jobsInPhase) {
        $jobStatusFound = $false

        # Check if the current job is in the component status for the phase
        foreach ($compStatus in $compPhaseJobStatuses[$deployPhase]) {
            if ($compStatus -like "*$job*") {
                $jobStatusFound = $true
                $finalCompPhaseStatus += "$compStatus`n"
                break
            }
        }

        # If job is not found in component status, mark it as skipped
        if (-not $jobStatusFound) {
            $finalCompPhaseStatus += "$job status: skipped ⏭️`n"
        }
    }

    $finalCompPhaseStatus += "`n"  # Add a newline after each phase
}

# Convert collected statuses into multi-line outputs for logging (WITH emojis)
$finalControllerStatus = $controllerJobStatuses -join "`n"
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
