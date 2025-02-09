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
$ControllerJobStatus = "job1 status: $componentInputResult, "
$ControllerJobStatus += "job2 status: $environmentMatrixResult, "
$ControllerJobStatus += "job3 status: $environmentRunnerResult"

# Print job statuses with each status on a new line
Write-Host $ControllerJobStatus
Write-Output "::set-output name=Controller-Job-Status::$ControllerJobStatus"

# Loop through the jobs and dynamically extract each status
for ($job = 1; $job -le 3; $job++) {
    $job_status = $ControllerJobStatus -split "job$job status: " | Select-String -Pattern ".*" | ForEach-Object { $_.Line.Split(',')[0] }
    Write-Output "::set-output name=controller-Job$job-status::job$job status: $job_status"
}

# Loop to set phase status for 1, 2, and 3
for ($phase = 1; $phase -le 3; $phase++) {
    $phase_status_value = ($phaseStatus -split "phase $phase status: " | Select-String -Pattern ".*" | ForEach-Object { $_.Line.Split(',')[0] })
    Write-Output "::set-output name=overall-job-status-phase$phase::$phase_status_value"
}

# Loop to handle component job status for all three phases
for ($phase = 1; $phase -le 3; $phase++) {
    if ($phase -eq 1) { $comp_status = $compStatusPhase1 }
    elseif ($phase -eq 2) { $comp_status = $compStatusPhase2 }
    elseif ($phase -eq 3) { $comp_status = $compStatusPhase3 }

    # Check if comp_status is empty (i.e., the job was skipped)
    if ([string]::IsNullOrEmpty($comp_status)) {
        $comp_status_job1 = "job1 status: skipped"
        $comp_status_job2 = "job2 status: skipped"
    }
    else {
        $comp_status_job1 = $comp_status -split "job1 status: " | Select-String -Pattern ".*" | ForEach-Object { $_.Line.Split(',')[0] }
        $comp_status_job2 = $comp_status -split "job2 status: " | Select-String -Pattern ".*" | ForEach-Object { $_.Line.Split(',')[0] }
    }

    # Output the job statuses for the current phase
    Write-Output "::set-output name=comp-status-phase$phase::$comp_status"
    Write-Output "::set-output name=comp-status-phase$phase-job1::$comp_status_job1"
    Write-Output "::set-output name=comp-status-phase$phase-job2::$comp_status_job2"
}
