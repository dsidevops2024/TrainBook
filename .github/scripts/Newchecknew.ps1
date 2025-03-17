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
$environmentStatusCounts = @{ }
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
 
# Filter for only failure status jobs
$controllerfailureStatuses = $controllerJobStatuses -split "`n" | Where-Object { $_ -match 'status: failure' }
 
# Set output to $env:GITHUB_OUTPUT for GitHub Actions to use
$env:GITHUB_OUTPUT = "controllerJobsStatus=$($controllerJobStatuses -join "`n")"
$env:GITHUB_OUTPUT += "`ncontrollerJobsStatusCount=$($controllerStatusCountArray -join ", ")"
$env:GITHUB_OUTPUT += "`ncontrollerFailureJobsStatus=$($controllerfailureStatuses -join "`n")"
 
# Determine the overall controller status
$controllerOverallStatus = if ($controllerJobStatuses -match 'status: failure') { "failure" } else { "success" }
$env:GITHUB_OUTPUT += "`ncontrollerOverallStatus=$controllerOverallStatus"
 
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
$environmentStatusCountArray = $environmentStatusCounts.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
 
foreach ($env in $environmentStatusCounts.Keys) {
    $envStatusCountArray = $environmentStatusCounts[$env].GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
    $env:GITHUB_OUTPUT += "`n$env Jobs Status Count=$($envStatusCountArray -join ', ')"
}
 
# Iterate over the environments and clean the statuses
foreach ($environment in $environmentJobs.Keys) {
    # Clean up the job statuses for the environment
    $statusForEnvironment = $environmentJobs[$environment] -join "`n" # Join all job statuses
    $statusForEnvironment = $statusForEnvironment.TrimEnd("`n")
 
    # Clean the environment job names in parentheses to keep only the first value
    $cleanedStatuses = $statusForEnvironment -replace '\(([^,]+).*?status:', '($1) status:'
    # Set output to $env:GITHUB_OUTPUT for GitHub Actions to use
    $env:GITHUB_OUTPUT += "`n$environment Jobs Status=$cleanedStatuses"
 
    # Filter for only failure status jobs
    $failureStatuses = $cleanedStatuses -split "`n" | Where-Object { $_ -match 'status: failure' }
 
    # Set the failure status for the environment
    $env:GITHUB_OUTPUT += "`n$environment Failure Jobs Status=$($failureStatuses -join "`n")"
 
    # Determine the overall status for the environment
    $environmentOverallStatus = if ($failureStatuses.Count -gt 0) { "failure" } else { "success" }
    $env:GITHUB_OUTPUT += "`n$environment Overall Status=$environmentOverallStatus"
}
