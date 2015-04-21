param (
	[Parameter(Mandatory=$True, Position=1)]
	[string]$AzureWebsiteName,
	[Parameter(Mandatory=$False)]
	[string]$RemoveMatch,
	[Parameter(Mandatory = $False)]
	[String]$SubscriptionName
	)
	
$ErrorActionPreference = "Stop"

if(-not $env:LOADERIO_API_KEY) {
	throw "Loader.io API key not set"
}

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
	
	$azureAccount = Add-AzureAccount -Credential $cred
	
	Write-Verbose ("Found {0}" -f $azureAccount[0].Id)

	#Get the Subscription
	$subscriptions = Get-AzureSubscription

	if($subscriptions.Count -gt 1 -and (-not $SubscriptionName)) {
		$SubscriptionName = $subscriptions[0].SubscriptionName
		Write-Warning "Account contains multiple subscriptions, but no subscription name was provided. Using subscription $SubscriptionName."
		
	} else {
		$subscriptions = $subscriptions | Where { $_.SubscriptionName -eq $SubscriptionName }
		if($subscriptions.Count -ne 1) {
			throw "Unable to find subscription $SubscriptionName on account $AzureLogin"
		}
	} 
	Write-Verbose "Found ${SubscriptionName}"
	Select-AzureSubscription -SubscriptionName $SubscriptionName -Current | Out-Null
}

$key = $env:LOADERIO_API_KEY

Write-Debug "RemoveMatch: $RemoveMatch"
$CreateApp = $true

$apps = Invoke-RestMethod -Uri "https://api.loader.io/v2/apps" -Method Get -Headers @{"loaderio-auth"=$key}
$apps | % { 
	if($_.app -eq "$AzureWebsiteName.azurewebsites.net") {
		if($_.status -eq "verified") {
			Write-Host "App already found and verified"
			Write-Host $_
			Exit
		} else {
			Write-Host "App found but not verified"
			$CreateApp = $false
		}
	}
}

if($CreateApp -and $RemoveMatch) {
	$apps | % {
		if($_.app.Contains($RemoveMatch)) {
			Write-Verbose ("Removing App {0}" -f $_.app)
			Invoke-RestMethod -Uri ("https://api.loader.io/v2/apps/{0}" -f $_.app_id) -Method Delete -Headers @{"loaderio-auth"=$key}
		}
	}
}


if($CreateApp) {
	Write-Verbose "Creating app $AzureWebsiteName.azurewebsites.net"
	
	$app = @{app="$AzureWebsiteName.azurewebsites.net"}
	$app = Invoke-RestMethod -Uri "https://api.loader.io/v2/apps" -Method Post -Body (ConvertTo-Json $app) -ContentType "application/json" -Headers @{"loaderio-auth"=$key}
}

$ErrorActionPreference = "SilentlyContinue"
$test = Invoke-WebRequest -Uri ("http://{0}/loaderio-{1}.txt" -f "$AzureWebsiteName.azurewebsites.net", $app.app_id) -ErrorAction SilentlyContinue
$ErrorActionPreference = "Stop"

if(-not $test) {
	Write-Verbose "Couldn't find verification file. Setting Configuration id."
	Select-AzureAccount
	
	$website = Get-AzureWebsite $AzureWebsiteName
	
	if(-not $website) {
		throw "Unable to find website $AzureWebsiteName"
	}
	
	$website.AppSettings.LoaderIOKey = $app.app_id
	Set-AzureWebsite -Name $AzureWebsiteName -AppSettings $website.AppSettings -Verbose
	Write-Verbose "Finished setting LoaderIO Key"
	
	Start-Sleep -Seconds 15
	
	$ErrorActionPreference = "SilentlyContinue"
	$test = Invoke-WebRequest -Uri ("http://{0}/loaderio-{1}.txt" -f "$AzureWebsiteName.azurewebsites.net", $app.app_id) -ErrorAction SilentlyContinue
	
	$ErrorActionPreference = "Stop"
	if(-not $test) {
		throw "Unable to successfully set validation key"
	}
}

$app = Invoke-RestMethod -Uri ("https://api.loader.io/v2/apps/{0}" -f $app.app_id) -Method Get -Headers @{"loaderio-auth"=$key}
if($app.status -eq "unverified") {
	$verificationMethod = @{method="url"}
	$ErrorActionPreference = "SilentlyContinue"
	$verification = Invoke-RestMethod -Uri ("https://api.loader.io/v2/apps/{0}/verify" -f $app.app_id) -Method Post -Headers @{"loaderio-auth"=$key} -ContentType "application/json" -Body (ConvertTo-Json $verificationMethod) -OutVariable $result
	$ErrorActionPreference = "Stop"
	
	if($verification.message -ne "success") {
		throw ("Unable to have Loader.IO validate app {0} for site {1}" -f $app.app_id, ("http://{0}/loaderio-{1}.txt" -f "$AzureWebsiteName.azurewebsites.net", $app.app_id))
	}
}
#Prime URL
Start-Sleep -Seconds 5
Invoke-WebRequest -Uri "http://$AzureWebsiteName.azurewebsites.net" | Out-Null
