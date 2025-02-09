param (  
    [string]$componentInputResult,
    [string]$environmentMatrixResult,
    [string]$environmentRunnerResult,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3
)

# Initialize ControllerJobStatus with all job results concatenated
$ControllerJobStatus = "job1 status: $componentInputResult job2 status: $environmentMatrixResult job3 status: $environmentRunnerResult"
Write-Host "ControllerJobStatus: $ControllerJobStatus"
Write-Output "::set-output name=Controller-Job-Status::$ControllerJobStatus"

# Output Controller job statuses individually
$jobStatuses = @(
    [PSCustomObject]@{Job = 1; Status = $componentInputResult},
    [PSCustomObject]@{Job = 2; Status = $environmentMatrixResult},
    [PSCustomObject]@{Job = 3; Status = $environmentRunnerResult}
)

foreach ($job in $jobStatuses) {
    Write-Output "::set-output name=controller-Job$($job.Job)-status::job$($job.Job) status: $($job.Status)"
}

# Handle overall phase status for all 3 phases (success or skipped)
$phaseStatuses = @()
for ($phase = 1; $phase -le 3; $phase++) {
    if ($phaseStatus -match "phase $phase status: (\S+)") {
        $phaseStatusValue = $matches[1].Trim()
    } else {
        $phaseStatusValue = "skipped"  # Default value for empty or unmatched statuses
    }

    $phaseStatuses += [PSCustomObject]@{Phase = $phase; Status = $phaseStatusValue}
    Write-Output "::set-output name=overall-job-status-phase$phase::phase $phase status: $($phaseStatusValue)"
}

# Output OverallPhaseJobStatus by concatenating all phase statuses without trailing commas
$phaseStatusStrings = @()
foreach ($status in $phaseStatuses) {
    $phaseStatusStrings += "phase $($status.Phase) status: $($status.Status)"
}
$OverallPhaseJobStatus = $phaseStatusStrings -join ", "

# Remove any unwanted trailing commas (although there shouldn't be any now)
Write-Host "OverallPhaseJobStatus: $OverallPhaseJobStatus"
Write-Output "::set-output name=OverallPhaseJobStatus::$OverallPhaseJobStatus"

# Handle component job status for all 3 phases (job1 and job2 in each phase)
$componentStatuses = @()
for ($phase = 1; $phase -le 3; $phase++) {
    $compStatus = ""
    if ($phase -eq 1) { $compStatus = $compStatusPhase1 }
    elseif ($phase -eq 2) { $compStatus = $compStatusPhase2 }
    elseif ($phase -eq 3) { $compStatus = $compStatusPhase3 }

    # Initialize component job statuses for phase 1, 2, and 3
    if ([string]::IsNullOrEmpty($compStatus)) {
        $comp_status_job1 = "job1 status: skipped"
        $comp_status_job2 = "job2 status: skipped"
    } else {
        if ($compStatus -match "job1 status: (\S+)") {
            $comp_status_job1 = "job1 status: $($matches[1].Trim())"
        } else {
            $comp_status_job1 = "job1 status: Unknown"
        }

        if ($compStatus -match "job2 status: (\S+)") {
            $comp_status_job2 = "job2 status: $($matches[1].Trim())"
        } else {
            $comp_status_job2 = "job2 status: Unknown"
        }
    }

    # Store component statuses for output
    $componentStatuses += [PSCustomObject]@{
        Phase = $phase
        Job1Status = $comp_status_job1
        Job2Status = $comp_status_job2
        CompStatus = $compStatus
    }

    # Output component job statuses for each phase
    Write-Output "::set-output name=comp-status-phase$phase::$compStatus"
    Write-Output "::set-output name=comp-status-phase$phase-job1::$comp_status_job1"
    Write-Output "::set-output name=comp-status-phase$phase-job2::$comp_status_job2"
}

# Output component job statuses for each phase in a detailed manner without trailing commas
foreach ($status in $componentStatuses) {
    # For Phase 2 and Phase 3, if status is empty or skipped, it will still show "skipped"
    $componentStatusStrings = @()
    if ($status.Job1Status -ne "") {
        $componentStatusStrings += "job1 status: $($status.Job1Status)"
    }
    if ($status.Job2Status -ne "") {
        $componentStatusStrings += "job2 status: $($status.Job2Status)"
    }
    $componentJobStatus = $componentStatusStrings -join ", "

    if ($status.Phase -eq 2 -or $status.Phase -eq 3) {
        if ($status.CompStatus -eq "") {
            Write-Host "ComponentJobStatus-for-Phase$($status.Phase): skipped"
        } else {
            Write-Host "ComponentJobStatus-for-Phase$($status.Phase): $($status.CompStatus)"
        }

        Write-Host "ComponentJobStatus-for-Phase$($status.Phase)-job1: $componentJobStatus"
    } else {
        Write-Host "ComponentJobStatus-for-Phase$($status.Phase): $($status.CompStatus)"
        Write-Host "ComponentJobStatus-for-Phase$($status.Phase)-job1: $componentJobStatus"
    }
}
