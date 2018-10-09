$sql_server = $env:COMPUTERNAME
$systemDb = "SilverAUTSystem"
$merchantDb = "AutMerchant001"    
#$merchantStarterDb = "Merchant_SilverStarter"
$databases = @($systemDb, $merchantDb) #$merchantStarterDb
$backup_root_dir = 'C:\SQLBackups\personal_runs'
$username = 'raddbo'
$password = ConvertTo-SecureString '$b99#82S' -AsPlainText -Force
$sql_cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password


## function to get timestmp name for backup files
function Get-FileStamp {
    return "{0:MMddyy}{0:HHmmss}" -f (Get-Date)
}


## basic console output logger functions
function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

function logger($message){

    Write-Output "$(Get-TimeStamp) $message"
}


foreach($db in $databases){

    $db_file = $backup_root_dir +'\'+ $db + '.bak'
    $sql_file = $sql_git_dir + $db + '.sql'
    
    logger("Saving database backup: $db" + ".bak")
    
    Backup-SqlDatabase -ServerInstance $sql_server -Database $db -BackupFile $db_file -Credential $sql_cred -Verbose

    logger("Backup finished")
}
