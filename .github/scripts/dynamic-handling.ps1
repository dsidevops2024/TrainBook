param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3
)

# Helper function to extract the status of a job dynamically
function Get-JobStatus($statusString, $jobName) {
    $jobStatus = ($statusString -split "$jobName status: ")[1] -split ", " | Select-Object -First 1
    return $jobStatus
}

# Dynamically extract and process controller jobs
Add-Content -Path $env:GITHUB_OUTPUT -Value "controller-status=$controllerStatus"

# Extract all controller jobs by matching "job status" patterns
$controllerJobs = [regex]::Matches($controllerStatus, "(?<jobName>[\w\-]+) status:")
foreach ($match in $controllerJobs) {
    $jobName = $match.Groups["jobName"].Value
    $componentStatus = Get-JobStatus $controllerStatus $jobName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$jobName-status=$jobName status: $componentStatus"
}

# Set phase status as output
Add-Content -Path $env:GITHUB_OUTPUT -Value "overall-phase-status=$phaseStatus"

# Extract and process phases dynamically
$phaseJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups[1].Value
    $phaseStatusValue = Get-JobStatus $phaseStatus $phaseName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phaseName}_status=$phaseName status: $phaseStatusValue"
}

# Dynamically handle jobs that start with 'deploy-' (e.g., deploy-single-component, deploy-phase-one, etc.)
$allPhaseJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:") | ForEach-Object { $_.Groups[1].Value }

# Handle component statuses dynamically for each 'deploy-' phase job
foreach ($phase in $allPhaseJobs) {
    # Dynamically construct the compStatus variable name based on the phase
    $compStatusVariableName = "compStatus$($phase -replace 'deploy-', '')" # e.g., compStatussinglecomponent, compStatusphaseone
    
    try {
        # Attempt to get the compStatus dynamically based on the phase name
        $compStatus = Get-Variable -Name $compStatusVariableName -ValueOnly
    }
    catch {
        # Handle case where the variable doesn't exist
        Write-Warning "Variable '$compStatusVariableName' not found. Skipping..."
        $compStatus = ""
    }

    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-status=$compStatus"

    if (-not $compStatus) {
        # If no compStatus, mark jobs as skipped dynamically
        $compStatusJobs = @("create-component-matrix", "deploy-to-AzService")
        
        foreach ($job in $compStatusJobs) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${job}-status=status: skipped"
        }
    }
    else {
        # Extract job statuses for the compStatus
        $compStatusJobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status: ")
        foreach ($match in $compStatusJobs) {
            $jobName = $match.Groups["jobName"].Value
            $compStatusJob = Get-JobStatus $compStatus $jobName
            Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${jobName}-status=$compStatusJob"
        }
    }
}
