param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string[]]$compStatuses  # Receives component statuses as an array
)

# Helper function to extract the status of a job dynamically
function Get-JobStatus {
    param (
        [string]$statusString,
        [string]$jobName
    )
    if ($statusString -match "$jobName status: ([^,]+)") {
        return $matches[1]
    }
    return "not available"
}

# Dynamically extract and process controller jobs
Add-Content -Path $env:GITHUB_OUTPUT -Value "controller-status=$controllerStatus"

# Extract all controller jobs dynamically
$controllerJobs = [regex]::Matches($controllerStatus, "(?<jobName>[\w\-]+) status:") 
foreach ($match in $controllerJobs) {
    $jobName = $match.Groups["jobName"].Value
    $componentStatus = Get-JobStatus -statusString $controllerStatus -jobName $jobName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$jobName-status=$jobName status: $componentStatus"
}

# Set phase status as output
Add-Content -Path $env:GITHUB_OUTPUT -Value "overall-phase-status=$phaseStatus"

# Extract and process phases dynamically
$phaseJobs = [regex]::Matches($phaseStatus, "(?<jobName>[\w\-]+) status:") 
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["jobName"].Value
    $phaseStatusValue = Get-JobStatus -statusString $phaseStatus -jobName $phaseName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phaseName}_status=$phaseName status: $phaseStatusValue"
}

# Extract all deploy phases dynamically from phaseStatus
$allPhaseJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:") | ForEach-Object { $_.Groups[1].Value }

# Process each component phase dynamically based on compStatuses
for ($i = 0; $i -lt $compStatuses.Length; $i++) {
    # Ensure index is within bounds of available deploy phases
    if ($i -ge $allPhaseJobs.Count) { continue }

    $phaseName = $allPhaseJobs[$i]  # Extract the corresponding phase name (e.g., deploy-phase-two)
    $compStatus = $compStatuses[$i]  # Extract the component status string for this phase

    if (-not $compStatus) {
        # Handle missing component status (e.g., skipped jobs)
        Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-status=skipped"
    } else {
        # Extract job names and their status from the component status
        if ($compStatus -match "(deploy-[\w\-]+): ([\w\-]+) status: ([^,]+)") {
            $componentPhase = $matches[1]   # e.g., deploy-phase-two
            $jobName = $matches[2]          # e.g., create-component-matrix
            $status = $matches[3]           # e.g., success

            # Output the component job status to GitHub output
            Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-$jobName-status=$jobName status: $status"
        }
    }
}

# Dynamically extract component statuses and handle missing/empty values
$defaultJobs = @()
foreach ($compStatus in $compStatuses) {
    if ($compStatus) {
        # Extract the job names dynamically from the component status
        $jobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status:") | ForEach-Object { $_.Groups["jobName"].Value }
        $defaultJobs += $jobs
    }
}
$defaultJobs = $defaultJobs | Select-Object -Unique  # Remove duplicates

# Handle missing jobs for dynamically added jobs like "azure-checking"
for ($i = 0; $i -lt $compStatuses.Length; $i++) {
    $compStatus = $compStatuses[$i]
    if (-not $compStatus) {
        # Handle missing component status
        Add-Content -Path $env:GITHUB_OUTPUT -Value "component-status-$i=skipped"
    } else {
        # Extract job statuses dynamically from the component status
        $phaseJobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status:")
        foreach ($match in $phaseJobs) {
            $jobName = $match.Groups["jobName"].Value
            $jobStatus = Get-JobStatus -statusString $compStatus -jobName $jobName
            Add-Content -Path $env:GITHUB_OUTPUT -Value "$jobName-status=$jobName status: $jobStatus"
        }
    }
}
