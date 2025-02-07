# Initialize ControllerJobStatus
$ControllerJobStatus = "job1 status: $args[0], "
$ControllerJobStatus += "job2 status: $args[1], "
$ControllerJobStatus += "job3 status: $args[2]"

# Print job statuses with each status on a new line
Write-Host $ControllerJobStatus
Write-Host "::set-output name=Controller-Job-Status::$ControllerJobStatus"

# Loop through the jobs and dynamically extract each status
for ($job = 1; $job -le 3; $job++) {
    # Extract the job status for each job using regex
    $job_status = ($ControllerJobStatus -replace ".*job$job status: (.*?),.*", '$1').Trim()

    # Set the output for each job dynamically
    Write-Host "::set-output name=controller-Job$job-status::job$job status: $job_status"
}

# Get phase status from input
$phase_status = $args[3]
Write-Host "OverallPhaseJobStatus:"
Write-Host $phase_status
Write-Host "::set-output name=overall-phase-status::$phase_status"

# Loop to set phase status for 1, 2, and 3
for ($phase = 1; $phase -le 3; $phase++) {
    $phase_status_value = ($phase_status -replace ".*phase $phase status: (.*?),.*", '$1').Trim()
    Write-Host "::set-output name=overall-job-status-phase$phase::$phase_status_value"
}

# Loop to handle component job status for all three phases
for ($phase = 1; $phase -le 3; $phase++) {
    # Explicitly reference each phase
    if ($phase -eq 1) {
        $comp_status = $args[4]
    } elseif ($phase -eq 2) {
        $comp_status = $args[5]
    } elseif ($phase -eq 3) {
        $comp_status = $args[6]
    }

    # Display component status for the current phase
    Write-Host "ComponentJobStatus-for-Phase$phase:"
    Write-Host $comp_status
    Write-Host "::set-output name=comp-status-phase$phase::$comp_status"

    # Check if comp_status is empty (i.e., the job was skipped)
    if ([string]::IsNullOrEmpty($comp_status)) {
        $comp_status_job1 = "job1 status: skipped"
        $comp_status_job2 = "job2 status: skipped"
    } else {
        # Extract job1 and job2 statuses from the component status using regex
        $comp_status_job1 = ($comp_status -replace ".*job1 status: (.*?),.*", 'job1 status: $1').Trim()
        $comp_status_job2 = ($comp_status -replace ".*job2 status: (.*?),.*", 'job2 status: $1').Trim()
        
        # If not found, set default values
        if ([string]::IsNullOrEmpty($comp_status_job1)) {
            $comp_status_job1 = "job1 status: not available"
        }
        if ([string]::IsNullOrEmpty($comp_status_job2)) {
            $comp_status_job2 = "job2 status: not available"
        }
    }

    # Output the job statuses for the current phase
    Write-Host "::set-output name=comp-status-phase$phase-job1::$comp_status_job1"
    Write-Host "::set-output name=comp-status-phase$phase-job2::$comp_status_job2"
}

