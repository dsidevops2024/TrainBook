param (
    [string]$controllerStatus,
    [string]$phaseStatus,
    [string]$compStatusPhase1,
    [string]$compStatusPhase2,
    [string]$compStatusPhase3
)

                #Controller newly added code
# Set controllerStatus as output
Add-Content -Path $env:GITHUB_OUTPUT -Value "controller-status=$controllerStatus"

$controllers = @("check-component-input", "create-environment-matrix", "set-environment-runner")
 foreach ($component in $controllers) {
    $componentStatus = ($controllerStatus -split "$component status: ")[1] -split ", " | Select-Object -First 1
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
        # Attempt to extract create-component-matrix status and deploy-to-AzService status using regex
        $compStatusJob1 = if ($compStatus -match "create-component-matrix status: (.*?)(,|$)") {
            "create-component-matrix status: $($matches[1])"
        } else {
            "create-component-matrix status: not available"
        }

        $compStatusJob2 = if ($compStatus -match "deploy-to-AzService status: (.*?)(,|$)") {
            "deploy-to-AzService status: $($matches[1])"
        } else {
            "deploy-to-AzService status: not available"
        }
    }

    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job1-status=$compStatusJob1"
    Add-Content -Path $env:GITHUB_OUTPUT -Value "${phase}-job2-status=$compStatusJob2"
}
