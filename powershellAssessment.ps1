#LOGIN TO AZURE - DISPLAYS LOGIN DIALOG
Login-AzureRmAccount

# Random generator function
function rand
{
    -join ((48..57) + (97..100) | Get-Random -Count 1 | % {[char]$_})
}

#_______ VARIABLES _______#

#hides green (GET) progress bars 
$ProgressPreference = 'SilentlyContinue'  

# Error variable used for error handling
$continue = $null

# Used for spacing
$space = "`n `n"


#Stores resource group name - For uniquness the 'rand' function is used to append a random character to the name
# https://technet.microsoft.com/en-us/library/ff730929.aspx
$resGroup = "rg" + (rand)

#### WebApp variables
# WebApp names
$WebApp1 = "FirstApp" + $resGroup
$WebApp2 = "SecondApp" + $resGroup

# WebApp locations
$WebAppLocation1 = "Southeast Asia"
$WebAppLocation2 = "South Central Us"

# WebApp service plan pricing tier
$tier = "standard"


# Service plan name
$sPlan = "SPlan" + $resGroup

<# Gets path of directory the script is in - Used for outputting a JSON file later in the script 
 http://stackoverflow.com/questions/18847145/loop-through-files-in-a-directory-using-powershell #>

function Get-ScriptDirectory 
{
    if ($psise) {
        Split-Path $psise.CurrentFile.FullPath
    } else {
        $global:PSScriptRoot
    }
}


# Check to see if resource group alredy exists - If alread exists name is modified until the chose name doesnt exist
$resGrpChk = Get-AzureRmResourceGroup -ResourceGroupName $resGroup -ev notPresent -erroraction 'silentlycontinue'

if (!$resGrpChk) {  
# Creates a new resource group
    New-AzureRmResourceGroup -Name $resGroup -Location "West Europe"  -erroraction 'ignore'  
    Write-Host 'The Resource Group' $resGroup ' has been created!' -fore white -back green
    } else {
    do {
       # one randomly generated character is added to $resGroup until name doesnt exist
       Write-Host 'The Resource Group' $resGroup 'already exists - Modifying name' -fore white -back red
       Write-Host ' '
       $resGroup = $resgroup + (rand)
       New-AzureRmResourceGroup -Name $resGroup -Location "West Europe" -ErrorAction SilentlyContinue -Errorvariable continue
    }until(!$continue)
    
    Write-Host "Resource Group $resGroup created" -fore white -back green
}
$space

<# Service plan creation. Service plan with 'Standard' tier has to be created as the default service plan doesn't support backup/restore #>
# Check if the chosen name for plan exists already
$plancheck = Get-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $sPlan -erroraction 'silentlycontinue' 
if($plancheck){
    # if plan name already exists, name is modified using 'rand' until doesn't exist
    do {
        $sPlan = $sPlan + (rand)
        Write-host "Already exists - Creating new app plan"
        New-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $sPlan -Tier "Standard" -Location "North Europe" -NumberofWorkers 1 -WorkerSize small 
      #  Set-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $sPlan 
    } until(!$plancheck)
} else { 
    Write-host "Creating new app plan" 
    New-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $sPlan -Tier "Standard" -Location "North Europe"  -NumberofWorkers 1 -WorkerSize small 
   # Set-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $sPlan 
}

$space

<#_______ Create webApps _______#>

# Check if webApps exist
$appChk = Get-AzureRmWebApp -Name $WebApp1 
$appChk = Get-AzureRmWebApp -Name $WebApp2

# Create webApps
function newApp ($resGroup , $webApp , $sPlan , [string]$webAppLocation)

{   
    if (!$appChk) { 
    Write-host "Creating $webApp"
        New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp  -AppServicePlan $sPlan -Location $WebAppLocation -ErrorAction SilentlyContinue 
    } else {
   do {
        #if webApp still exists append another random numbers on the end.  
         Write-host "WebApp name '$webApp' taken - Modifying name"
         sleep -s 1
         $WebApp = $WebApp + (rand)
        New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp -AppServicePlan $sPlan -Location $WebAppLocation -ErrorAction SilentlyContinue -ErrorVariable continue 
      }until(!$continue)
   }  
    Write-Host "$WebApp  deployed" 
}

New-AzureRmWebApp -ResourceGroupName $se -Name $m -Location

# Create webApp1
newApp $resGroup $WebApp1 $sPlan $WebAppLocation1 
# Create webbApp2
newApp $resGroup $WebApp2 $sPlan $WebAppLocation2 




<# Get hostnames of webApps and launche them in a browser#>
# Get hostnames for webApps
$host1 = Get-AzureRmWebApp -Name $WebApp1
$host2 = Get-AzureRmWebApp -Name $WebApp2

# Get links (urls) for webApps 
Write-Host ' '
$link1 = $host1.DefaultHostName
$link2 = $host2.DefaultHostName


<# CHECKS IF CHROME EXISTS IN DEFAULT INSTALATION PATH - IF DOESNT EXIST WEB APPS ARE
LAUNCHED IN INTERNET EXPLORER #>

<# Check if Chrome is installed (in default location) - If not webApps are launched in Internet Explorer #>
$chromeChk = Get-Item "C:\Program Files (x86)\Google\Chrome\Application\Chrome.exe" -ErrorAction SilentlyContinue

Write-Host 'Launching $WebApp1 & $webApp2' 
if ($chromeChk)
{
    Start-Process "chrome.exe" $link1, $link2
}
else
{
    $Browser=new-object -com internetexplorer.application
    $Browser.navigate2($link1)
    $Browser.navigate2($link2, 0x1000 )#launch second webapp in new tab - solution found on StackOverflow
    #http://stackoverflow.com/questions/15544839/open-tab-in-existing-ie-instance
    $Browser.visible=$true
    $space
    Sleep -s 15
}
#DISPLAY COUNT OF DEPLOYED APPS UNDER CURRENT PLAN

Write-Host "Getting number of apps in service plan...`n" 
Start-Sleep -s 5
 
$appsInPlan = Get-AzureRmAppServicePlan -Name $sPlan | Select-Object -ExpandProperty NumberOfSites
Write-Host "Number of apps deployed under current plan:  $appsInPlan" 
$space
Start-Sleep -s 5

  #firewall rules
  #https://github.com/Microsoft/azure-docs/blob/master/articles/sql-database/sql-database-configure-firewall-settings-powershell.md
 $startIPAddress = "0.0.0.0"
 $endIPAddress = "255.255.255.255"
 $server1rule = "server1rule"
 $server2rule = "server2rule"
 $server3rule = "server3rule"

###### SQL SERVER LOGIN CREDENTIALS
$userName = "aaron"
$password = "Password1234" 

 
### SQL server names with resource group name appeneded
$server1 = "sqlserver1" + $resGroup
$server2 = "sqlserver2" + $resGroup
$server3 = "sqlserver3" + $resGroup

$serVerion = "12.0"

#Location variables
$server1Location = "East US"
$server2Location = "UK South"
$server3Location = "West Europe"


# Gets SQL capabilies of chosen georgaphic location
Write-Host "SQL capabilities of $server1Location"
Get-AzureRMSqlCapability -Location $server1Location 
$space

#________ CREATE SERVERS A,B and C _______#

  function createSQLserver ($server, $username , $password , $serverlocation  , $resGroup , $serVerion)
  {<#check to see if server exists - It exists, $continue is created and passed to
if statement to append two random characters to name#>

write-host "creating" $server
   $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
   $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword
    
    $sqlserver = New-AzureRmSqlServer -ServerName $server -SqlAdministratorCredentials $creds -Location $serverLocation -ResourceGroupName $resGroup -ServerVersion $serVerion -ErrorVariable continue -ErrorAction SilentlyContinue

     if ($continue){
     do{
     $server = $server + (rand)
     $sqlserver = New-AzureRmSqlServer -ServerName $server -SqlAdministratorCredentials $creds -Location $serverLocation -ResourceGroupName $resGroup -ServerVersion $serVerion -ErrorVariable continue -ErrorAction SilentlyContinue
     }
     until(!$continue)

     Write-Host 'exists creating new' $server 'Created'
    }else{
    Write-Host $server ' Created'
    }
    Start-Sleep -s 2   
  }

  
 function newFirewallRule ($resGroup , $server , $serverRule , $startIPAddress , $endIPAddress)
 {
  New-AzureRmSqlServerFirewallRule -ResourceGroupName $resGroup `
 -ServerName $server -FirewallRuleName $serverRule -StartIpAddress $startIPAddress -EndIpAddress $endIPAddress -ErrorAction 'SilentlyContinue' -ErrorVariable continue
 
 if($continue)
 {
    do
    {
     $serverRule = $serverRule + (rand)
      New-AzureRmSqlServerFirewallRule -ResourceGroupName $resGroup `
     -ServerName $server -FirewallRuleName $serverRule -StartIpAddress $startIPAddress -EndIpAddress $endIPAddress -ErrorAction 'SilentlyContinue' -ErrorVariable continue
 
     }until(!$continue)
    }
 }

  #Create server 1(Server A)
  createSQLserver $server1 $userName $password $server1Location $resGroup $serVerion
  #Create Firewall rules for server 1(Server A)
  newFirewallRule $resGroup $server1 $server1rule $startIPAddress $endIPAddress

  #Create server 2(Server B)
  createSQLserver $server2 $userName $password $server2Location $resGroup $serVerion
  #Create Firewall rules for server 1(Server A)
  newFirewallRule $resGroup $server2 $server2rule $startIPAddress $endIPAddress
 
Start-Sleep -s 2

#___________ DEPLOY SQL DATABASE TO SERVER1 (ServerA)___________#
 
# Create SQL Database 
$Db = "db1" 
$DbBackup = "db1backup" 
$Edition = "basic" #Options {None | Premium | Basic | Standard | DataWarehouse | Free}
$Tier = "Basic"  

Write-Host "Creating SQL database in" $server1

New-AzureRmSqlDatabase -ResourceGroupName $resGroup -ServerName $server1 -DatabaseName $Db -Edition $Edition -RequestedServiceObjectiveName $Tier

#Copy db1 from server1 accross to server2
#https://docs.microsoft.com/en-us/azure/sql-database/sql-database-copy-powershell

Write-Host "Copying" $Db "from" $server1 "over to" $server2 
New-AzureRmSqlDatabaseCopy -ResourceGroupName $resGroup -ServerName $server1 -DatabaseName $Db -CopyServerName $server2 -CopyDatabaseName $DbBackup

$space
#Start-Sleep -s 20

####################################
########## 2:1 CRITERIA ############
####################################

# Storage account name
$storage = "stores" + $resGroup

# Storage container name
$cont = "storagebackup" + $resGroup


<# Creates new storage account
https://msdn.microsoft.com/en-us/library/dn466439(v=sql.120).aspx #>

$storeExist = Get-AzureRmStorageAccount -ResourceGroupName $resGroup -AccountName $storage  -ErrorAction SilentlyContinue 

if (!$storeExist)
{
 Write-Host "Creating torage account"
 New-AzureRmStorageAccount -ResourceGroupName $resGroup -AccountName $storage -Location "West Europe" -Type "Standard_LRS" -ErrorAction SilentlyContinue -Errorvariable continue    
  
}else{
do
    {
   Write-Host "Storage account already exists - Modifying name"
    $storage = $storage + (rand)
    New-AzureRmStorageAccount -ResourceGroupName $resGroup -AccountName $storage -Location "West Europe" -Type "Standard_LRS" -ErrorAction SilentlyContinue -Errorvariable continue    
    }until(!$continue)
}


<# Creates new storage container
https://msdn.microsoft.com/en-us/library/dn466439(v=sql.120).aspx #>

Set-AzureRmCurrentStorageAccount -ResourceGroupName $resGroup -StorageAccountName $storage

Get-AzureRmContext
Write-Host "Creating storage container"

$contExist = Get-AzureStorageContainer -Name $cont 

if (!$contExist)
{
   Write-Host "Creating storage account"
   New-AzureStorageContainer -Name $cont  -Permission Off 
}else{
 do
   {
   Write-Host "Storage account already exists - Modifying name"
    $cont = $cont + (rand)
   New-AzureStorageContainer -Name $cont -Permission Off 

    }until($contExist)
}


#gets storage key
$storekey=(Get-AzureRmStorageAccountKey -Name $storage -ResourceGroupName $resGroup)[0].Value

# Database to export
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName, $securePassword

# Generate a unique filename for the BACPAC
$bacpacFilename = $Db + ".bacpac"

# Storage account info for the BACPAC
$BaseStorageUri = "https://"+$storage+".blob.core.windows.net/$cont/"
$BacpacUri = $BaseStorageUri + $bacpacFilename
$StorageKeytype = "StorageAccessKey"
$StorageKey = $storekey


$exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $resGroup -ServerName $server1 `
   -DatabaseName $Db -StorageKeytype $StorageKeytype -StorageKey $StorageKey -StorageUri $BacpacUri `
   -AdministratorLogin $creds.UserName -AdministratorLoginPassword $creds.Password
$exportRequest

# Check status of the export
Write-Host "Status of backup"
Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink

#_________________ SERVER 3 CREATION______________________#

 #Create server 3(Server 3)
  createSQLserver $server3 $userName $password $server3Location $resGroup $serVerion
#add Firewall rule to SQL server 3
 newFirewallRule $resGroup $server3 $server3rule $startIPAddress $endIPAddress
 
#_________________ IMPORT SQL TO SERVER3______________________#
 write-host "Importing SQLDB TO $server3 from blob storage"
# import .bacpac from blobstorage to Server3

# checks for existance of .bacpac file before continuing with import 
do{
$blobExist = Get-AzureStorageBlob -Container $cont | Select-Object -ExpandProperty Name -ErrorAction SilentlyContinue
  sleep -s 5
  Write-Host "waiting for .bacpac"
}while(!$blobExist)

$StorageUri = "http://$storage.blob.core.windows.net/$cont/db1.bacpac"

$importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName $resGroup -ServerName $server3 -DatabaseName $Db -StorageKeytype $StorageKeyType -StorageKey $StorageKey -StorageUri $StorageUri -AdministratorLogin $creds.UserName -AdministratorLoginPassword $creds.Password -Edition Standard -ServiceObjectiveName S0 -DatabaseMaxSizeBytes 50000
$importRequest 

Write-Host "Status of restore"
Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink 

#https://blobstoresrg1b.blob.core.windows.net/dbbackup/

# Backup webapps to blob

    # This returns an array of keys for your storage account. Be sure to select the appropriate key. Here we select the first key as a default.
    $storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resGroup -Name $storage
    $context = New-AzureStorageContext -StorageAccountName $storage -StorageAccountKey $storageAccountKey[0].Value
    $sasUrl = New-AzureStorageContainerSASToken -Name $cont -Permission rwdl -Context $context -ExpiryTime (Get-Date).AddMonths(1) -FullUri
    $backup = New-AzureRmWebAppBackup -ResourceGroupName $resGroup -Name $webApp1 -StorageAccountUrl $sasUrl
    $backup = New-AzureRmWebAppBackup -ResourceGroupName $resGroup -Name $webApp2 -StorageAccountUrl $sasUrl
      
#_______ CREATE NOTIFICATION HUB _______#

<# Gets file path of script and generates a .json file for Notification hub configuration.#> 

#function call to Get-ScriptDirectory
Get-ScriptDirectory

Write-Host " Generating .JSON file for Notification Hub Configuration `n`n"
##lOCAL FILE PARH
$currDir = Get-ScriptDirectory

$hubName = "notificationHub" + $resGroup
$hubLocation = "West US"

##JSON content for Notification Hub configuration
$jsonconfig = @{
    "Name" = $hubName
    "Location" = $hubLocation
}
$space
Sleep -s 3
$outfile = "hubconfig.json" 
Write-Host $outfile "created at $currDir"

$jsonconfig | ConvertTo-Json -depth 100 | Out-File -FilePath $outfile 

Sleep -s 3

      Write-host "Creating Notification Hub Namespace"
      
      $namespace = "hubnamespace" + $resGroup

      #Create new notification hub to resource group.
        
    $hubspaceChek = Get-AzureRmNotificationHubsNamespace -ResourceGroup $resGroup  -Namespace $namespace -ErrorVariable continue  -ErrorAction SilentlyContinue
#New-AzureRmNotificationHubsNamespace -ResourceGroup $resGroup -Location $hubLocation -Namespace $namespace

if($continue)
{
    New-AzureRmNotificationHubsNamespace -ResourceGroup $resGroup -Location $hubLocation -Namespace $namespace -ErrorAction SilentlyContinue -ErrorVariable Continue       
}
else{
 do
    {
        $namespace = $namespace + (rand)
        New-AzureRmNotificationHubsNamespace -ResourceGroup $resGroup -Location $hubLocation -Namespace $namespace -ErrorAction SilentlyContinue -ErrorVariable Continue
        }until(!$continue)}


sleep -s 15
Write-host "Creating Notification Hub"
#Get-AzureRmNotificationHubsNamespace -ResourceGroup $resGroup -Location "West US" -Namespace $namespace
New-AzureRmNotificationHub -Namespace $namespace -ResourceGroup $resGroup -InputFile $outfile 

Write-Host "Complete Sleeping for 5 minutes..."
Sleep -s 300





<#
function deleterg
{


$currentSub = Get-AzureSubscription -Current

Write-Host Script will run on the subscription Name : $currentSub.SubscriptionName Id : ($currentSub.SubscriptionId)

$resourceGroups = Get-AzureRmResourceGroup

foreach($rg in $resourceGroups)

{
    Remove-AzureRmResourceGroup -Name $rg.ResourceGroupName -Force -Verbose
}
}



#>

