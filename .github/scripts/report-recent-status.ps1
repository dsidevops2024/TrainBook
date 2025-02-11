# Get input data for job statuses
$ControllerJobStatus = "check-component-input status: $($env:check_component_input_status), "
$ControllerJobStatus += "create-environment-matrix status: $($env:create_environment_matrix_status), "
$ControllerJobStatus += "set-environment-runner status: $($env:set_environment_runner_status)"
Write-Host "$ControllerJobStatus:"
Write-Host "Controller-Job-Status=$ControllerJobStatus" | Out-File -Append -FilePath $env:GITHUB_OUTPUT

# Components list
$components = @("check-component-input", "create-environment-matrix", "set-environment-runner")
foreach ($component in $components) {
    $component_status = $ControllerJobStatus -split "$component status: " | Select-Object -Skip 1 | ForEach-Object { ($_ -split ', ')[0] }
    Write-Host "$component status: $component_status"
    Write-Host "$component-status=$component status: $component_status" | Out-File -Append -FilePath $env:GITHUB_OUTPUT
}

# Phase status
$phase_status = $env:phase_status
Write-Host "OverallPhaseJobStatus:"
Write-Host "$phase_status"
Write-Host "overall-phase-status=$phase_status" | Out-File -Append -FilePath $env:GITHUB_OUTPUT

# Phases list
$phases = @("deploy-single-component", "deploy-phase-one", "deploy-phase-two")
foreach ($phase in $phases) {
    $phase_status_value = $phase_status -split "$phase status: " | Select-Object -Skip 1 | ForEach-Object { ($_ -split ', ')[0] }
    Write-Host "$phase status: $phase_status_value"
    Write-Host "$phase`_status=$phase status: $phase_status_value" | Out-File -Append -FilePath $env:GITHUB_OUTPUT
}

# For each phase, get component status
foreach ($phase in $phases) {
    if ($phase -eq "deploy-single-component") {
        $comp_status = $env:comp_status_phase1
    } elseif ($phase -eq "deploy-phase-one") {
        $comp_status = $env:comp_status_phase2
    } elseif ($phase -eq "deploy-phase-two") {
        $comp_status = $env:comp_status_phase3
    }

    Write-Host "$phase status: $comp_status"
    Write-Host "$phase-status=$comp_status" | Out-File -Append -FilePath $env:GITHUB_OUTPUT

    if (-not $comp_status) {
        $comp_status_job1 = "create-component-matrix status: skipped"
        $comp_status_job2 = "deploy-to-AzService status: skipped"
    } else {
        $comp_status_job1 = ($comp_status -split 'create-component-matrix status: ')[1] -split ', ' | Select-Object -First 1
        $comp_status_job2 = ($comp_status -split 'deploy-to-AzService status: ')[1] -split ', ' | Select-Object -First 1
    }

    Write-Host "$phase-job1-status=$comp_status_job1" | Out-File -Append -FilePath $env:GITHUB_OUTPUT
    Write-Host "$phase-job2-status=$comp_status_job2" | Out-File -Append -FilePath $env:GITHUB_OUTPUT
}
