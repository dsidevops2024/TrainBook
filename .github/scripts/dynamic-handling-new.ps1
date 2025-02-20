param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3
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

# Process component statuses dynamically for each extracted deploy phase
$compStatuses = @($compStatusPhase1, $compStatusPhase2, $compStatusPhase3)

for ($i = 0; $i -lt $compStatuses.Length; $i++) {
    if ($i -ge $allPhaseJobs.Count) { continue }  # Ensure index is within bounds

    $phaseName = $allPhaseJobs[$i]
    $compStatus = $compStatuses[$i]

    Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-status=$compStatus"

    if (-not $compStatus) {
        # Default to skipped if no status is available
        $defaultJobs = @("create-component-matrix", "deploy-to-AzService")
        foreach ($job in $defaultJobs) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-$job-status=$job status: skipped"
        }
    } else {
        # Extract job statuses dynamically
        $phaseJobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status:")
        foreach ($match in $phaseJobs) {
            $jobName = $match.Groups["jobName"].Value
            $jobStatus = Get-JobStatus -statusString $compStatus -jobName $jobName
            Add-Content -Path $env:GITHUB_OUTPUT -Value "$phaseName-$jobName-status=$jobName status: $jobStatus"
        }
    }
}
