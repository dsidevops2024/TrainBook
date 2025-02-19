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
$phaseJobs = [regex]::Matches($phaseStatus, "(?<jobName>[\w\-]+) status:")
foreach ($match in $phaseJobs) {
    $phaseName = $match.Groups["jobName"].Value
    $phaseStatusValue = Get-JobStatus $phaseStatus $phaseName
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phaseName}_status=$phaseName status: $phaseStatusValue"
}

# Dynamically extract all phases from phaseStatus
$allPhaseJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:") | ForEach-Object { $_.Groups[1].Value }

# Dynamically extract component statuses from phaseStatus
$compStatuses = @()
foreach ($phase in $allPhaseJobs) {
    $compStatusMatch = [regex]::Match($phaseStatus, "$phase.*status: (.*?)(,|$)")
    if ($compStatusMatch.Success) {
        $compStatuses += $compStatusMatch.Groups[1].Value
    } else {
        $compStatuses += "not available"
    }
}

# Dynamically process each phase and job status
foreach ($index in 0..($allPhaseJobs.Count - 1)) {
    $phase = $allPhaseJobs[$index]
    $compStatus = $compStatuses[$index]  # Get the component status dynamically for each phase

    $phaseStatusValue = ($phaseStatus -split "$phase status: ")[1] -split ", " | Select-Object -First 1
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}_status=$phase status: $phaseStatusValue"

    # Set the component status dynamically for each phase
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-status=$compStatus"

    # Dynamically extract job statuses (handles any number of jobs)
    # Find all jobs associated with the current phase (jobs can be extracted from phaseStatus)
    $jobMatches = [regex]::Matches($phaseStatus, "$phase.*?([\w\-]+) status: (.*?)(,|$)")

    if ($jobMatches.Count -gt 0) {
        foreach ($jobMatch in $jobMatches) {
            $jobName = $jobMatch.Groups[1].Value
            $jobStatus = $jobMatch.Groups[2].Value
            Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-${jobName}-status=$jobName status: $jobStatus"
        }
    } else {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job-statuses=No jobs found"
    }
}
