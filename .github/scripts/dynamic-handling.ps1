param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3,
)

# Function to extract job names and statuses dynamically from a status string
function Get-Jobs {
    param (
        [string]$status
    )

    # Regular expression to match job names (assuming the pattern "job-name status: <status>")
    $regex = '([a-zA-Z0-9\-_]+) status: ([^,]+)'  # Matches job names and their statuses

    $matches = [regex]::Matches($status, $regex)
    $jobDetails = @()

    foreach ($match in $matches) {
        $jobDetails += [PSCustomObject]@{
            JobName = $match.Groups[1].Value
            JobStatus = $match.Groups[2].Value
        }
    }

    return $jobDetails
}

# Controller dynamically extracted jobs
$controllerJobs = Get-Jobs -status $controllerStatus

# Set controllerStatus as output
Add-Content -Path $env:GITHUB_OUTPUT -Value "controller-status=$controllerStatus"

# Loop through each controller job dynamically and add job status to output
foreach ($job in $controllerJobs) {
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$($job.JobName)-status=$($job.JobName) status: $($job.JobStatus)"
}

# Set phaseStatus as output
Add-Content -Path $env:GITHUB_OUTPUT -Value "overall-phase-status=$phaseStatus"

# Phase dynamically extracted jobs (from phaseStatus string)
$phaseJobs = Get-Jobs -status $phaseStatus

# Loop through each phase job dynamically and add phase job status to output
foreach ($job in $phaseJobs) {
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$($job.JobName)-status=$($job.JobName) status: $($job.JobStatus)"
}

# Dynamically create a map of phase jobs to component statuses
$phaseJobToCompStatusMap = @{}
$compStatuses = @($compStatusPhase1, $compStatusPhase2, $compStatusPhase3)

# Automatically map phase jobs to component statuses (based on order)
$counter = 0
foreach ($job in $phaseJobs) {
    $phaseName = $job.JobName
    if ($counter -lt $compStatuses.Count) {
        $phaseJobToCompStatusMap[$phaseName] = $compStatuses[$counter]
    } else {
        # Handle cases where there are more phase jobs than component statuses
        $phaseJobToCompStatusMap[$phaseName] = "Component status: not available"
    }
    $counter++
}

# Process component status dynamically for each phase
foreach ($job in $phaseJobs) {
    $phase = $job.JobName
    $compStatus = $phaseJobToCompStatusMap[$phase]

    # Add the component status for each phase
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-status=$compStatus"

    # Extract jobs dynamically from the component status
    $compStatusJobs = @()  # Array to hold dynamically extracted job names for each phase

    # If a component status is available, try to extract job statuses dynamically
    if ($compStatus) {
        # Extract all job names dynamically from the component status (no hardcoded job names)
        $compStatusJobs = Get-Jobs -status $compStatus

        # Loop through each extracted job and process its status dynamically
        foreach ($compJob in $compStatusJobs) {
            # Add job status dynamically to the output
            Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${compJob.JobName}-status=$($compJob.JobName) status: $($compJob.JobStatus)"
        }
    }

    # **Handle the case when no jobs were found**:
    if ($compStatusJobs.Count -eq 0) {
        # If no job details were found, dynamically add skipped statuses for all job names found in phaseStatus
        $jobNames = $phaseJobs.JobName  # Get the names of all jobs in this phase

        foreach ($jobName in $jobNames) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${jobName}-status=$jobName status: skipped"
        }
    }
}
