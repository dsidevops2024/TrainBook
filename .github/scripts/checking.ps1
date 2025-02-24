# Function to write the status to the GitHub output
function Write-OutputToFile {
    param (
        [string]$name,
        [string]$value
    )
    Write-Host "$name=$value"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "$name=$value"
}

# Construct the Controller Job Status using the GitHub Actions environment variables
$ControllerJobStatus = "check-component-input status: $($env:CHECK_COMPONENT_INPUT), "
$ControllerJobStatus += "create-environment-matrix status: $($env:CREATE_ENVIRONMENT_MATRIX), "
$ControllerJobStatus += "set-environment-runner status: $($env:SET_ENVIRONMENT_RUNNER)"
Write-Host "ControllerJobStatus:"
Write-Host $ControllerJobStatus
Write-OutputToFile "Controller-Job-Status" $ControllerJobStatus

# Define components
$components = @("check-component-input", "create-environment-matrix", "set-environment-runner")

# Loop through components to extract their status from the ControllerJobStatus
foreach ($component in $components) {
    $componentStatus = ($ControllerJobStatus | Select-String -Pattern "$component status: (.*?),") -replace ".*?status: (.*?),", '$1'
    Write-Host "$component status: $componentStatus"
    Write-OutputToFile "$component-status" $componentStatus
}

# Overall Phase Status
$phaseStatus = $env:PHASE_STATUS
Write-Host "OverallPhaseJobStatus:"
Write-Host $phaseStatus
Write-OutputToFile "overall-phase-status" $phaseStatus

# Define phases
$phases = @("check-approvals", "deploy-single-component", "deploy-phase-one", "deploy-phase-two")

# Loop through phases to extract their status
foreach ($phase in $phases) {
    $phaseStatusValue = ($phaseStatus | Select-String -Pattern "$phase status: (.*?),") -replace ".*?status: (.*?),", '$1'
    Write-Host "$phase status: $phaseStatusValue"
    Write-OutputToFile "${phase}_status" $phaseStatusValue
}

# Phase job statuses
$phaseJobs = @("deploy-single-component", "deploy-phase-one", "deploy-phase-two")

# Loop through phase jobs to extract their status
foreach ($phase in $phaseJobs) {
    $compStatus = ""
    if ($phase -eq "deploy-single-component") {
        $compStatus = $env:DEPLOY_SINGLE_COMPONENT_STATUS
    } elseif ($phase -eq "deploy-phase-one") {
        $compStatus = $env:DEPLOY_PHASE_ONE_STATUS
    } elseif ($phase -eq "deploy-phase-two") {
        $compStatus = $env:DEPLOY_PHASE_TWO_STATUS
    }

    Write-Host "$phase status: $compStatus"
    Write-OutputToFile "${phase}-status" $compStatus

    # Define additional job statuses within each phase
    if (-not $compStatus) {
        $compStatusJob1 = "create-component-matrix status: skipped"
        $compStatusJob2 = "deploy-to-AzService status: skipped"
    } else {
        $compStatusJob1 = ($compStatus | Select-String -Pattern "create-component-matrix status: (.*?),") -replace ".*?status: (.*?),", '$1'
        $compStatusJob2 = ($compStatus | Select-String -Pattern "deploy-to-AzService status: (.*?),") -replace ".*?status: (.*?),", '$1'
    }

    Write-Host "${phase}-job1-status=$compStatusJob1"
    Write-Host "${phase}-job2-status=$compStatusJob2"
    Write-OutputToFile "${phase}-job1-status" $compStatusJob1
    Write-OutputToFile "${phase}-job2-status" $compStatusJob2
}
