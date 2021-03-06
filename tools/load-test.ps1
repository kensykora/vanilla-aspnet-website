# Load Test
#
# Invokes the Loader.io API and runs load tests
#
# == Usage ==
# .\load-test.ps1 -ApiKey xxxxxxxxx -Name "My Test Name"
#
# == Environment Settings ==
#
# LOADERIO_API_KEY: Api Key to authenticate with Loader.IO
#
# == Params ==
#
# Name: Name of the test
# HostName: HostName to send traffic to 
# PrimeUrl: URL to hit before kicking off the test (to prime the site in case it needs a few seconds on first load)
#
# == Example Usage ==
# .\load-test.ps1 -Name "Load test for BAMNER-3" -HostName "www.google.com" -PrimeUrl "http://www.google.com"
#
param (
[Parameter(Mandatory=$True)][string]$Name,
[Parameter(Mandatory=$True)][string]$HostName,
[Parameter(Mandatory=$False)][string]$PrimeUrl)

if($env:CONFIGURATION -ne "Debug") {
	exit 0;
}

if(-not $env:LOADERIO_API_KEY) {
	throw "Loader.io API key not set"
}

$HostName = $HostName.ToLower()

$API_ATTEMPTS = 5
$API_TIME_BETWEEN_ATTEMPTS_SECONDS = 17

$ACCEPTABLE_ERROR_RATE = 0.01
$ACCEPTABLE_AVG_RESPONSE_TIME_MS = 150

$ErrorActionPreference = "Stop"

$key = $env:LOADERIO_API_KEY
	
$test = @{
	test_type="non-cycling"
	urls= @(@{url="http://$HostName/"})
	duration= 15
	name= $Name
	initial= 0
	total= 1000
}

if($PrimeUrl) {
	Invoke-WebRequest -Uri $PrimeUrl
}

$attempts = 0
$testId = $null
$resuldId = $null

while($response -eq $null -and $attempts -lt $API_ATTEMPTS) {
	$attempts = $attempts + 1
	try {
		$response = Invoke-RestMethod -Uri "https://api.loader.io/v2/tests" -Method Post -Body (ConvertTo-Json $test) -ContentType "application/json" -Headers @{"loaderio-auth"=$key}
		Write-Host $response
		$testId = $response.test_id
		$resultId = $response.result_id
	} catch {
		$_
		Start-Sleep -Seconds $API_TIME_BETWEEN_ATTEMPTS_SECONDS
	}
}
Start-Sleep -Seconds $API_TIME_BETWEEN_ATTEMPTS_SECONDS
$response=$null
while($response -eq $null -and $attempts -lt $API_ATTEMPTS) {
	$attempts = $attempts + 1
	try {
		$response = Invoke-RestMethod -Uri ("https://api.loader.io/v2/tests/{0}/results/{1}" -f $testId, $resultId)-Method Get -ContentType "application/json" -Headers @{"loaderio-auth"=$key}
		Write-Host $response
		if($response.status -ne "ready") {
			$response=$null
			Start-Sleep -Seconds $API_TIME_BETWEEN_ATTEMPTS_SECONDS
		} else {
			if($response.avg_error_rate -gt $ACCEPTABLE_ERROR_RATE) {
				Add-AppveyorTest -Name "Load Test" -Outcome Failed -Duration $response.avg_response_time -ErrorMessage ("Unacceptable Average Error Rate: {0} > {1}" -f $response.avg_error_rate, $ACCEPTABLE_ERROR_RATE) -StdErr ("Unacceptable Average Response Time: {0} > {1}" -f $response.avg_response_time, $ACCEPTABLE_AVG_RESPONSE_TIME_MS)
				exit 1
			} elseif($response.avg_response_time -gt $ACCEPTABLE_AVG_RESPONSE_TIME_MS) {
				Add-AppveyorTest -Name "Load Test" -Outcome Failed -Duration $response.avg_response_time -ErrorMessage ("Unacceptable Average Response Time: {0} > {1}" -f $response.avg_response_time, $ACCEPTABLE_AVG_RESPONSE_TIME_MS) -StdErr ("Unacceptable Average Response Time: {0} > {1}" -f $response.avg_response_time, $ACCEPTABLE_AVG_RESPONSE_TIME_MS)
				exit 1
			} else {
				Add-AppveyorTest -Name "Load Test" -Outcome Passed -Duration $response.avg_response_time -StdOut ("Pass: Average Response Time: {0} <= {1}" -f $response.avg_response_time, $ACCEPTABLE_AVG_RESPONSE_TIME_MS)
			}
		}
	} catch {
		$_
		Start-Sleep -Seconds $API_TIME_BETWEEN_ATTEMPTS_SECONDS
	}
}
