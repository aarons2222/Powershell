$ProgressPreference = 'SilentlyContinue'
#LOGIN TO AZURE - DISPLAYS LOGIN DIALOG
#Select-AzureRmProfile  -Path “C:\Users\Aaron\Documents\login\azureprofile.json”
Login-AzureRmAccount



## ERROR VARIALE CREATED FOR ERROR HANDLING 
 $continue = $null
#STORES RESOURCE GROUP NAME - ADDS A RANDOM 2 DIGITS (NUMBER/LETTER) COMBINATION
#https://technet.microsoft.com/en-us/library/ff730929.aspx
$resGroup = "rg" + -join ((48..57) + (97..100) | Get-Random -Count 2 | % {[char]$_})

#CHECK TO SEE IF RESOURCE GROUP EXISTS IF DOESNT EXIST A NEW RESOURCE GROUP IS CREATED
$resGrpChk = Get-AzureRmResourceGroup -ResourceGroupName $resGroup -ev notPresent -erroraction 'silentlycontinue'

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
   $resGroup = $resGroup + -join ((48..57) + (97..100) | Get-Random -Count 2 | % {[char]$_})
    New-AzureRmResourceGroup -Name $resGroup -Location "West Europe"
     Write-Host ' '  
     Write-Host 'Resource Group' $resGroup 'created' -fore white -back green
}

################### 
# DEPLOY WEB APPS #
###################

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

New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp1 -Location $WebAppLocation1 
}

else
{
#if webApp still exists append another random numbers on the end.  
Write-Host "webApp name already exists - creating new"
 $WebApp1 = $WebApp1 + (Get-Random -minimum 1 -maximum 9)
New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp1 -Location $WebAppLocation1 -erroraction 'silentlycontinue'
Write-Host $WebApp1 ' CREATED' -fore white -back GREEN
}

#CREATE SECOND WEB APP
Write-Host 'Creating second webApp' -fore white -back DarkBlue
if (!$appChk)
{ 
Write-Host "Doesnt exist - Creating"
New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp2 -Location $WebAppLocation2 
}

else
{
#if webApp still exists append another random numbers on the end. 
Write-Host "WebApp name already exists - Creating new"
 $WebApp2 = $WebApp2 + (Get-Random -minimum 1 -maximum 9)
New-AzureRmWebApp -ResourceGroupName $resGroup  -Name $WebApp2 -Location $WebAppLocation2 -erroraction 'silentlycontinue'
Write-Host $WebApp2 ' CREATED' -fore white -back GREEN
}


#GET HOSTNAMES AND LAUNCHES THE URLS IN INTERNET EXPLORER
# GET HOST NAME FOR WEB APP

$host1 = Get-AzureRmWebApp -Name $WebApp1
$host2 = Get-AzureRmWebApp -Name $WebApp2
Write-Host ' '
$link1 = $host1.DefaultHostName
$link2 = $host2.DefaultHostName
Write-Host 'Launching ' $WebApp1  -fore white -back green
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
Start-Sleep -s 15
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

Write-Host "SQL capabilities of "$server1Location 
Get-AzureRMSqlCapability -Location $server1Location 
Write-Host ""
Write-Host ""
Write-Host "SQL capabilities of "$server2Location 
Get-AzureRMSqlCapability -Location $server2Location 

###### SQL SERVER LOGIN CREDENTIALS
$admin = "aaron"
$password = "Password_1234" 
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $admin, $securePassword

### SQL server names with resource group name appeneded
$server1 = "sqlserver1" + $resGroup
$server2 = "sqlserver2" + $resGroup

 ##Server
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

 ##Server2 
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


<#firewall rules
https://github.com/Microsoft/azure-docs/blob/master/articles/sql-database/sql-database-configure-firewall-settings-powershell.md
#>

# Adds Firewall rule to Server1
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resGroup `
 -ServerName $server1 -FirewallRuleName "server1Rule" -StartIpAddress '10.10.1.1' -EndIpAddress '10.10.1.99' 
Write-Host "New Firewall rule added to" $server1  -fore white -back green `

# Adds Firewall rule to Server2
New-AzureRmSqlServerFirewallRule -ResourceGroupName $resGroup `
 -ServerName $server2 -FirewallRuleName "server2Rule" -StartIpAddress '10.11.1.1' -EndIpAddress '10.11.1.70' 
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

Start-Sleep -s 20


####################################
########## 2:1 CRITERIA ############
####################################

##Creates BLOB storage account












<#
$storageName = "storage" + $resGroup;
 
Write-Host  "- Creating storage account" -fore white -back darkblue
  
New-AzureStorageContainer -Name "blob" -Permission Off

 



##backup SQL DB to blob storage as .bacpac

$subscriptionId = "YOUR AZURE SUBSCRIPTION ID"

Login-AzureRmAccount
Set-AzureRmContext -SubscriptionId $subscriptionId

# Database to export

$ServerName =  $server1  
$serverAdmin = $admin  
$securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $serverAdmin, $securePassword







 Get-AzureStorageKey –StorageAccountName $storageName

 Write-Host  $myStoreKey 



# Generate a unique filename for the BACPAC
$bacpacFilename = $Db + (Get-Date).ToString("yyyyMMddHHmm") + ".bacpac"

# Storage account info for the BACPAC
$BaseStorageUri = "https://STORAGE-NAME.blob.core.windows.net/BLOB-CONTAINER-NAME/"
$BacpacUri = $BaseStorageUri + $bacpacFilename
$StorageKeytype = "StorageAccessKey"
$StorageKey = "YOUR STORAGE KEY"

$exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $ResourceGroupName -ServerName $ServerName `
   -DatabaseName $DatabaseName -StorageKeytype $StorageKeytype -StorageKey $StorageKey -StorageUri $BacpacUri `
   -AdministratorLogin $creds.UserName -AdministratorLoginPassword $creds.Password
$exportRequest

# Check status of the export
Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink


  

 
"Starting database backup" 
 
$StorageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey 
 



 #Create a variable to store the Storage Account name
$StorageAccount = 'savtechstoreeastus'

#Save the storage account key
$StorageKey = (Get-AzureStorageKey `
-StorageAccountName $StorageAccount).Primary

#Create a context to the storage account
$storageaccount1 = new-azurestoragecontext `
-storageaccountname $StorageAccount -storageaccountkey $StorageKey





 Get-AzureStorageAccountKey -ResourceGroupName $resGroup –StorageAccountName $storageName

 Write-Host  $myStoreKey 




###### FIRST CRITERIA ############




<#DELETES ALL RESOURCE GROUPS

$currentSub = Get-AzureSubscription -Current

Write-Host Script will run on the subscription Name : $currentSub.SubscriptionName Id : ($currentSub.SubscriptionId)

$resourceGroups = Get-AzureRmResourceGroup

foreach($rg in $resourceGroups)

{
    Remove-AzureRmResourceGroup -Name $rg.ResourceGroupName -Force -Verbose
}
#>