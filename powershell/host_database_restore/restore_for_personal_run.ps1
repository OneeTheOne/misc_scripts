clear

$error[0]|format-list -force

$sql_server = $env:COMPUTERNAME
$systemDb = "SilverAUTSystem"
$merchantDb = "AutMerchant001"    
$merchantStarterDb = "Merchant_SilverStarter"
$databases = @($systemDb, $merchantDb) #, $merchantStarterDb)
$backup_root_dir = 'C:\SQLBackups'

$username = 'raddbo'
$roleName = 'db_owner'
$plain_pwd = '$b99#82S'
$password = ConvertTo-SecureString $plain_pwd -AsPlainText -Force
$sql_cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password


#######################################
#check path and mount network drive from Dev environment if z: not mounted
if(!(Test-Path z:)){

    New-PSDrive -name "Z" -PSProvider FileSystem -Root "\\autdev01\SQLBackups" -Persist

}


#######################################
#Connect to the SQL server and kill processes connected to the databases
Add-Type -Path 'c:\Program Files (x86)\Microsoft SQL Server\100\SDK\Assemblies\Microsoft.SqlServer.Smo.dll'
Add-Type -Path 'c:\Program Files (x86)\Microsoft SQL Server\100\SDK\Assemblies\Microsoft.SqlServer.SmoExtended.dll'
$srv = new-object Microsoft.SqlServer.Management.Smo.Server $sql_server  
$srv.ConnectionContext.LoginSecure=$false; 
$srv.ConnectionContext.set_Login("raddbo"); 
$srv.ConnectionContext.set_Password('$b99#82S')


#######################################
## basic console output logger functions
function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

function logger($message){

    Write-Output "$(Get-TimeStamp) $message"
}



#######################################
#loop to restore merchant and system database
foreach($db in $databases){

    logger("Killing the processes for the database: $db")
    $srv.KillAllProcesses($db)

    logger("Dropping database: $db")
    $srv.Databases[$db].Drop()
    

    # DB and file names to be used for SQL DB relocation
    $mdf_name = $db +'.mdf'
    $mdf_path = 'd:\SQL Databases\' + $mdf_name
    $log_string = $db + '_log'
    $log_name = $log_string + '.ldf'
    $log_path = 'd:\SQL Logs\' + $log_name


    #final relocation objects
    #$RelocateData = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($db , $mdf_path)
    $RelocateData = New-Object 'Microsoft.SqlServer.Management.Smo.RelocateFile, Microsoft.SqlServer.SmoExtended, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ArgumentList $db, $mdf_path
   #$RelocateLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile($log_string , $log_path) 
    $RelocateLog = New-Object 'Microsoft.SqlServer.Management.Smo.RelocateFile, Microsoft.SqlServer.SmoExtended, Version=11.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91' -ArgumentList $log_string, $log_path


   
    #set full path to DB bak file
    $db_file = 'z:\personal_runs\' + $db + '.bak'
    
    #condition to remove timestamp from merchant starter db which remains always the same 
    #if($db -eq $merchantStarterDb){
    #    $db_file = $backup_root_dir +'\' + $db + '.bak'
    #}


    #restore database
    logger("restoring database: $db from file: $db_file")
    Restore-SqlDatabase -ServerInstance $sql_server -ReplaceDatabase -Database $db -BackupFile $db_file -Credential $sql_cred -RelocateFile @($RelocateData,$RelocateLog) -Verbose 
    logger("restore finished")
    
    
    
}


  


#######################################
#SQL queries to change allow raddbo user to login to restored database and set proper url based on the environment

#query change dbo.merchantserver to $env:COMPUTERNAME 
$query1 = "
UPDATE [SilverAUTSystem].[dbo].[MerchantDatabaseServer] 
SET [DatabaseServerName] = '" + $env:COMPUTERNAME + "' 
WHERE [MerchantDatabaseServerId] = 1"

#query change user for merchant database to raddbo
$query2 = "UPDATE [SilverAUTSystem].[dbo].[MerchantDatabase]
SET [DatabaseUserName] = '" + $username + "'
WHERE [DatabaseName] = '" + $merchantDb + "'
"

#query to change password for raddbo user on merchant db to be correct
$query3 = "UPDATE [SilverAUTSystem].[dbo].[MerchantDatabase]
SET [DatabasePassword] = '" + $plain_pwd + "'
WHERE [DatabaseName] = '" + $merchantDb + "'
"

#query to change redirection URL based on the environment
$WebServerUrl = 'https://mystore-aut01-run.ncrsilverlab.com'

if($env:COMPUTERNAME -eq 'AUTDEV01'){
    $WebServerUrl = 'https://mystore-aut01.ncrsilverlab.com'
}

$query4 = " UPDATE [SilverAUTSystem].[dbo].[SystemConfig]
SET [WebServerUrl] = '" + $WebServerUrl + "'
WHERE [SystemConfigId] = 1
"


#######################################
#final loop to run all the queries

$queries = @($query1, $query2, $query3, $query4)

foreach($query in $queries){
    logger("running query
    $query")
    Invoke-Sqlcmd -Query $query -ServerInstance $sql_server -Username $username -Password $plain_pwd -Verbose
}

