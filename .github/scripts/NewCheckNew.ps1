#$controllerStatus = "check-component-input status: success, set-environment-runner status: success, create-environment-matrix status: success"
#$phaseStatus = "check-approvals status: success, deploy-single-component status: skipped, deploy-phase-one status: success, deploy-phase-two status: success, Reset-Approvals status: success"
#$componentStatus = "deploy-phase-one / create-component-matrix status: success, deploy-phase-one / deploy-to-AzService status: success, deploy-phase-two / create-component-matrix status: success, deploy-phase-two / deploy-to-AzService status: success"
param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$componentStatus  # Receives component statuses as an array
)
Write-Output "Controller Status: $controllerStatus"
Write-Output "Phase Status: $phaseStatus"
Write-Output "Component Statuses: $componentStatus"

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
$compPhaseJobStatuses = @()

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

# Extract deploy phases and sub-jobs from the input string
$pattern = '([a-zA-Z0-9-]+)\s*/\s*([a-zA-Z0-9-]+)\s*status:\s*(\w+)'
$matches = [regex]::Matches($componentStatus, $pattern)

# Initialize a hashtable to store jobs and their corresponding sub-jobs with status
$jobDict = @{ }
$subJobSet = @{ }

# Loop through the matches in the input string and organize them into the hash table
foreach ($match in $matches) {
    $mainJob = $match.Groups[1].Value
    $subJob = $match.Groups[2].Value
    $status = $match.Groups[3].Value

    # Check if the main job is already in the dictionary
    if (-not $jobDict.ContainsKey($mainJob)) {
        $jobDict[$mainJob] = @()  # Initialize an empty array for sub-jobs and status
    }

    # Create a unique entry for the sub-job and status
    $jobDict[$mainJob] += "$subJob status: $status"

    # Add the sub-job to the set for dynamic extraction
    $subJobSet[$subJob] = $true
}

# Extract just the phase names (without status) for easier checking later
$deployPhasesNames = [regex]::Matches($phaseStatus, '\bdeploy-[a-zA-Z0-9-]+\b') | ForEach-Object { $_.Value }

# Collect and store the statuses as a single string to output to GitHub
$controllerOutput = $controllerJobStatuses -join "`n"
$phaseOutput = $phaseJobStatuses -join "`n"
$componentOutput = ""

# Collect component and sub-job statuses with icons
foreach ($mainJob in $deployPhasesNames) {
    $componentOutput += "$mainJob`n"

    if ($jobDict.ContainsKey($mainJob)) {
        foreach ($entry in $jobDict[$mainJob]) {
            # Extract the job name and status
            $jobParts = $entry -split " status:"
            $status = $jobParts[1].Trim()
            $icon = Get-Icon $status  # Get emoji for logs

            $componentOutput += "$entry $icon`n"
        }
    }
    else {
        foreach ($subJob in $subJobSet.Keys) {
            $componentOutput += "$subJob status: skipped ⏭️`n"
        }
    }
}

# Set the outputs to GitHub Actions using $env:GITHUB_OUTPUT
$env:GITHUB_OUTPUT = "controller_status=$controllerOutput"
$env:GITHUB_OUTPUT += "`nphase_status=$phaseOutput"
$env:GITHUB_OUTPUT += "`ncomponent_status=$componentOutput"

Write-Host "Controller Statuses:"
$controllerJobStatuses | ForEach-Object { Write-Host $_ }

Write-Host "Phase Statuses:"
$phaseJobStatuses | ForEach-Object { Write-Host $_ }

Write-Host "Component and Sub-Job Statuses:"
Write-Host $componentOutput
