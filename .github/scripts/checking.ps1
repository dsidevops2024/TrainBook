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

# Extract all deploy phases dynamically
$allPhaseJobs = [regex]::Matches($phaseStatus, "(deploy-[\w\-]+) status:") | ForEach-Object { $_.Groups[1].Value }

# Dynamically extract component statuses from the array (compStatuses)
$defaultJobs = @()
foreach ($compStatus in $compStatuses) {
    if ($compStatus) {
        $jobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status:") | ForEach-Object { $_.Groups["jobName"].Value }
        $defaultJobs += $jobs
    }
}
$defaultJobs = $defaultJobs | Select-Object -Unique  # Remove duplicates

# Process each component phase dynamically
for ($i = 0; $i -lt $compStatuses.Length; $i++) {
    if ($i -ge $allPhaseJobs.Count) { continue }  # Ensure index is within bounds

    $phaseName = $allPhaseJobs[$i]
    $compStatus = $compStatuses[$i]

    # Output phase status
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-status=$compStatus"

    if (-not $compStatus) {
        # Use dynamically extracted default jobs when component status is missing
        foreach ($job in $defaultJobs) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-$job-status=$job status: skipped"
        }
    } else {
        # Extract job statuses dynamically from the component status
        $phaseJobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status:")
        foreach ($match in $phaseJobs) {
            $jobName = $match.Groups["jobName"].Value
            $jobStatus = Get-JobStatus -statusString $compStatus -jobName $jobName
            Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-$jobName-status=$jobName status: $jobStatus"
        }
    }
}
