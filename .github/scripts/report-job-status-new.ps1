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
$ControllerJobStatus = "check-component-input status: $componentInputResult, create-environment-matrix status: $environmentMatrixResult, set-environment-runner status: $environmentRunnerResult"
Write-Host "ControllerJobStatus: $ControllerJobStatus"
Write-Output "::set-output name=Controller-Job-Status::$ControllerJobStatus"

# Output Controller job statuses individually with job names
$jobStatuses = @(
    [PSCustomObject]@{Job = 'check-component-input'; Status = $componentInputResult},
    [PSCustomObject]@{Job = 'create-environment-matrix'; Status = $environmentMatrixResult},
    [PSCustomObject]@{Job = 'set-environment-runner'; Status = $environmentRunnerResult}
)

foreach ($job in $jobStatuses) {
    Write-Host "$($job.Job) Status: $($job.Status)"
    Write-Output "::set-output name=controller-$($job.Job)-status::$($job.Status)"
}
# Handle overall phase status for all 3 phases (success or skipped)
$phaseStatuses = @()
for ($phase = 1; $phase -le 3; $phase++) {
    if ($phaseStatus -match "Firstphase status: (\S+)") {
        $phaseStatusValue = $matches[1].Trim()
    } elseif ($phaseStatus -match "Secondphase status: (\S+)") {
        $phaseStatusValue = $matches[1].Trim()
    } elseif ($phaseStatus -match "Thirdphase status: (\S+)") {
        $phaseStatusValue = $matches[1].Trim()
    } else {
        $phaseStatusValue = "skipped"  # Default value for empty or unmatched statuses
    }

    $phaseStatuses += [PSCustomObject]@{Phase = $phase; Status = $phaseStatusValue}
    Write-Output "::set-output name=overall-job-status-phase$phase::phase$phase status: $($phaseStatusValue)"
}

# Output OverallPhaseJobStatus by concatenating all phase statuses with commas
$OverallPhaseJobStatus = "Firstphase status: $($phaseStatuses[0].Status), Secondphase status: $($phaseStatuses[1].Status), Thirdphase status: $($phaseStatuses[2].Status)"

# Remove any unwanted trailing commas
$OverallPhaseJobStatus = $OverallPhaseJobStatus -replace ",\s*$", ""

# Remove any extra commas if there are empty phase statuses
$OverallPhaseJobStatus = $OverallPhaseJobStatus -replace ",,", ","

Write-Host "OverallPhaseJobStatus: $OverallPhaseJobStatus"
Write-Output "::set-output name=OverallPhaseJobStatus::$OverallPhaseJobStatus"

# Handle component job status for all 3 phases (job1 and job2 in each phase)
$componentStatuses = @()
for ($phase = 1; $phase -le 3; $phase++) {
    $compStatus = ""
    if ($phase -eq 1) { $compStatus = $compStatusPhase1 }
    elseif ($phase -eq 2) { $compStatus = $compStatusPhase2 }
    elseif ($phase -eq 3) { $compStatus = $compStatusPhase3 }

    # Print the processing status for the current phase
    Write-Host "Processing Component for Phase ${phase}: $compStatus"

    # Initialize component job statuses for phase 1, 2, and 3
    if ([string]::IsNullOrEmpty($compStatus)) {
        $comp_status_job1 = "Firstcomponent status: skipped"
        $comp_status_job2 = "Secondcomponent status: skipped"
    } else {
        if ($compStatus -match "job1 status: (\S+)") {
            $comp_status_job1 = "Firstcomponent status: $($matches[1].Trim())"
        } else {
            $comp_status_job1 = "Firstcomponent status: Unknown"
        }

        if ($compStatus -match "job2 status: (\S+)") {
            $comp_status_job2 = "Secondcomponent status: $($matches[1].Trim())"
        } else {
            $comp_status_job2 = "Secondcomponent status: Unknown"
        }
    }

    # Store component statuses for output
    $componentStatuses += [PSCustomObject]@{
        Phase = $phase
        Job1Status = $comp_status_job1
        Job2Status = $comp_status_job2
        CompStatus = $compStatus
    }

    Write-Output "::set-output name=comp-status-phase$phase::$compStatus"
    Write-Output "::set-output name=comp-status-phase$phase-job1::$comp_status_job1"
    Write-Output "::set-output name=comp-status-phase$phase-job2::$comp_status_job2"
}

# Output component job statuses for each phase in a detailed manner
foreach ($status in $componentStatuses) {
    # For Phase 2 and Phase 3, if status is empty or skipped, it will still show "skipped"
    if ($status.Phase -eq 2 -or $status.Phase -eq 3) {
        if ($status.CompStatus -eq "") {
            Write-Host "ComponentJobStatus-for-Phase$($status.Phase): skipped"
        } else {
            Write-Host "ComponentJobStatus-for-Phase$($status.Phase): $($status.CompStatus)"
        }

        Write-Host "ComponentJobStatus-for-Phase$($status.Phase)-job1: $($status.Job1Status)"
        Write-Host "ComponentJobStatus-for-Phase$($status.Phase)-job2: $($status.Job2Status)"
    } else {
        Write-Host "ComponentJobStatus-for-Phase$($status.Phase): $($status.CompStatus)"
        Write-Host "ComponentJobStatus-for-Phase$($status.Phase)-job1: $($status.Job1Status)"
        Write-Host "ComponentJobStatus-for-Phase$($status.Phase)-job2: $($status.Job2Status)"
    }
}
