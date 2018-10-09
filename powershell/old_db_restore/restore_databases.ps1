$systemDb = "SilverAUTSystem"
#$merchantDb = "Merchant01"    
#$merchantStarterDb = "Merchant_SilverStarter"
$databases = @($systemDb) #$merchantStarterDb $merchantDb


#Connect to the SQL server and kill processes connected to the databases
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null 
$srv = new-object Microsoft.SqlServer.Management.Smo.Server "10.14.19.228"  
$srv.ConnectionContext.LoginSecure=$false; 
$srv.ConnectionContext.set_Login("raddbo"); 
$srv.ConnectionContext.set_Password('$b99#82S')

$processes = @($srv.enumprocesses())

foreach($db in $databases){
    $consolidated = @{}
    $proc = @($processes | Where-Object {$_.Database -eq $db})
    if($proc.Count -gt 0){
        foreach($process in $proc){
            $consolidated.Add($process.program, $process.Spid)
        }
        Write-Host "`n"
        Write-Host "Killing the following processes for the database: "$db
        $consolidated
        Write-Host "`n"
        $srv.KillAllProcesses($db)
        $srv.Databases[$db].Drop()
        $srv.Databases[$db].r
        
    }
}


#invoke-sqlcmd -ServerInstance 10.14.19.228 -Username raddbo -Password '$b99#82S' -Query "Drop database SilverAUTSystem;"
Invoke-Sqlcmd -ServerInstance 10.14.19.228 -Username raddbo -Password '$b99#82S' -InputFile .\test.sql