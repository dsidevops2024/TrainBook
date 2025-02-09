# report-job-status.ps1
param (
    [string]$componentInputResult,
    [string]$environmentMatrixResult,
    [string]$environmentRunnerResult,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3
)

# Initialize ControllerJobStatus
$ControllerJobStatus = "job1 status: $componentInputResult | "
$ControllerJobStatus += "job2 status: $environmentMatrixResult | "
$ControllerJobStatus += "job3 status: $environmentRunnerResult"

# Output Controller Job Status
Write-Host $ControllerJobStatus
Write-Output "::set-output name=Controller-Job-Status::$ControllerJobStatus"

# Extract and output individual job statuses
for ($job = 1; $job -le 3; $job++) {
    $job_status = $ControllerJobStatus -match "job$job status: ([^|]+)" | Out-Null; $matches[1]
    Write-Output "::set-output name=controller-Job$job-status::job$job status: $job_status"
}

# Handle phase status for all 3 phases
for ($phase = 1; $phase -le 3; $phase++) {
    $phase_status_value = $phaseStatus -match "phase $phase status: ([^|]+)" | Out-Null; $matches[1]
    Write-Output "::set-output name=overall-job-status-phase$phase::$phase_status_value"
}

# Handle component job status for all phases
for ($phase = 1; $phase -le 3; $phase++) {
    if ($phase -eq 1) { $comp_status = $compStatusPhase1 }
    elseif ($phase -eq 2) { $comp_status = $compStatusPhase2 }
    elseif ($phase -eq 3) { $comp_status = $compStatusPhase3 }

    if ([string]::IsNullOrEmpty($comp_status)) {
        $comp_status_job1 = "job1 status: skipped"
        $comp_status_job2 = "job2 status: skipped"
    } else {
        $comp_status_job1 = $comp_status -match "job1 status: ([^|]+)" | Out-Null; $matches[1]
        $comp_status_job2 = $comp_status -match "job2 status: ([^|]+)" | Out-Null; $matches[1]
    }

    Write-Output "::set-output name=comp-status-phase$phase::$comp_status"
    Write-Output "::set-output name=comp-status-phase$phase-job1::$comp_status_job1"
    Write-Output "::set-output name=comp-status-phase$phase-job2::$comp_status_job2"
}
