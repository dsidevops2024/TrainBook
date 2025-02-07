#!/bin/bash

# Initialize ControllerJobStatus
ControllerJobStatus="job1 status: $1, "
ControllerJobStatus+="job2 status: $2, "
ControllerJobStatus+="job3 status: $3"

# Print job statuses with each status on a new line
echo "$ControllerJobStatus:"
echo "::set-output name=Controller-Job-Status::$ControllerJobStatus"

# Loop through the jobs and dynamically extract each status
for job in 1 2 3; do
  # Use awk to correctly extract the status for each job
  job_status=$(echo "$ControllerJobStatus" | awk -v job="$job" -F"job$job status: " '{print $2}' | awk -F', ' '{print $1}')

  # Set the output for each job dynamically
  echo "::set-output name=controller-Job$job-status::job$job status: $job_status"
done

# Get phase status from input
phase_status=$4
echo "OverallPhaseJobStatus:"
echo "$phase_status"
echo "::set-output name=overall-phase-status::$phase_status"

# Loop to set phase status for 1, 2, and 3
for phase in 1 2 3; do
  phase_status_value=$(echo "$phase_status" | awk -F"phase $phase status: " '{print "phase " phase " status: " $2}' | awk -F', ' '{print $1}')
  echo "::set-output name=overall-job-status-phase$phase::$phase_status_value"
done

# Loop to handle component job status for all three phases
for phase in 1 2 3; do
  # Explicitly reference each phase
  if [ $phase -eq 1 ]; then
    comp_status=$5
  elif [ $phase -eq 2 ]; then
    comp_status=$6
  elif [ $phase -eq 3 ]; then
    comp_status=$7
  fi

  # Display component status for the current phase
  echo "ComponentJobStatus-for-Phase$phase:"
  echo "$comp_status"
  echo "::set-output name=comp-status-phase$phase::$comp_status"

  # Check if comp_status is empty (i.e., the job was skipped)
  if [ -z "$comp_status" ]; then
    comp_status_job1="job1 status: skipped"
    comp_status_job2="job2 status: skipped"
  else
    # Extract job1 and job2 statuses from the component status using awk
    comp_status_job1=$(echo "$comp_status" | awk -F'job1 status: ' '{print "job1 status: " $2}' | awk -F', ' '{print $1}' | sed 's/^ *//;s/ *$//' || echo "job1 status: not available")
    comp_status_job2=$(echo "$comp_status" | awk -F'job2 status: ' '{print "job2 status: " $2}' | awk -F', ' '{print $1}' | sed 's/^ *//;s/ *$//' || echo "job2 status: not available")
  fi

  # Output the job statuses for the current phase
  echo "::set-output name=comp-status-phase$phase-job1::$comp_status_job1"
  echo "::set-output name=comp-status-phase$phase-job2::$comp_status_job2"
done