param (
    [string]$check_component_input_status,
    [string]$create_environment_matrix_status,
    [string]$set_environment_runner_status,
    [string]$phase_status,
    [string]$comp_status_phase1,
    [string]$comp_status_phase2,
    [string]$comp_status_phase3
)

# Generate the Controller Job Status
$ControllerJobStatus = "check-component-input status: $check_component_input_status, "
$ControllerJobStatus += "create-environment-matrix status: $create_environment_matrix_status, "
$ControllerJobStatus += "set-environment-runner status: $set_environment_runner_status"

Write-Host "$ControllerJobStatus"
Write-Host "Controller-Job-Status=$ControllerJobStatus"

# Process component statuses
$components = @("check-component-input", "create-environment-matrix", "set-environment-runner")
foreach ($component in $components) {
    $component_status = $ControllerJobStatus -split "$component status: " | Select-String -Pattern '^.*, ' | ForEach-Object { $_.Line -split ", " | Select-Object -First 1 }
    Write-Host "$component status: $component_status"
    Write-Host "$component-status=$component status: $component_status"
}

# Process phase statuses
$phases = @("check-approvals", "deploy-single-component", "deploy-phase-one", "deploy-phase-two")
foreach ($phase in $phases) {
    $phase_status_value = $phase_status -split "$phase status: " | Select-String -Pattern '^.*, ' | ForEach-Object { $_.Line -split ", " | Select-Object -First 1 }
    Write-Host "$phase status: $phase_status_value"
    Write-Host "$phase-status=$phase status: $phase_status_value"
}

# Process component statuses for each phase
$phasejobs = @("deploy-single-component", "deploy-phase-one", "deploy-phase-two")
foreach ($phase in $phasejobs) {
    # Assign the corresponding phase status for each phase job
    if ($phase -eq "deploy-single-component") {
        $comp_status = $comp_status_phase1
    } elseif ($phase -eq "deploy-phase-one") {
        $comp_status = $comp_status_phase2
    } elseif ($phase -eq "deploy-phase-two") {
        $comp_status = $comp_status_phase3
    }

    Write-Host "$phase status: $comp_status"
    Write-Host "$phase-status=$comp_status"

    # If there is no component status, set default skipped values for job 1 and job 2
    if (-not $comp_status) {
        $comp_status_job1 = "create-component-matrix status: skipped"
        $comp_status_job2 = "deploy-to-AzService status: skipped"
    } else {
        # Split comp_status to get the specific job statuses
        $comp_status_job1 = ($comp_status -split 'create-component-matrix status: ')[1] -split ',' | Select-Object -First 1
        $comp_status_job2 = ($comp_status -split 'deploy-to-AzService status: ')[1] -split ',' | Select-Object -First 1
    }

    Write-Host "$phase-job1-status=$comp_status_job1"
    Write-Host "$phase-job2-status=$comp_status_job2"
}
