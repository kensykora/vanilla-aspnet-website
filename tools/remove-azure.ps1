
Param(
    [Parameter(Mandatory = $true, Position=1)]
	[String]$ResourceGroupName,
	[Parameter(Mandatory = $False)]
	[String]$SubscriptionName
)

Write-Verbose "[Start] Deprovisioning resource group $ResourceGroupName"
$ErrorActionPreference = "Stop"


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
		Write-Warning "Account contains multiple subscriptions, but no subscription name was provided. Using the first subscription."
		$SubscriptionName = $subscriptions[0].SubscriptionName
	} else {
		$subscriptions = $subscriptions | Where { $_.SubscriptionName -eq $SubscriptionName }
		if($subscriptions.Count -ne 1) {
			throw "Unable to find subscription $SubscriptionName on account $AzureLogin"
		}
	} 
	Write-Verbose "Found ${SubscriptionName}"
	Select-AzureSubscription -SubscriptionName $SubscriptionName -Current | Out-Null
}


Switch-AzureMode AzureResourceManager | Out-Null
Select-AzureAccount

$resource = Get-AzureResourceGroup $ResourceGroupName -ErrorAction SilentlyContinue
if(-not $resource) {
	throw "Resource Group $ResourceGroupName not found."
} else {
	Remove-AzureResourceGroup $ResourceGroupName -Force -Verbose
}

Write-Host "[Complete] Deprovisioning resource group $ResourceGroupName"
