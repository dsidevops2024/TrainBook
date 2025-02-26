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

# **Key Change: Initialize a hashtable to group component statuses by phase**
$compStatusGrouped = @{}

# Process each component phase dynamically
for ($i = 0; $i -lt $compStatuses.Length; $i++) {
    if ($i -ge $allPhaseJobs.Count) { continue }  # Ensure index is within bounds

    $phaseName = $allPhaseJobs[$i]
    $compStatus = $compStatuses[$i]

    # **Key Change: Initialize phase in the grouped hashtable if not already**
    if (-not $compStatusGrouped.ContainsKey($phaseName)) {
        $compStatusGrouped[$phaseName] = @()
    }

    # **Key Change: If the component status is not empty, process and group it**
    if ($compStatus) {
        # Extract jobs from the component status string
        $phaseJobs = [regex]::Matches($compStatus, "(?<jobName>[\w\-]+) status:") 
        foreach ($match in $phaseJobs) {
            $jobName = $match.Groups["jobName"].Value
            $jobStatus = Get-JobStatus -statusString $compStatus -jobName $jobName
            $compStatusGrouped[$phaseName] += "$jobName status: $jobStatus"
        }
    } else {
        # **Key Change: If component status is empty, use default jobs**
        foreach ($job in $defaultJobs) {
            $compStatusGrouped[$phaseName] += "$job status: skipped"
        }
    }
}

# **Key Change: Output the grouped component statuses for each phase**
foreach ($phase in $compStatusGrouped.Keys) {
    $groupedStatus = ($compStatusGrouped[$phase] -join ", ")
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}: $groupedStatus"
}
