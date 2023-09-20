#service principal identity - make sure that this user is a Azure Connected Machine Resource Administrator
$TenantId = '<YOUR AZURE AD TENANT GUID HERE>'
$ApplicationId = '<SERVICE PRINCIPAL APP ID HERE>'
$SecurePassword = ConvertTo-SecureString -String "<SERVICE PRINCIPAL PASSWORD HERE>" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationId, $SecurePassword

Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential
$token = (Get-AzAccessToken -ResourceUrl 'https://management.azure.com').Token


#ye olde variable section(e)s
$subscriptionId = '<subscription id here>'
$resourceGroup = '<resource group of machine here>'

#arc machine variables
$machineName = '<arc machine name here>'
#in this scenario i'm assuming that the machine and the ESU license are in the same resource group - this is a choice you can make.
$machineResourceGroupName = $resourceGroup

#license variables

#region should be the same as the machine
$region = 'East US'
#Deactivated licenses will not incur billing - but will be backbilled to the start of the ESU period when Activated.
$licenseState = 'Deactivated'
$licenseTarget = 'Windows Server 2012'
#options here are Datacenter or Standard
$licenseEdition = 'Datacenter'
#options here are vCore or pCore
$licenseType = 'vCore'
#please note limits on processor counts - vCore must be at least 8, pCore must be at least 16.  Also please note licensing requirements at https://learn.microsoft.com/en-us/azure/azure-arc/servers/license-extended-security-updates
$processors = 8

#this is the generated resource id for the license - it might be helpful to name this off the machine for readability/ensure uniqueness.
$licenseResourceId = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.HybridCompute/licenses/{2}" -f $subscriptionId, $resourceGroup, $($machineName+"-ESU") 

#create an ESU license
$createLicenseUrl =  "https://management.azure.com{0}?api-version=2023-06-20-preview" -f $licenseResourceId 
$createBody = @{
    'location' = $region  
    'properties' = @{  
        'licenseDetails' = @{  
            'state' = $licenseState  
            'target' = $licenseTarget  
            "Edition" = $licenseEdition  
            "Type" = $licenseType  
            "Processors" = $processors  
        }  
    }  
}
$bodyJson = $createBody | ConvertTo-Json -Depth 3

$headers = @{
    Authorization = "Bearer $token"
}
Invoke-WebRequest -Uri $createLicenseUrl -Method Put -Body $bodyJson -Headers $headers -ContentType "application/json"


#update an ESU License
$updateLicenseUrl =  "https://management.azure.com{0}?api-version=2023-06-20-preview" -f $licenseResourceId

$licenseState = 'Activated'
$updateBody = @{
    'properties' = @{  
        'licenseDetails' = @{  
            'state' = $licenseState  
        }  
    }  
}
$bodyJson = $updateBody | ConvertTo-Json -Depth 3

$headers = @{
    Authorization = "Bearer $token"
}
Invoke-WebRequest -Uri $updateLicenseUrl -Method Patch -Body $bodyJson -Headers $headers -ContentType "application/json"
#note - we could use PUT as a method here but that would require all properties to be included.


#link to machine
$machineResourceId = (Get-AzConnectedMachine -Name $machineName -ResourceGroupName $machineResourceGroupName).Id
$linkLicenseUrl = "https://management.azure.com{0}/licenseProfiles/default?api-version=2023-06-20-preview " -f $machineResourceId
$linkBody = @{
    location = $region
    properties = @{ 
        esuProfile = @{ 
            assignedLicense = $licenseResourceId
        } 
    } 
}
$bodyJson = $linkBody | ConvertTo-Json -Depth 3
$headers = @{
    Authorization = "Bearer $token"
}
Invoke-WebRequest -Uri $linkLicenseUrl -Method PUT -Body $bodyJson -Headers $headers -ContentType "application/json"


#delete link to machine
$headers = @{
    Authorization = "Bearer $token"
}
Invoke-WebRequest -Uri $linkLicenseUrl -Method Delete -Headers $headers


#deactivate license
$updateLicenseUrl =  "https://management.azure.com{0}?api-version=2023-06-20-preview" -f $licenseResourceId

$licenseState = 'Deactivated'
$updateBody = @{
    'properties' = @{  
        'licenseDetails' = @{  
            'state' = $licenseState  
        }  
    }  
}
$bodyJson = $updateBody | ConvertTo-Json -Depth 3
$headers = @{
    Authorization = "Bearer $token"
}
Invoke-WebRequest -Uri $updateLicenseUrl -Method Patch -Body $bodyJson -Headers $headers -ContentType "application/json"


#delete license
$headers = @{
    Authorization = "Bearer $token"
}
$deleteLicenseUrl =  "https://management.azure.com{0}?api-version=2023-06-20-preview" -f $licenseResourceId
Invoke-WebRequest -Uri $deleteLicenseUrl -Method DELETE -Headers $headers
