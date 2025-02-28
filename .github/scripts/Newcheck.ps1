# Input strings
$inputString = "deploy-phase-one / create-component-matrix status: success, deploy-phase-one / deploy-to-AzService status: success, deploy-phase-two / create-component-matrix status: success, deploy-phase-two / deploy-to-AzService status: success"
$phaseStatus = "check-approvals status: success, deploy-single-component status: skipped, deploy-phase-one status: success, deploy-phase-two status: success, Reset-Approvals status: success"

# Extract deploy phases (jobs starting with deploy-) from the phaseStatus string
$deployPhases = [regex]::Matches($phaseStatus, '\bdeploy-[a-zA-Z0-9-]+\b')

# Print the extracted deploy phases to see what we have
#Write-Host "Extracted deploy phases from phaseStatus:"
#$deployPhases | ForEach-Object { Write-Host $_.Value }

# Now we can proceed with the original logic to process $inputString
# Regular expression pattern to extract main job, sub-job, and status
$pattern = '([a-zA-Z0-9-]+)\s*/\s*([a-zA-Z0-9-]+)\s*status:\s*(\w+)'

# Match the pattern in the input string
$matches = [regex]::Matches($inputString, $pattern)

# Initialize a hashtable to store jobs and their corresponding sub-jobs with status
$jobDict = @{}

# Initialize a hashset to store sub-job names dynamically
$subJobSet = @{}

# Loop through the matches in the input string and organize them into the hash table
foreach ($match in $matches) {
    $mainJob = $match.Groups[1].Value
    $subJob = $match.Groups[2].Value
    $status = $match.Groups[3].Value

    # Check if the main job is already in the dictionary
    if (-not $jobDict.ContainsKey($mainJob)) {
        $jobDict[$mainJob] = @()  # Initialize an empty array for sub-jobs and status
    }

    # Create a unique entry for the sub-job and status
    $jobDict[$mainJob] += "$subJob status: $status"

    # Add the sub-job to the set for dynamic extraction
    $subJobSet[$subJob] = $true
}

# Extract just the phase names (without status) for easier checking later
$deployPhasesNames = $deployPhases | ForEach-Object { $_.Value }

# Output the grouped results and check if phase exists in $inputString
foreach ($mainJob in $deployPhasesNames) {
    Write-Host $mainJob
    
    # If the phase exists in the $jobDict, print sub-jobs with their status
    if ($jobDict.ContainsKey($mainJob)) {
        foreach ($entry in $jobDict[$mainJob]) {
            Write-Host $entry
        }
    }
    # If the phase does not exist in the $jobDict, print all dynamically extracted sub-jobs with skipped status
    else {
        foreach ($subJob in $subJobSet.Keys) {
            Write-Host "$subJob status: skipped"
        }
    }
}
