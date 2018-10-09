$sql_server = '10.14.18.164'
$systemDb = "SilverAUTSystem"
$merchantDb = "AutMerchant001"    
#$merchantStarterDb = "Merchant_SilverStarter"
$databases = @($systemDb, $merchantDb) #$merchantStarterDb
$backup_root_dir = 'D:\SQLBackups\automation_backups'

$username = 'raddbo'
$password = ConvertTo-SecureString '$b99#82S' -AsPlainText -Force
$sql_cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password


#Connect to the SQL server and kill processes connected to the databases
Add-Type -Path 'C:\Program Files\Microsoft SQL Server\130\SDK\Assemblies\Microsoft.SqlServer.Smo.dll'
$srv = new-object Microsoft.SqlServer.Management.Smo.Server $sql_server  
$srv.ConnectionContext.LoginSecure=$false; 
$srv.ConnectionContext.set_Login("raddbo"); 
$srv.ConnectionContext.set_Password('$b99#82S')


## basic console output logger functions
function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

function logger($message){

    Write-Output "$(Get-TimeStamp) $message"
}

$last_database_created = Get-content C:\temp\last_database_created


foreach($db in $databases){

    logger("Killing the processes for the database: $db")
    $srv.KillAllProcesses($db)

    logger("Dropping database: $db")
    $srv.Databases[$db].Drop()


    $db_file = $backup_root_dir +'\' + $db + '_' + $last_database_created + '.bak'
    logger("restoring database: $db from file: $db_file")
    Restore-SqlDatabase -ServerInstance $sql_server -ReplaceDatabase -Database $db -BackupFile $db_file -Credential $sql_cred -Verbose
    logger("restore finished")
}
