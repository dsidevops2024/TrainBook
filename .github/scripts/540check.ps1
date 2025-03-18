$finalStatus = "set-environment-runner status: success, kickoff-notification status: failure, check-component-input status: success, create-environment-matrix status: success, call-deploy-workflow (ds-dev) / Check-Approvals status: success, call-deploy-workflow (it-dev) / Check-Approvals status: success, call-deploy-workflow (ds-dev) / deploy-single-component status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-one / create-component-matrix status: success, call-deploy-workflow (ds-dev) / deploy-phase-one / create-vm-json status: success, call-deploy-workflow (it-dev) / deploy-single-component status: skipped, call-deploy-workflow (it-dev) / deploy-phase-one / create-vm-json status: success, call-deploy-workflow (it-dev) / deploy-phase-one / create-component-matrix status: success, call-deploy-workflow (ds-dev) / deploy-phase-one / Deploy-to-VM status: failure, call-deploy-workflow (ds-dev) / deploy-phase-one / deploy-to-AzService (SphereEngine-Dacpac, sb-dev-generic-local, main, SphereEngine-Dacpac,  , Dep... status: success, call-deploy-workflow (ds-dev) / deploy-phase-one / deploy-to-AzService (Appconfig, appsettingsreferences.json,  , Deploy-Appconfig, latest, 1, main,... status: success, call-deploy-workflow (it-dev) / deploy-phase-one / deploy-to-AzService (SphereEngine-Dacpac, sb-dev-generic-local, main, SphereEngine-Dacpac,  , Dep... status: cancelled, call-deploy-workflow (it-dev) / deploy-phase-one / deploy-to-AzService (Appconfig, appsettingsreferences.json,  , Deploy-Appconfig, latest, 1, main,... status: failure, call-deploy-workflow (it-dev) / deploy-phase-one / Deploy-to-VM status: failure, call-deploy-workflow (ds-dev) / deploy-phase-one / SaaS-Config-Prepare-Upload status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-two status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-three status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-four status: skipped, call-deploy-workflow (ds-dev) / deploy-phase-five status: skipped, call-deploy-workflow (ds-dev) / Reset-Approvals status: success, call-deploy-workflow (it-dev) / deploy-phase-one / SaaS-Config-Prepare-Upload status: skipped, call-deploy-workflow (it-dev) / deploy-phase-two status: skipped, call-deploy-workflow (it-dev) / deploy-phase-three status: skipped, call-deploy-workflow (it-dev) / deploy-phase-four status: skipped, call-deploy-workflow (it-dev) / deploy-phase-five status: skipped, call-deploy-workflow (it-dev) / Reset-Approvals status: success"

# Function to return appropriate emoji based on status
function Get-Icon($status) {
    switch ($status.ToLower()) {
        "success" { return "✅" }  # Green Checkmark
        "failure"  { return "❌" }  # Red Cross
        "skipped" { return "⚠️" }  # Skipped Icon
        "cancelled" { return "⚪" }  # Cancelled Icon
        default   { return "⚪" }  # Default Neutral Circle
    }
}

# Initialize a hashtable to collect job statuses for each environment
$environmentStatusCounts = @{}
$controllerStatusCount = @{ "success" = 0; "failure" = 0; "cancelled" = 0; "skipped" = 0 }

# Extract controller jobs that have a slash and match specific status
$controllerstatus = ($finalStatus -split ", " | Where-Object { $_ -notmatch "/" -and $_ -match "status: (success|failure|cancelled|skipped)$" }) -join ", "
$controllerJobStatuses = @()

# Extract all controller job statuses dynamically
$controllerJobs = [regex]::Matches($controllerstatus, "(?<jobName>[\w\-]+) status: (?<status>\w+)")

foreach ($match in $controllerJobs) {
    $jobName = $match.Groups["jobName"].Value
    $jobStatus = $match.Groups["status"].Value
    $icon = Get-Icon $jobStatus  # Get emoji for logs

    # Store for logging purposes (WITH emojis)
    $controllerJobStatuses += "• $jobName status: $jobStatus $icon `r`n" # Using • for bullet 

    # Increment the respective status count for controller jobs
    if ($controllerStatusCount.ContainsKey($jobStatus.ToLower())) {
        $controllerStatusCount[$jobStatus.ToLower()]++
    }
}

# Output controller status counts
$controllerStatusCountArray = $controllerStatusCount.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
$controllerStatusCountString = ($controllerStatusCountArray -join ", ")

# Set the GitHub output for Controller Jobs Status Count using echo
echo "controller_jobs_status_count=$controllerStatusCountString" >> $env:GITHUB_OUTPUT
echo "controller_jobs_status_count=$controllerStatusCountString"

# Filter for only failure status jobs
$controllerfailureStatuses = $controllerJobStatuses -split "`n" | Where-Object { $_ -match 'status: failure' }

# Output the failure statuses for this environment (if any)
if ($controllerfailureStatuses.Count -gt 0) {
    $controllerFailureJobsStatusString = $controllerfailureStatuses -join "`n"
} else {
    $controllerFailureJobsStatusString = "none"
}

# Set the GitHub output for Controller Failure Jobs Status using echo
echo "controller_failure_jobs_status=$controllerFailureJobsStatusString" >> $env:GITHUB_OUTPUT
echo "controller_failure_jobs_status=$controllerFailureJobsStatusString"

# Determine the overall controller status based on job statuses
$controllerOverallStatus = if ($controllerJobStatuses -match 'status: failure') { "failure" } else { "success" }

# Set the GitHub output for Controller Overall Status using echo
echo "controller_overall_status=$controllerOverallStatus" >> $env:GITHUB_OUTPUT
echo "controller_overall_status=$controllerOverallStatus"

# Regex pattern to match environment inside parentheses and status
$pattern = '\(([^)]+)\) /?([^:]+) status: (\w+)'

# Initialize a hashtable to collect job statuses for each environment
$environmentJobs = @{}  # Initialize as hashtable

# Extract all jobs and group them by environment (ds-dev, it-dev, etc.)
$jobs = [regex]::Matches($finalStatus, $pattern)

foreach ($match in $jobs) {
    $environment = $match.Groups[1].Value   # e.g., ds-dev, it-dev, etc.
    $jobName = $match.Groups[2].Value       # Job Name
    $status = $match.Groups[3].Value        # Status
    $icon = Get-Icon $status                # Get emoji for logs

    # Format the job status with bullet and emoji
    $jobStatus = "• $jobName status: $status $icon"

    # If the environment doesn't exist in the hashtable, create a new hashtable for status counts
    if (-not $environmentStatusCounts.ContainsKey($environment)) {
        $environmentStatusCounts[$environment] = @{ "success" = 0; "failure" = 0; "cancelled" = 0; "skipped" = 0 }
    }

    # If the environment doesn't exist in the environmentJobs hashtable, create a new list (array)
    if (-not $environmentJobs.ContainsKey($environment)) {
        $environmentJobs[$environment] = @()  # Initialize as an array
    }

    # Add the job status to the environment's list (array)
    $environmentJobs[$environment] += $jobStatus

    # Increment the respective status count for the specific environment
    if ($environmentStatusCounts[$environment].ContainsKey($status.ToLower())) {
        $environmentStatusCounts[$environment][$status.ToLower()]++
    }
}

# Output environment status counts for each environment
foreach ($env in $environmentStatusCounts.Keys) {
    $envStatusCountArray = $environmentStatusCounts[$env].GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
    echo "phase_jobs_status_count_${env}=$($envStatusCountArray -join ', ')" >> $env:GITHUB_OUTPUT
}

# Iterate over the environments and clean the statuses
foreach ($environment in $environmentJobs.Keys) {
    # Clean up the job statuses for the environment
    $statusForEnvironment = $environmentJobs[$environment] -join "`n" # Join all job statuses
    $statusForEnvironment = $statusForEnvironment.TrimEnd("`n")

    # Filter for only failure status jobs
    $failureStatuses = $statusForEnvironment -split "`n" | Where-Object { $_ -match 'status: failure' }

    # Determine the overall status for the environment
    $environmentOverallStatus = if ($failureStatuses.Count -gt 0) { "failure" } else { "success" }

    # Output the failure statuses for this environment (if any)
    $phaseFailureJobsString = if ($failureStatuses.Count -gt 0) { $failureStatuses -join "`n" } else { "none" }
    echo "phase_failure_jobs_status_${environment}=$phaseFailureJobsString" >> $env:GITHUB_OUTPUT
     echo "phase_failure_jobs_status_${environment}=$phaseFailureJobsString"

    # Set the GitHub output for Phase Job Status Count
    $phaseStatusCountArray = $environmentStatusCounts[$environment].GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
    $phaseStatusCountString = ($phaseStatusCountArray -join ", ")
    echo "phase_jobs_status_count_${environment}=$phaseStatusCountString" >> $env:GITHUB_OUTPUT
    echo "phase_jobs_status_count_${environment}=$phaseStatusCountString"

    # Set the GitHub output for Phase Job Overall Status
    echo "phase_overall_status_${environment}=$environmentOverallStatus" >> $env:GITHUB_OUTPUT
    echo "phase_overall_status_${environment}=$environmentOverallStatus"
}
