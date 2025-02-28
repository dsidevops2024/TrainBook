# Input string
$inputString = "deploy-phase-one / create-component-matrix status: success, deploy-phase-one / deploy-to-AzService status: success, deploy-phase-two / create-component-matrix status: success, deploy-phase-two / deploy-to-AzService status: success"

# Regular expression pattern to extract main job, sub-job, and status
$pattern = '([a-zA-Z0-9-]+)\s*/\s*([a-zA-Z0-9-]+)\s*status:\s*(\w+)'

# Match the pattern
$matches = [regex]::Matches($inputString, $pattern)

# Initialize a hashtable to store jobs and their corresponding sub-jobs with status
$jobDict = @{}

# Loop through the matches and organize them into the hash table
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
}

# Output the grouped results
foreach ($mainJob in $jobDict.Keys) {
    Write-Host $mainJob
    # Output each sub-job and its status under the main job
    foreach ($entry in $jobDict[$mainJob]) {
        Write-Host $entry
    }
}
