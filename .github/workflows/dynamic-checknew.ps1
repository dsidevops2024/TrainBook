name: dynamic checknew
run-name: Deploy ${{ inputs.component }} to ${{ inputs.environment }}

on:
  workflow_dispatch:
    inputs:
      component:
        description: Input the component you wish to deploy. Use "fullstack" to deploy the entire app stack.
        required: true
        type: string
      environment:
        description: Select a deployment environment.
        type: choice
        options:
          - dev
          - qa
          - uat
          - prod
          - id
          - standalone
        required: true
      target_environment:
        description: "Input target environment(s) for Prod. For multiple environments input them with comma separated i.e. (env1, env2)"
        type: string
        default: 'All'
        required: false
      keep:
        description: Check to Overwrite the current AppConfig.
        type:  boolean
        required: false

permissions:
  contents: read
  id-token: write

jobs:    
  check-component-input:
    environment: ${{ inputs.environment }}
    runs-on: ubuntu-latest
    outputs:
      component: ${{ steps.component-input.outputs.component }}
    steps:
      - name: checkout code
        uses: actions/checkout@v4 
      - name: check component input 
        id: component-input
        shell: bash
        run: |
          temp="${{ inputs.component }}"
          lower=${temp,,}
          if [[ "$lower" == "fullstack" ]]; then
            echo "component=fullstack" >> $GITHUB_OUTPUT
            echo "Deploying fullstack"
          else 
            comp=`jq '.[] | .componentName' component.json | grep -i "\<${{ inputs.component }}\>" -m1`
            lowercomp=${comp,,}
            if [[ $lowercomp == "\"${lower}\"" ]]; then
              echo "Deploying `cat ./component.json | grep -iF -o "${{ inputs.component }}" -m1`"
              echo "component=`cat ./component.json | grep -iF -o "${{ inputs.component }}" -m1`" >> $GITHUB_OUTPUT
            else
              echo "Error: Component '${{ inputs.component }}' not found in component.json"
              exit 1
            fi
          fi
  create-environment-matrix:
    needs: check-component-input
    runs-on: ubuntu-latest
    outputs:
        env: ${{ steps.env-matrix.outputs.env }}
    steps:
      - name: checkout code
        uses: actions/checkout@v4  
      - name: get environment input and created matrix
        id: env-matrix
        shell: bash
        run: |
          input_envs=$(echo "${{ inputs.target_environment }}" | tr -d '[:blank:]')
          if [[ "${{ inputs.environment }}" == "prod" ]]; then
            if [[ "$input_envs" == "All" ]]; then
              echo "env=`cat ./client-manifests/${{ inputs.environment }}-clients.json | jq -c`" >> $GITHUB_OUTPUT
            else
              deploy_envs="["
              IFS=',' read -ra ENV_ARRAY <<< "$input_envs"
              for env in "${ENV_ARRAY[@]}"; do
                matching_env=$(jq -c ".[] | select(.env == \"$env\")" ./client-manifests/${{ inputs.environment }}-clients.json)
                 
                if [[ -z "$matching_env" ]]; then
                  echo "Error: No matching environment found for '$env' in ${{ inputs.environment }}-clients.json"
                  exit 1
                else
                  if [[ -z "$deploy_envs" || "$deploy_envs" == "[" ]]; then
                    deploy_envs="$deploy_envs$matching_env"
                  else
                    deploy_envs="$deploy_envs, $matching_env"
                  fi
                fi
              done
              deploy_envs="$deploy_envs]"
              echo "env=$deploy_envs" >> $GITHUB_OUTPUT
            fi
          else
            echo "env=`cat ./client-manifests/${{ inputs.environment }}-clients.json | jq -c`" >> $GITHUB_OUTPUT
          fi
  
  set-environment-runner:
    runs-on: ubuntu-latest
    outputs:
      runner: ${{ steps.env-runner.outputs.runner }}
    steps:
      - name: set runner group
        id: env-runner
        run: |
          if [[ ${{ inputs.environment }} == "prod" ]]; then
            echo "runner=Prod" >> $GITHUB_OUTPUT
          else
            echo "runner=NonProd" >> $GITHUB_OUTPUT
          fi
  call-phase:
    needs: [check-component-input, create-environment-matrix]
    uses: ./.github/workflows/deploy-phas1.yml
    with: 
      component: ${{ inputs.component }}
      environment: ${{ inputs.environment }}
      runner: ${{ inputs.runner }}

  combined-status-report:
    needs: [check-component-input, create-environment-matrix, set-environment-runner, call-phase]
    runs-on: windows-latest
    steps:
       # Step 1: Get Job Statuses from GitHub API (from collect-control-status)
      - name: Get Job Statuses from GitHub API
        id: get_status
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          $headers = @{
              "Authorization" = "Bearer $env:GITHUB_TOKEN"  # Use the GitHub token from the environment
              "Accept" = "application/vnd.github+json"
          }

          # Construct the API URL using environment variables in PowerShell
          $url = "https://api.github.com/repos/$env:GITHUB_REPOSITORY/actions/runs/$env:GITHUB_RUN_ID/jobs"
          $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

          # Extract job statuses, excluding 'combined-status-report' and jobs with 'in_progress' status
          $STATUSES = ($response.jobs | Where-Object { $_.name -ne "collect-control-status" -and $_.name -ne "combined-status-report" -and $_.conclusion -ne "in_progress" } | 
                      ForEach-Object { "$($_.name) status: $($_.conclusion)" }) -join ", "
          Write-Output "Collected statuses: $STATUSES"

          # Extract controller statuses (jobs with no slashes)
          $controllerstatus = ($STATUSES -split ", " | Where-Object { $_ -notmatch "/" }) -join ", "

          # Extract phase statuses (jobs with one slash)
          $phasejobs = ($STATUSES -split ", " | Where-Object { $_ -match '^[^/]+/[^/]+ ' }) |
                        ForEach-Object { $_ -replace '^[^/]+/([^/]+).*status: ([^ ]+)', '$1status: $2' }
          # Remove duplicates from phase jobs
          $phasejobs = $phasejobs | Select-Object -Unique
          # Join phase jobs
          $phasejobs = $phasejobs -join ", "

          # Extract component phase statuses (jobs with two slashes)
          $compStatus = ($STATUSES -split ", " | Where-Object { $_ -match '^[^/]+ /[^/]+ /' }) |
                        ForEach-Object { $_ -replace '^[^/]+ /([^/]+ /[^/]+).*status: ([^ ]+)', '$1status: $2' }
           # Join component statuses
          $compStatus = $compStatus -join ", "

          # Debug output for verification
          Write-Output "Controller Statuses: $controllerstatus"
          Write-Output "Phase Statuses: $phasejobs"
          Write-Output "CompPhase Statuses: $compStatus"
          
          # Split the compStatus string into individual items, further cleaning and organizing them by component phase
          $compStatusDict = @{}
          $compStatus -split ", " | ForEach-Object {
                $phase, $status = $_.Trim() -split 'status: '
                $phase = $phase.Trim()
                $status = $status.Trim()

          if (-not $compStatusDict.ContainsKey($phase)) {
             $compStatusDict[$phase] = @()
          }
          $compStatusDict[$phase] += $status
          }

          # Output the results to GitHub Actions output and to console
          foreach ($key in $compStatusDict.Keys) {
            $varName = "comstatus_" + ($key -replace '-', '_')
            $value = ($compStatusDict[$key] -join ', ').TrimEnd(', ')

            Write-Output "${varName}=${value}"  # Output the value for GitHub Actions
            Write-Output "${varName}: ${value}"  # Print to console
          }

          # Set GitHub Actions outputs
           Write-Output "controllerstatus=$controllerstatus" >> $env:GITHUB_OUTPUT
           Write-Output "phasejobs=$phasejobs" >> $env:GITHUB_OUTPUT
          
      - name: Debug Inputs Before Running Script
        run: |
          echo "Controller Status: ${{ steps.get_status.outputs.controllerstatus }}"
          echo "Phase Status: ${{ steps.get_status.outputs.phasejobs }}"
          #echo "Component Statuses: ${{ steps.get_status.outputs.compStatuses_values_only }}"
          echo "Component Statuses: ${{ steps.get_status.outputs.comstatus_deploy_single_component }}" , ${{ steps.get_status.outputs.comstatus_deploy_phase_one }}, ${{ steps.get_status.outputs.comstatus_deploy_phase_two }}"

       # Step 3: Run PowerShell script to report job statuses (from report-job-status)
      - name: Run PowerShell script to report job statuses
        id: report-status
        shell: pwsh
        run: |
          #$compStatuses = @(
            #"${{ steps.get_status.outputs.compStatuses_values_only }}",
            #)
          $compStatuses = @(
            "${{ steps.get_status.outputs.comstatus_deploy_single_component }}",
            "${{ steps.get_status.outputs.comstatus_deploy_phase_one }}",
            "${{ steps.get_status.outputs.comstatus_deploy_phase_two }}"
          )
          .\.github\scripts\checking.ps1 -controllerStatus "${{ steps.get_status.outputs.controllerstatus }}" `
            -phaseStatus "${{ steps.get_status.outputs.phasejobs }}" `
            #-compStatuses "${{ steps.get_status.outputs.compStatuses_values_only }}"
            -compStatuses $compStatuses

      # Step 4: Use the outputs from report-job-status (final reporting)
      - name: Use the outputs from report-job-status
        run: |
          echo "ControllerJobStatus:"
          echo "${{ steps.report-status.outputs.controller-status }}"
          echo "ControllerJob1Status:"
          echo "${{ steps.report-status.outputs.check-component-input-status }}"
          echo "ControllerJob2Status:"
          echo "${{ steps.report-status.outputs.create-environment-matrix-status }}"
          echo "ControllerJob3Status:"
          echo "${{ steps.report-status.outputs.set-environment-runner-status }}"
          echo "OverallPhaseJobStatus:"
          echo "${{ steps.report-status.outputs.overall-phase-status }}"
          echo "Overall_Job_Status_phase1:"
          echo "${{ steps.report-status.outputs.Check-Approvals_status }}"
          echo "Overall_Job_Status_phase2:"
          echo "${{ steps.report-status.outputs.deploy-single-component_status }}"
          echo "Overall_Job_Status_phase3:"
          echo "${{ steps.report-status.outputs.deploy-phase-one_status }}"
          echo "Overall_Job_Status_phase4:"
          echo "${{ steps.report-status.outputs.deploy-phase-two_status }}"


           echo "ComponentJobStatus-for-Phase2check:"
           echo "${{ steps.report-status.outputs.deploy-single-component-status }}"         
           echo "ComponentJobStatus-for-Phase2-job1-check:"
           echo "${{ steps.report-status.outputs.deploy-single-component-create-component-matrix-status }}"
           echo "ComponentJobStatus-for-Phase2-job2-check:"
           echo "${{ steps.report-status.outputs.deploy-single-component-deploy-to-AzService-status }}"        
           echo "ComponentJobStatus-for-Phase3check:"
           echo "${{ steps.report-status.outputs.deploy-phase-one-status }}"
           echo "ComponentJobStatus-for-Phase3-job1check:"
           echo "${{ steps.report-status.outputs.deploy-phase-one-create-component-matrix-status }}"
           echo "ComponentJobStatus-for-Phase3-job2check:"
           echo "${{ steps.report-status.outputs.deploy-phase-one-deploy-to-AzService-status }}"
           echo "ComponentJobStatus-for-Phase4check:"
           echo "${{ steps.report-status.outputs.deploy-phase-two-status }}"
           echo "ComponentJobStatus-for-Phase4-job1check:"
           echo "${{ steps.report-status.outputs.deploy-phase-two-create-component-matrix-status }}"
           echo "ComponentJobStatus-for-Phase4-job2check:"
           echo "${{ steps.report-status.outputs.deploy-phase-two-deploy-to-AzService-status }}"

           
           
