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
$phaseJobs = [regex]::Matches($phaseStatus, "(?<phaseName>[\w\-]+) status:")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["phaseName"].Value
    $phaseStatusValue = Get-JobStatus $phaseStatus $phaseName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phaseName}_status=$phaseName status: $phaseStatusValue"
}

# Dynamically handle jobs that start with 'deploy-'
$deployJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:")
$allPhaseJobs = $deployJobs | ForEach-Object { $_.Groups[1].Value }

# Handle component statuses dynamically for each 'deploy-' phase job
foreach ($phase in $allPhaseJobs) {
    # Dynamically select the compStatus value based on the phase by extracting phase number
    $phaseNumber = if ($phase -match "deploy-phase-(\d+)") {
        $matches[1]
    }

    # Use the dynamic phase number to access the respective compStatus variable
    $compStatusVariableName = "compStatusPhase$phaseNumber"
    $compStatus = Get-Variable -Name $compStatusVariableName -ValueOnly

    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-status=$compStatus"

    # If no compStatus available, mark jobs as skipped dynamically
    if (-not $compStatus) {
        # Dynamically extract all job names from the compStatus variable
        $compStatusJobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status: ")

        # If no jobs were found, fall back to skipped jobs
        if ($compStatusJobs.Count -eq 0) {
            $jobStatuses = @("status: skipped")
            foreach ($jobStatus in $jobStatuses) {
                Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job-status=$jobStatus"
            }
        }
        else {
            # Process the dynamically extracted job statuses from compStatus
            foreach ($match in $compStatusJobs) {
                $jobName = $match.Groups["jobName"].Value
                $compStatusJob = Get-JobStatus $compStatus $jobName
                Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${jobName}-status=$compStatusJob"
            }
        }
    } else {
        # Dynamically extract job statuses using regex for all jobs in the component status
        $compStatusJobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status: ")
        foreach ($match in $compStatusJobs) {
            $jobName = $match.Groups["jobName"].Value
            $compStatusJob = Get-JobStatus $compStatus $jobName
            Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${jobName}-status=$compStatusJob"
        }
    }
}
