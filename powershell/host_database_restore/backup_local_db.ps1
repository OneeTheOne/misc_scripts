$sql_server = $env:COMPUTERNAME
$systemDb = "SilverAUTSystem"
$merchantDb = "AutMerchant001"    
#$merchantStarterDb = "Merchant_SilverStarter"
$databases = @($systemDb, $merchantDb) #$merchantStarterDb
$backup_root_dir = 'C:\SQLBackups\automation_backups'
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


#getting time stamp for filename based on when the backup started
$file_time_stamp = Get-FileStamp
$file_time_stamp | Set-Content C:\SQLBackups\automation_backups\last_database_created


foreach($db in $databases){

    $db_file = $backup_root_dir +'\'+ $db + '_' + $file_time_stamp + '.bak'
    $sql_file = $sql_git_dir + $db + '.sql'
    
    logger("Saving database backup: $db"+"_"+"$file_time_stamp.bak")
    
    Backup-SqlDatabase -ServerInstance $sql_server -Database $db -BackupFile $db_file -Credential $sql_cred -Verbose
    #mssql-scripter.bat -S 10.14.19.228 -d $db -U raddbo -P '$b99#82S' --schema-and-data > $sql_file

    logger("Backup finished")
}


#commit SQL scripts to GIT repository
#$commit_message = 'SQL backup from ' + $file_time_stamp 

#logger("entering sql git directory $sql_git_dir")
#cd $sql_git_dir
#git checkout $env_git_branch
#$git_status = git status
#logger($git_status)
#git add *
#logger("committing changes")
#git commit -m $commit_message
#logger("pushing changes to the remote repository")
#git push currently not working due to access rights issues for bitbucket vs octopus tentacle user
