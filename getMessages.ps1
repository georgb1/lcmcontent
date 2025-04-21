# vCenter FQDN
$vcHost = "cmbu-pvc-vc01.eng.vmware.com"
# vCenter Username
$vcUsername = "bgeorge.admin@sqa.local"
# vCenter Password
$vcPassword = "Dynam1c0ps"
# Aria VM name
$vraHost = "lnelson-vra-9"
# Aria VM Guest Username
$guestUser = "root"
# Aria VM Guest Password
$guestPassword = "VMware1!"
# Start Time
$startTime = "2024-05-23 14:20:00"
# Debug Mode
$debug = $true

$searchMessages = @("freeze synchronization failed","sync failed, making inconsistent snapshot")



Connect-VIServer -Server $vcHost -Protocol https -User $vcUsername -Password $vcPassword


$VM = Get-VM $vraHost


if ($debug) {
    $startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss" -AsUTC
    write-host $startTime.ToString()
    $snapName = "vRAbackuptest-" + (Get-Date -UFormat %s -Millisecond 0).ToString()
    $newSnap = New-Snapshot -VM $VM -Name $snapName -Quiesce -Description "Test Backup Snapshot"
}

$queryscript = "journalctl --identifier=vmtoolsd --no-pager --output=json --since='" + $startTime.ToString() + "'" 

$RESPONSE = Invoke-VMScript -VM $VM -ScriptText $queryscript -GuestUser $guestUser -GuestPassword $guestPassword

$ERRORFOUND = $false
if ($RESPONSE.ExitCode -eq 0) {
    $jsonstring = "[" + $RESPONSE.ScriptOutput.Replace("}`n{","},{") + "]"
    $LOGSLIST = ConvertFrom-Json -InputObject $jsonstring
    foreach ($MESSAGE in $LOGSLIST) {
        foreach ($errorMessage in $searchMessages) {
            if ($MESSAGE.MESSAGE.ToLower().Contains($errorMessage)) { 
                Write-Host $MESSAGE.MESSAGE
                $ERRORFOUND = $true
            }
        }            
    }
}


Disconnect-VIServer -Server $vcHost -Confirm:$false

if ($ERRORFOUND) {
    Write-Error "Error messages found"
    exit 1
} else {
    Write-Host "No error messages found"
    exit 0
}
