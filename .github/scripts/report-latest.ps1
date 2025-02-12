param (
    [string]$check_component_input_status,
    [string]$create_environment_matrix_status,
    [string]$set_environment_runner_status,
    [string]$phase_status,
    [string]$comp_status_phase1,
    [string]$comp_status_phase2,
    [string]$comp_status_phase3
)

$ControllerJobStatus = "check-component-input status: $check_component_input_status, "
$ControllerJobStatus += "create-environment-matrix status: $create_environment_matrix_status, "
$ControllerJobStatus += "set-environment-runner status: $set_environment_runner_status"

Write-Host "$ControllerJobStatus"
Write-Host "Controller-Job-Status=$ControllerJobStatus"

$components = @("check-component-input", "create-environment-matrix", "set-environment-runner")
foreach ($component in $components) {
    $component_status = $ControllerJobStatus -split "$component status: " | Select-String -Pattern '^.*, ' | ForEach-Object { $_.Line -split ", " | Select-Object -First 1 }
    Write-Host "$component status: $component_status"
    Write-Host "$component-status=$component status: $component_status"
}

$phases = @("check-approvals", "deploy-single-component", "deploy-phase-one", "deploy-phase-two")
foreach ($phase in $phases) {
    $phase_status_value = $phase_status -split "$phase status: " | Select-String -Pattern '^.*, ' | ForEach-Object { $_.Line -split ", " | Select-Object -First 1 }
    Write-Host "$phase status: $phase_status_value"
    Write-Host "$phase-status=$phase status: $phase_status_value"
}

$phasejobs = @("deploy-single-component", "deploy-phase-one", "deploy-phase-two")
foreach ($phase in $phasejobs) {
    if ($phase -eq "deploy-single-component") {
        $comp_status = $comp_status_phase1
    } elseif ($phase -eq "deploy-phase-one") {
        $comp_status = $comp_status_phase2
    } elseif ($phase -eq "deploy-phase-two") {
        $comp_status = $comp_status_phase3
    }

    Write-Host "$phase status: $comp_status"
    Write-Host "$phase-status=$comp_status"

    if (-not $comp_status) {
        $comp_status_job1 = "create-component-matrix status: skipped"
        $comp_status_job2 = "deploy-to-AzService status: skipped"
    } else {
        $comp_status_job1 = $comp_status -split 'create-component-matrix status: ' | Select-Object -First 1
        $comp_status_job2 = $comp_status -split 'deploy-to-AzService status: ' | Select-Object -First 1
    }

    Write-Host "$phase-job1-status=$comp_status_job1"
    Write-Host "$phase-job2-status=$comp_status_job2"
}
