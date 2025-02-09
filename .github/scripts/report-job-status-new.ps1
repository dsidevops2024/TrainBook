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

# Output Controller job statuses individually with new job names
$jobStatuses = @(
    [PSCustomObject]@{Job = "check-component-input"; Status = $componentInputResult},
    [PSCustomObject]@{Job = "create-environment-matrix"; Status = $environmentMatrixResult},
    [PSCustomObject]@{Job = "set-environment-runner"; Status = $environmentRunnerResult}
)

foreach ($job in $jobStatuses) {
    Write-Output "::set-output name=controller-Job$($job.Job)-status::$($job.Job) status: $($job.Status)"
}

# Handle overall phase status for all 3 phases (success or skipped) with new phase names
$phaseStatuses = @()
$phaseNames = @("Firstphase", "Secondphase", "Thirdphase")

for ($phase = 1; $phase -le 3; $phase++) {
    if ($phaseStatus -match "phase $phase status: (\S+)") {
        $phaseStatusValue = $matches[1].Trim()
    } else {
        $phaseStatusValue = "skipped"  # Default value for empty or unmatched statuses
    }

    $phaseStatuses += [PSCustomObject]@{Phase = $phaseNames[$phase - 1]; Status = $phaseStatusValue}
    Write-Output "::set-output name=overall-job-status-$($phaseNames[$phase - 1])::${phaseNames[$phase - 1]} status: $($phaseStatusValue)"
}

# Output OverallPhaseJobStatus by concatenating all phase statuses with commas
$OverallPhaseJobStatus = "$($phaseStatuses[0].Phase) status: $($phaseStatuses[0].Status), $($phaseStatuses[1].Phase) status: $($phaseStatuses[1].Status), $($phaseStatuses[2].Phase) status: $($phaseStatuses[2].Status)"

# Remove any unwanted trailing commas
$OverallPhaseJobStatus = $OverallPhaseJobStatus -replace ",\s*$", ""

# Remove any extra commas if there are empty phase statuses
$OverallPhaseJobStatus = $OverallPhaseJobStatus -replace ",,", ","

Write-Host "OverallPhaseJobStatus: $OverallPhaseJobStatus"
Write-Output "::set-output name=OverallPhaseJobStatus::$OverallPhaseJobStatus"

# Handle component job status for all 3 phases (job1 and job2 in each phase) with new component names
$componentStatuses = @()
$componentNames = @("Firstcomponent", "Secondcomponent")

for ($phase = 1; $phase -le 3; $phase++) {
    $compStatus = ""
    if ($phase -eq 1) { $compStatus = $compStatusPhase1 }
    elseif ($phase -eq 2) { $compStatus = $compStatusPhase2 }
    elseif ($phase -eq 3) { $compStatus = $compStatusPhase3 }

    # Initialize component job statuses for phase 1, 2, and 3
    if ([string]::IsNullOrEmpty($compStatus)) {
        $comp_status_job1 = "${componentNames[0]} status: skipped"
        $comp_status_job2 = "${componentNames[1]} status: skipped"
    } else {
        if ($compStatus -match "job1 status: (\S+)") {
            $comp_status_job1 = "${componentNames[0]} status: $($matches[1].Trim())"
        } else {
            $comp_status_job1 = "${componentNames[0]} status: Unknown"
        }

        if ($compStatus -match "job2 status: (\S+)") {
            $comp_status_job2 = "${componentNames[1]} status: $($matches[1].Trim())"
        } else {
            $comp_status_job2 = "${componentNames[1]} status: Unknown"
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

# Output component job statuses for each phase in a detailed manner with updated component names
foreach ($status in $componentStatuses) {
    # For Phase 2 and Phase 3, if status is empty or skipped, it will still show "skipped"
    if ($status.Phase -eq "Secondphase" -or $status.Phase -eq "Thirdphase") {
        if ($status.CompStatus -eq "") {
            Write-Host "ComponentJobStatus-for-$($status.Phase): skipped"
        } else {
            Write-Host "ComponentJobStatus-for-$($status.Phase): $($status.CompStatus)"
        }

        Write-Host "ComponentJobStatus-for-$($status.Phase)-job1: $($status.Job1Status)"
        Write-Host "ComponentJobStatus-for-$($status.Phase)-job2: $($status.Job2Status)"
    } else {
        Write-Host "ComponentJobStatus-for-$($status.Phase): $($status.CompStatus)"
        Write-Host "ComponentJobStatus-for-$($status.Phase)-job1: $($status.Job1Status)"
        Write-Host "ComponentJobStatus-for-$($status.Phase)-job2: $($status.Job2Status)"
    }
}
