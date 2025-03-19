# Example final status (simulating the final status you provided)
$finalStatus = "set-environment-runner status: success, kickoff-notification status: failure, check-component-input status: success, create-environment-matrix status: success, call-deploy-workflow (ds-dev) / Check-Approvals status: success, call-deploy-workflow (it-dev) / Check-Approvals status: success, call-deploy-workflow (ds-dev) / deploy-single-component status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-one / create-component-matrix status: success, call-deploy-workflow (ds-dev) / deploy-phase-one / create-vm-json status: success, call-deploy-workflow (it-dev) / deploy-single-component status: skipped, call-deploy-workflow (it-dev) / deploy-phase-one / create-vm-json status: success, call-deploy-workflow (it-dev) / deploy-phase-one / create-component-matrix status: success, call-deploy-workflow (ds-dev) / deploy-phase-one / Deploy-to-VM status: failure, call-deploy-workflow (ds-dev) / deploy-phase-one / deploy-to-AzService (SphereEngine-Dacpac, sb-dev-generic-local, main, SphereEngine-Dacpac,  , Dep... status: success, call-deploy-workflow (ds-dev) / deploy-phase-one / deploy-to-AzService (Appconfig, appsettingsreferences.json,  , Deploy-Appconfig, latest, 1, main,... status: success, call-deploy-workflow (it-dev) / deploy-phase-one / deploy-to-AzService (SphereEngine-Dacpac, sb-dev-generic-local, main, SphereEngine-Dacpac,  , Dep... status: cancelled, call-deploy-workflow (it-dev) / deploy-phase-one / deploy-to-AzService (Appconfig, appsettingsreferences.json,  , Deploy-Appconfig, latest, 1, main,... status: failure, call-deploy-workflow (it-dev) / deploy-phase-one / Deploy-to-VM status: failure, call-deploy-workflow (ds-dev) / deploy-phase-one / SaaS-Config-Prepare-Upload status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-two status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-three status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-four status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-five status: skipped, call-deploy-workflow (ds-dev) / Reset-Approvals status: success, call-deploy-workflow (it-dev) / deploy-phase-one / SaaS-Config-Prepare-Upload status: skipped, call-deploy-workflow (it-dev) / deploy-phase-two status: skipped, call-deploy-workflow (it-dev) / deploy-phase-three status: skipped, call-deploy-workflow (it-dev) / deploy-phase-four status: skipped, call-deploy-workflow (it-dev) / deploy-phase-five status: skipped, call-deploy-workflow (it-dev) / Reset-Approvals status: success"

# Function to return appropriate emoji based on status
function Get-Icon($status) {
    switch ($status.ToLower()) {
        "success" { return "✅" }
        "failure"  { return "❌" }
        "skipped" { return "⚠️" }
        "cancelled" { return "⚪" }
        default   { return "⚪" }
    }
}

# Initialize hashtable for controller jobs and status counts
$controllerStatusCount = @{ "success" = 0; "failure" = 0; "cancelled" = 0; "skipped" = 0 }
$controllerJobStatuses = @()

# Extract controller job statuses (no slashes in the job name)
$controllerstatus = ($finalStatus -split ", " | Where-Object { $_ -notmatch "/" -and $_ -match "status: (success|failure|cancelled|skipped)$" }) -join ", "

# Extract all controller job statuses dynamically
$controllerJobs = [regex]::Matches($controllerstatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")

foreach ($match in $controllerJobs) {
    $jobName = $match.Groups["jobName"].Value
    $jobStatus = $match.Groups["status"].Value
    $icon = Get-Icon $jobStatus  # Get emoji for logs

    # Store for logging purposes (WITH emojis)
    $controllerJobStatuses += "• $jobName status: $jobStatus $icon `r`n" 

    # Increment respective status count for controller jobs
    if ($controllerStatusCount.ContainsKey($jobStatus.ToLower())) {
        $controllerStatusCount[$jobStatus.ToLower()]++
    }
}

# Collect controller jobs' status counts
$controllerStatusCountArray = $controllerStatusCount.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
$controllerStatusCountString = ($controllerStatusCountArray -join ", ")

# Collect failed controller jobs
$controllerFailureStatuses = $controllerJobStatuses -split "`n" | Where-Object { $_ -match 'status: failure' }
if ($controllerFailureStatuses.Count -gt 0) {
    $controllerFailureJobsStatusString = $controllerFailureStatuses -join "`n"
} else {
    $controllerFailureJobsStatusString = "none"
}

# Determine overall controller status (failure if any failure exists)
$controllerOverallStatus = if ($controllerJobStatuses -match 'status: failure') { "failure" } else { "success" }

# Initialize collections for phase jobs' status
$environmentStatusCounts = @{ }
$environmentJobs = @{ }
$pattern = '\(([^)]+)\) /?([^:]+) status: (\w+)'

$jobs = [regex]::Matches($finalStatus, $pattern)

foreach ($match in $jobs) {
    $environment = $match.Groups[1].Value
    $jobName = $match.Groups[2].Value
    $status = $match.Groups[3].Value
    $icon = Get-Icon $status

    # Format the job status with bullet and emoji
    $jobStatus = "• $jobName status: $status $icon"

    # Add job status to the respective environment
    if (-not $environmentStatusCounts.ContainsKey($environment)) {
        $environmentStatusCounts[$environment] = @{ "success" = 0; "failure" = 0; "cancelled" = 0; "skipped" = 0 }
    }

    if (-not $environmentJobs.ContainsKey($environment)) {
        $environmentJobs[$environment] = @()
    }

    $environmentJobs[$environment] += $jobStatus

    if ($environmentStatusCounts[$environment].ContainsKey($status.ToLower())) {
        $environmentStatusCounts[$environment][$status.ToLower()]++
    }
}

# Collect Phase-Jobs Status Count into output
$output = "Phase-Jobs Status Count:`n"
foreach ($env in $environmentStatusCounts.Keys) {
    $envStatusCountArray = $environmentStatusCounts[$env].GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
    $output += "${env}: $($envStatusCountArray -join ', ')`n"
}

# Collect failed job statuses for each environment into output
foreach ($environment in $environmentJobs.Keys) {
    $statusForEnvironment = $environmentJobs[$environment] -join "`n"
    $statusForEnvironment = $statusForEnvironment.TrimEnd("`n")

    $cleanedStatuses = $statusForEnvironment -replace '\(([^,]+).*?status:', '($1) status:'
    $failureStatuses = $cleanedStatuses -split "`n" | Where-Object { $_ -match 'status: failure' }

    $environmentOverallStatus = if ($failureStatuses.Count -gt 0) { 
        "failure" 
    } else { 
        "success" 
    }

    if ($failureStatuses.Count -gt 0) {
        $output += "$environment Failed Jobs:`n"
        $failureStatuses | ForEach-Object { $output += "$_`n" }
    } else {
        $output += "$environment Failed Jobs: none`n"
    }

    $output += "$environment Overall Status: $environmentOverallStatus`n"
}

# Combine controller job outputs with phase job outputs into one final output
$output = $output.Trim()

# Add controller jobs' status counts, failure statuses, and overall status to final output
$output = "Controller Jobs Status Count:`n$controllerStatusCountString`n" + `
          "Controller Failure Jobs:`n$controllerFailureJobsStatusString`n" + `
          "Controller Overall Status: $controllerOverallStatus`n`n" + $output

# Set the collected output as GitHub Actions output using $env:GITHUB_OUTPUT
#$env:GITHUB_OUTPUT = "job_status=$output"
#Write-Host "Final Output for GitHub:"
#Write-Host $output

# Write the output to the GITHUB_OUTPUT file
#echo "job_status=$output" >> $GITHUB_OUTPUT
echo "job_status=$output" >> $env:GITHUB_OUTPUT

Write-Host "Final Output for GitHub:"
Write-Host $output
