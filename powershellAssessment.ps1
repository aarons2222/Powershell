#LOGIN TO AZURE - DISPLAYS LOGIN DIALOG
#Select-AzureRmProfile  -Path “C:\Users\Aaron\Documents\login\azureprofile.json”
Login-AzureRmAccount

#### VARIABLES
##############

#hides green (GET) progress bars 
$ProgressPreference = 'SilentlyContinue'  

## ERROR VARIALE CREATED FOR ERROR HANDLING 
 $continue = $null

 #STORES RESOURCE GROUP NAME - ADDS A RANDOM 2 DIGITS (NUMBER/LETTER) COMBINATION
#https://technet.microsoft.com/en-us/library/ff730929.aspx
$resGroup = "rg" + -join ((48..57) + (97..100) | Get-Random -Count 2 | % {[char]$_})

#CHECK TO SEE IF RESOURCE GROUP EXISTS IF DOESNT EXIST A NEW RESOURCE GROUP IS CREATED
$resGrpChk = Get-AzureRmResourceGroup -ResourceGroupName $resGroup -ev notPresent -erroraction 'silentlycontinue'

#Service plan name
$sPlan = "SPlan1"

if (!$resGrpChk)
{  
    #CREATES A NEW RESOURCE GROUP
    New-AzureRmResourceGroup -Name $resGroup -Location "West Europe"    
    Write-Host 'The Resource Group' $resGroup ' has been created!' -fore white -back green
}
else
{
    #IF RESOURCE GROUP ALREADY EXISTS 2 RANDOMLY GENERATED DIDGETS ARE APPENDED TO THE $resGroup variable
   Write-Host 'The Resource Group' $resGroup 'already exists!!' -fore white -back red
    Write-Host ' '
   $resGroup = $resGroup + $changename
    New-AzureRmResourceGroup -Name $resGroup -Location "West Europe"
     Write-Host ' '  
     Write-Host 'Resource Group' $resGroup 'created' -fore white -back green
}
Write-host "Creating new app plan"
New-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $sPlan -Tier "Standard" -Location "West Europe" -NumberofWorkers 1 -WorkerSize small 
Set-AzureRmAppServicePlan -ResourceGroupName $resGroup -Name $sPlan 

# DEPLOY WEB APPS #

#WEB APP 1
$WebApp1 = "FirstApp" + $resGroup
$WebAppLocation1 = "Southeast Asia"

#WEB APP 2
$WebApp2 = "SecondApp" + $resGroup
$WebAppLocation2 = "South Central Us"

#check if webapps already exist
$appChk = Get-AzureRmWebApp -Name $WebApp1 
$appChk = Get-AzureRmWebApp -Name $WebApp2

#CREATE FIRST WEB APP
Write-Host 'Creating first webApp' -fore white -back DarkBlue
if (!$appChk)
{ 
New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp1 -Location $WebAppLocation1 -AppServicePlan $sPlan
}
else
{
#if webApp still exists append another random numbers on the end.  
Write-Host "webApp name already exists - creating new"
 $WebApp1 = $WebApp1 + (Get-Random -minimum 1 -maximum 9)
New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp1 -Location $WebAppLocation1 -erroraction 'silentlycontinue' -AppServicePlan $sPlan
Write-Host $WebApp1 ' CREATED' -fore white -back GREEN
}

#CREATE SECOND WEB APP
Write-Host 'Creating second webApp' -fore white -back DarkBlue
if (!$appChk)
{ 
Write-Host "Doesnt exist - Creating"
New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp2 -Location $WebAppLocation2 -AppServicePlan $sPlan
}

else
{
#if webApp still exists append another random numbers on the end. 
Write-Host "WebApp name already exists - Creating new"
 $WebApp2 = $WebApp2 + (Get-Random -minimum 1 -maximum 9)
New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp2 -Location $WebAppLocation2 -erroraction 'silentlycontinue' -AppServicePlan $sPlan 
Write-Host $WebApp2 ' CREATED' -fore white -back GREEN
}

#GET HOSTNAMES AND LAUNCHES THE URLS IN INTERNET EXPLORER
# GET HOST NAME FOR WEB APP

$host1 = Get-AzureRmWebApp -Name $WebApp1
$host2 = Get-AzureRmWebApp -Name $WebApp2
Get-AzureRmWebApp 

Write-Host ' '
$link1 = $host1.DefaultHostName
$link2 = $host2.DefaultHostName
Write-Host 'Launching ' $WebApp1 '&' $webApp2  -fore white -back green
$Browser=new-object -com internetexplorer.application
$Browser.navigate2($link1)
$Browser.navigate2($link2, 0x1000 )#launch second webapp in new tab - solution found on StackOverflow
#http://stackoverflow.com/questions/15544839/open-tab-in-existing-ie-instance
$Browser.visible=$true
Write-Host " `n"

#GETS LIST OF RUNNNING WEB APPS IN PLAN AND DISPLAY NUMBER OF WEB APPS.
$appCount = 0
Get-AzureRmResource -ResourceGroupName $resGroup -ResourceType Microsoft.Web/sites| ForEach-Object {$appCount++ }

Write-Host ""
Write-Host "Number of WebApps/Sites deployed in" $resGroup "Resource Group: " $appCount "`n`n"

#DISPLAY COUNT OF DEPLOYED APPS UNDER CURRENT PLAN
$appsInPlan = 0
Write-Host "Getting number of apps in service plan...`n" 
Start-Sleep -s 20
Get-AzureRmAppServicePlan | Select-Object -ExpandProperty NumberOfSites | ForEach-Object {$appsInPlan++ }
Write-Host "Number of apps deployed under current plan:"  $appsInPlan 
Write-Host ""
Write-Host 'Done!' -fore white -back green
Start-Sleep -s 10

##################################################
################## 2:2 CRITERIA ##################
##################################################

# Gets SQL capabilies of chosen georgaphic location
Write-Host ""
$server1Location = "East US"
$server2Location = "UK South"
$server3Location = "West Europe"

Write-Host "SQL capabilities of "$server1Location 
Get-AzureRMSqlCapability -Location $server1Location 
Write-Host ""

###### SQL SERVER LOGIN CREDENTIALS
$admin = "aaron"
$password = "Password_1234" 
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $admin, $securePassword

### SQL server names with resource group name appeneded
$server1 = "sqlserver1" + $resGroup
$server2 = "sqlserver2" + $resGroup
$server3 = "sqlserver3" + $resGroup

 #Create server 1(Server A)
<#check to see if server exists - It exists, $continue is created and passed to
if statement to append two random characters to name#>
Write-Host "Creating First SQL Server"
 
  $sqlServer = New-AzureRmSqlServer -ServerName $server1 -SqlAdministratorCredentials $creds -Location $server1Location -ResourceGroupName $resGroup -ServerVersion "12.0" -ErrorVariable continue -ErrorAction SilentlyContinue

if ($continue)
{
 do {
     $server1 = $server1 + -join ((48..57) + (97..100) | Get-Random -Count 1 | % {[char]$_})
   $sqlServer = New-AzureRmSqlServer -ServerName $server1 `
 -SqlAdministratorCredentials $creds -Location $server1Location `
 -ResourceGroupName $resGroup -ServerVersion "12.0" -ErrorVariable continue -ErrorAction SilentlyContinue
  }
  until(!$continue)

 Write-Host 'exists creating new' $server1 'Created'
}else{
Write-Host $server1 ' Created'
}
  Start-Sleep -s 2

 #Create server 2(Server B)
 <#check to see if server exists - It exists, $continue is created and passed to
if statement to append two random characters to name#>
 Write-Host "Creating Second SQL Server"
  $continue = $null
  $sqlServer = New-AzureRmSqlServer -ServerName $server2 -SqlAdministratorCredentials $creds -Location $server2Location -ResourceGroupName $resGroup -ServerVersion "12.0" -ErrorVariable continue -ErrorAction SilentlyContinue

if ($continue)
{
 do {
     $server2 = $server2 + -join ((48..57) + (97..100) | Get-Random -Count 1 | % {[char]$_})
   $sqlServer = New-AzureRmSqlServer -ServerName $server2 `
 -SqlAdministratorCredentials $creds -Location $server1Location `
 -ResourceGroupName $resGroup -ServerVersion "12.0" -ErrorVariable continue -ErrorAction SilentlyContinue
  }
  until(!$continue)

 Write-Host 'exists creating new' $server2 'Created'
}else{
Write-Host $server2 ' Created'
}

#firewall rules
#https://github.com/Microsoft/azure-docs/blob/master/articles/sql-database/sql-database-configure-firewall-settings-powershell.md

# Adds Firewall rule to Server1
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resGroup `
 -ServerName $server1 -FirewallRuleName "server1Rule" -StartIpAddress '0.0.0.0' -EndIpAddress '255.255.255.255' 
Write-Host "New Firewall rule added to" $server1  -fore white -back green `

# Adds Firewall rule to Server2
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resGroup `
 -ServerName $server2 -FirewallRuleName "server2Rule" -StartIpAddress '0.0.0.0' -EndIpAddress '255.255.255.255' 
  Write-Host "New Firewall rule added to" $server2  -fore white -back green ` 

Start-Sleep -s 2

###### DEPLOY SQL DATABASE TO SERVER A (Server1)
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

Write-Host "done!"
#Start-Sleep -s 20

####################################
########## 2:1 CRITERIA ############
####################################
#storage container
$cont = "dbbackup"
##Creates storage account
$storage = "blobstores" + $resGroup

#new storage account
Write-Host "Creating storage account"
New-AzureRmStorageAccount -ResourceGroupName $resGroup -AccountName $storage -Location "West Europe" -Type "Standard_LRS"


##create storage container
Write-Host "Creating storage container"
Set-AzureRmCurrentStorageAccount -ResourceGroupName $resGroup -StorageAccountName $storage

Get-AzureRmContext

New-AzureStorageContainer -Name $cont -Permission Off

#gets storage key
$storekey=(Get-AzureRmStorageAccountKey -Name $storage -ResourceGroupName $resGroup)[0].Value

# Database to export
$ServerName = $server1
$serverAdmin = "aaron"
$serverPassword = "Password_1234" 
$securePassword = ConvertTo-SecureString -String $serverPassword -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $serverAdmin, $securePassword

# Generate a unique filename for the BACPAC
$bacpacFilename = $Db + ".bacpac"

# Storage account info for the BACPAC
$BaseStorageUri = "https://"+$storage+".blob.core.windows.net/dbbackup/"
$BacpacUri = $BaseStorageUri + $bacpacFilename
$StorageKeytype = "StorageAccessKey"
$StorageKey = $storekey

$exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $resGroup -ServerName $ServerName `
   -DatabaseName $Db -StorageKeytype $StorageKeytype -StorageKey $StorageKey -StorageUri $BacpacUri `
   -AdministratorLogin $creds.UserName -AdministratorLoginPassword $creds.Password
$exportRequest

# Check status of the export
Write-Host "Status of backup"
Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink

######Create server 3(Server C)
<#check to see if server exists - It exists, $continue is created and passed to
if statement to append two random characters to name#>

Write-Host "Creating 3rd SQL Server"
 
  $sqlServer = New-AzureRmSqlServer -ServerName $server3 -SqlAdministratorCredentials $creds -Location $server3Location -ResourceGroupName $resGroup -ServerVersion "12.0" -ErrorVariable continue -ErrorAction SilentlyContinue

if ($continue)
{
 do {
     $server3 = $server3 + -join ((48..57) + (97..100) | Get-Random -Count 1 | % {[char]$_})
   $sqlServer = New-AzureRmSqlServer -ServerName $server3 `
 -SqlAdministratorCredentials $creds -Location $server3Location `
 -ResourceGroupName $resGroup -ServerVersion "12.0" -ErrorVariable continue -ErrorAction SilentlyContinue
  }
  until(!$continue)

 Write-Host 'exists creating new' $server3 'Created'
}else{
Write-Host $server3 ' Created'
}
  Start-Sleep -s 2

  # Adds Firewall rule to Server3
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resGroup `
 -ServerName $server3 -FirewallRuleName "server1Rule" -StartIpAddress '0.0.0.0' -EndIpAddress '255.255.255.255' 
Write-Host "New Firewall rule added to" $server3  -fore white -back green `

##import .bacpac from storage to Server3

##checks for existance of .bacpac file before continuing with import 
do{
$blobExist = Get-AzureStorageBlob -Container $cont | Select-Object -ExpandProperty Name
  sleep -s 5
  Write-Host "waiting for .bacpac"
}while(!$blobExist)

$StorageUri = "http://$storage.blob.core.windows.net/dbbackup/db1.bacpac"

$importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName $resGroup -ServerName $server3 -DatabaseName $Db -StorageKeytype $StorageKeyType -StorageKey $StorageKey -StorageUri $StorageUri -AdministratorLogin $creds.UserName -AdministratorLoginPassword $creds.Password -Edition Standard -ServiceObjectiveName S0 -DatabaseMaxSizeBytes 50000
$importRequest 

Write-Host "Status of restore"
Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink 

#https://blobstoresrg1b.blob.core.windows.net/dbbackup/

##Backup webapps to blob

#new storage

    # This returns an array of keys for your storage account. Be sure to select the appropriate key. Here we select the first key as a default.
    $storageAccountKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resGroup -Name $storage
    $context = New-AzureStorageContext -StorageAccountName $storage -StorageAccountKey $storageAccountKey[0].Value

    $sasUrl = New-AzureStorageContainerSASToken -Name $cont -Permission rwdl -Context $context -ExpiryTime (Get-Date).AddMonths(1) -FullUri

    $backup = New-AzureRmWebAppBackup -ResourceGroupName $resGroup -Name $webApp1 -StorageAccountUrl $sasUrl
    $backup = New-AzureRmWebAppBackup -ResourceGroupName $resGroup -Name $webApp2 -StorageAccountUrl $sasUrl
      
      Write-host "Creating Notification Hub Namespace"

      $namespace = "namespace" + $resGroup

      #Create new notification hub to resource group.

New-AzureRmNotificationHubsNamespace -ResourceGroup $resGroup -Location "West US" -Namespace $namespace
sleep -s 15
Write-host "Creating Notification Hub"
#Get-AzureRmNotificationHubsNamespace -ResourceGroup $resGroup -Location "West US" -Namespace $namespace
New-AzureRmNotificationHub -Namespace $namespace -ResourceGroup $resGroup -InputFile "C:\Configurations\json.json"

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

deleterg
#>


