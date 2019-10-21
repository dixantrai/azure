## Purpose: Script to DeAllocate Azure VM based on avg CPU usage for last N minutes.
## Author: Dixant Rai

## Run script below to save AZ context for automation purpose
# Enable-AzureRmContextAutosave
# Login-AzureRmAccount
# Get-AzureRmResourceGroup

Function DellocatedVMBasedOnCPUUsage($resourceGroup, $vmName, $lookBackMins)
{
    $vmId = (get-azurermvm -ResourceGroupName $resourceGroup -Name $vmName -ea silentlyContinue -WarningAction silentlyContinue).id
    $et = (get-date).ToUniversalTime()
    $st = $et.AddMinutes(-1*$lookBackMins)
    $output = Get-AzureRmMetric -ResourceId $vmId -StartTime $st -EndTime $et -TimeGrain 00:01:00 -MetricName "Percentage CPU" -ea silentlyContinue -WarningAction silentlyContinue
    # $output.Data
    $outputAvg = ($output.Data.Average | Measure-Object -Average).Average;
    # return ($Avg.Average);


    $msg = "LogTime: $et VM: $vmName in ResourceGroup: $resourceGroup has Avg CPU Usage of $outputAvg in last $lookBackMins minutes."
    Write-Host -NoNewline $msg
    
    $logFile =  "C:\Workspace\Work\git\azure\DellocatedVMBasedOnCPUUsage.txt"
    Add-Content $logFile $msg

    If ($outputAvg -gt 1.25) # if avg CPU is > 1.25%, skip
    {
        $msg = " Status: VM in use. Action: Skipping deallocation."   
        Write-Host $msg 
    }
    ElseIf ($outputAvg -eq $null) # if avg CPU is unknown, skip
    {
        $msg = " Status: Could not retrieve CPU usage. Action: Skipping deallocation."   
        Write-Host $msg

    } Else {
        Stop-AzureRmVM -ResourceGroupName $resourceGroup -Name $vmName -Force
        $msg = " Status: CPU below threshold of 1.25%. Action: Deallocating VM ... Successful."
        Write-Host $msg     
    }

    Add-Content $logFile $msg
}

## Usage 
# DellocatedVMBasedOnCPUUsage "nameResourceGroup" "nameVM1" 3
