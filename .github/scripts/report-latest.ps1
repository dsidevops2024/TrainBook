param (
    [string]$checkComponentInputStatus,
    [string]$createEnvironmentMatrixStatus,
    [string]$setEnvironmentRunnerStatus,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3
)

# Debug log for phaseStatus
Write-Host "Debug: phaseStatus is '$phaseStatus'"

# Constructing Controller Job Status
$ControllerJobStatus = "check-component-input status: $checkComponentInputStatus, "
$ControllerJobStatus += "create-environment-matrix status: $createEnvironmentMatrixStatus, "
$ControllerJobStatus += "set-environment-runner status: $setEnvironmentRunnerStatus"

# Set output for Controller_Job_Status
Add-Content -Path $env:GITHUB_OUTPUT -Value "Controller-Job-Status=$ControllerJobStatus"

$components = @("check-component-input", "create-environment-matrix", "set-environment-runner")
foreach ($component in $components) {
    $componentStatus = ($ControllerJobStatus -split "$component status: ")[1] -split ", " | Select-Object -First 1
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$component-status=$component status: $componentStatus"
}
    # Set phaseStatus as output
    Add-Content -Path $env:GITHUB_OUTPUT -Value "overall-phase-status=$phaseStatus"

# Process Phase Status
$phases = @("check-approvals", "deploy-single-component", "deploy-phase-one", "deploy-phase-two")
foreach ($phase in $phases) {
    $phaseStatusValue = ($phaseStatus -split "$phase status: ")[1] -split ", " | Select-Object -First 1
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}_status=$phase status: $phaseStatusValue"
}

$phaseJobs = @("deploy-single-component", "deploy-phase-one", "deploy-phase-two")
foreach ($phase in $phaseJobs) {
    $compStatus = if ($phase -eq "deploy-single-component") {
        $compStatusPhase1
    } elseif ($phase -eq "deploy-phase-one") {
        $compStatusPhase2
    } elseif ($phase -eq "deploy-phase-two") {
        $compStatusPhase3
    }

    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-status=$compStatus"

    if (-not $compStatus) {
        $compStatusJob1 = "create-component-matrix status: skipped"
        $compStatusJob2 = "deploy-to-AzService status: skipped"
    } else {
        # Extract full status text for each job
        $compStatusJob1 = if ($compStatus) {
            ($compStatus -split 'create-component-matrix status: ')[1] -split ", " | Select-Object -First 1
        } else {
            "create-component-matrix status: not available"
        }

        $compStatusJob2 = if ($compStatus) {
            ($compStatus -split 'deploy-to-AzService status: ')[1] -split ", " | Select-Object -First 1
        } else {
            "deploy-to-AzService status: not available"
        }
    }

    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job1-status=$compStatusJob1"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job2-status=$compStatusJob2"
}
