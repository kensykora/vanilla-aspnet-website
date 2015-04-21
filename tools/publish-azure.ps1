Param(
	[Parameter(Mandatory = $true, Position=1)]
	[String]$WebDeployPackagePath,
	[Parameter(Mandatory = $true, Position=2)]
	[String]$WebsiteName,
	[Parameter(Mandatory = $false)]
	[String]$WebsiteSlot, 
	[Parameter(Mandatory = $False)]
	[String]$SubscriptionName,
	[Parameter(Mandatory = $false)]
	[Switch]$Create
)

Write-Verbose "[Start] Deploying site package"
$ErrorActionPreference = "Stop"

$WebsiteName = $WebsiteName.ToLower()

function Select-AzureAccount() {

	if(-not $env:AZURE_LOGIN) {
		throw "Environment Variable AZURE_LOGIN not set";
	}
	if(-not $env:AZURE_PASSWORD) {
		throw "Environment Variable AZURE_PASSWORD not set";
	}
	
	Write-Verbose "Looking up Azure account info"
	$securePassword = ConvertTo-SecureString -String $env:AZURE_PASSWORD -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential($env:AZURE_LOGIN, $securePassword)
	
    Add-AzureAccount -Credential $cred
    $azureAccount = Get-AzureAccount

	Write-Verbose ("Found {0}" -f $azureAccount[0].Id)

	#Get the Subscription
	$subscriptions = Get-AzureSubscription

	if($subscriptions.Count -gt 1 -and (-not $SubscriptionName)) {
		Write-Warning "Account contains multiple subscriptions, but no subscription name was provided. Using the first subscription."
		$SubscriptionName = $subscriptions[0].SubscriptionName
	} else {
		$subscriptions = $subscriptions | Where { $_.SubscriptionName -eq $SubscriptionName }
		if($subscriptions.Count -ne 1) {
			throw "Unable to find subscription $SubscriptionName on account $AzureLogin"
		}
	} 
	Write-Verbose "Found ${SubscriptionName}"
	Select-AzureSubscription -SubscriptionName $SubscriptionName -Default
}

function New-SWRandomPassword {
    [CmdletBinding(ConfirmImpact='Low')]
    [OutputType([String])]
    Param
    (
        # Specifies minimum password length
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [ValidateScript({$_ -gt 0})]
        [Alias("Min")] 
        [int]$MinPasswordLength = 8,
        
        # Specifies maximum password length
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1)]
        [ValidateScript({$_ -ge $MinPasswordLength})]
        [Alias("Max")]
        [int]$MaxPasswordLength = 12,
        
        # Specifies an array of strings containing charactergroups from which the password will be generated.
        # At least one char from each group (string) will be used.
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2)]
        [String[]]$InputStrings = @('abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', '0123456789', '!#%&'),
        
        # Specifies number of passwords to generate.
        [Parameter(Mandatory=$false, 
                   ValueFromPipeline=$false,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=3)]
        [ValidateScript({$_ -gt 0})]
        [int]$Count = 1
    )
    Begin {
        Function Get-Seed{
            # Generate a seed for future randomization
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            $Random.GetBytes($RandomBytes)
            [BitConverter]::ToInt32($RandomBytes, 0)
        }
    }
    Process {
        For($iteration = 1;$iteration -le $Count; $iteration++){
            # Create char arrays containing possible chars
            [char[][]]$CharGroups = $InputStrings

            # Set counter of used groups
            [int[]]$UsedGroups = for($i=0;$i -lt $CharGroups.Count;$i++){0}



            # Create new char-array to hold generated password
            if($MinPasswordLength -eq $MaxPasswordLength) {
                # If password length is set, use set length
                $password = New-Object -TypeName 'System.Char[]' $MinPasswordLength
            }
            else {
                # Otherwise randomize password length
                $password = New-Object -TypeName 'System.Char[]' (Get-Random -SetSeed $(Get-Seed) -Minimum $MinPasswordLength -Maximum $($MaxPasswordLength+1))
            }

            for($i=0;$i -lt $password.Length;$i++){
                if($i -ge ($password.Length - ($UsedGroups | Where-Object {$_ -eq 0}).Count)) {
                    # Check if number of unused groups are equal of less than remaining chars
                    # Select first unused CharGroup
                    $CharGroupIndex = 0
                    while(($UsedGroups[$CharGroupIndex] -ne 0) -and ($CharGroupIndex -lt $CharGroups.Length)) {
                        $CharGroupIndex++
                    }
                }
                else {
                    #Select Random Group
                    $CharGroupIndex = Get-Random -SetSeed $(Get-Seed) -Minimum 0 -Maximum $CharGroups.Length
                }

                # Set current position in password to random char from selected group using a random seed
                $password[$i] = Get-Random -SetSeed $(Get-Seed) -InputObject $CharGroups[$CharGroupIndex]
                # Update count of used groups.
                $UsedGroups[$CharGroupIndex] = $UsedGroups[$CharGroupIndex] + 1
            }
            Write-Output -InputObject $($password -join '')
        }
    }
}

if($Create) {
	Switch-AzureMode AzureResourceManager | Out-Null
	Select-AzureAccount
	
	$pass = New-SWRandomPassword -MinPasswordLength 8 -MaxPasswordLength 8
	
	$resourceGroup = New-AzureResourceGroup `
		-Name "$WebsiteName-resource" `
		-TemplateFile "${env:APPVEYOR_BUILD_FOLDER}\tools\WebSiteSQLDatabase.json"`
		-Location "North Central US" `
        -StorageAccountName "kmstemp" `
		-TemplateParameterObject @{
			sku="Standard";
			edition="Standard";
			siteName=$WebsiteName;
			hostingPlanName="$WebsiteName-plan";
			siteLocation="North Central US";
			serverName="$WebsiteName-sqlserver";
			serverLocation="North Central US";
			administratorLogin="$WebsiteName-user";
			administratorLoginPassword="$pass";
			databaseName="$WebsiteName-sqldb"
		} `
		-Verbose -Force
	
	Switch-AzureMode AzureServiceManagement | Out-Null
	
	$connString  = ("Server=tcp:{0}.database.windows.net,1433;Database={1};" `
				 + "User ID={2}@{0};Password={3};Trusted_Connection=False;Encrypt=True;Connection Timeout=30;") `
				 -f "$WebsiteName-sqlserver", "$WebsiteName-sqldb", "$WebsiteName-user", $pass
				 
	$website = Get-AzureWebsite $WebsiteName
				   
    Set-AzureWebsite $WebsiteName -ConnectionStrings (@{Name="DefaultConnection"; Type="SQLAzure"; ConnectionString=$connString;})	
} else {
	Switch-AzureMode AzureServiceManagement | Out-Null
	Select-AzureAccount

	#Get the Website
	#if($WebsiteSlot) {
#		$website = Get-AzureWebsite $WebsiteName -Slot $WebsiteSlot -ErrorAction SilentlyContinue
	#} else {
#		$website = Get-AzureWebsite $WebsiteName -ErrorAction SilentlyContinue
#	}
##	if(-not $website -or $website.Count -eq 0) {
#		throw ("Unable to find website {0}{1}" -f $WebsiteName, @{$true="($WebsiteSlot)";$false=""}[[bool]$WebsiteSlot])
#	}
#
#	if($website.Count -gt 1 -and (-not $WebsiteSlot)) {
#		$website
#		throw ("Please specify -WebsiteSlot for site {0}" -f $WebsiteName)
#	}
#
#	Write-Verbose ("Found website {0}{1}" -f $WebsiteName, @{$true="($WebsiteSlot)";$false=""}[[bool]$WebsiteSlot])

}
#Deploy the Website
Write-Verbose "Deploying site"

if($WebsiteSlot) {
	Publish-AzureWebsiteProject -Name $WebsiteName -Slot $WebsiteSlot -Package $WebDeployPackagePath
} else {
	Publish-AzureWebsiteProject -Name $WebsiteName -Package $WebDeployPackagePath
}

Write-Host "[Complete] Deploying site package"
