# UI Test
#
# Invokes MS Test to run UI tests. Usually run via Bamboo. Expects environemnt variables to set
# if using remote selenium agent
#
# == Usage ==
# .\ui-test.ps1 DLL
#
# == Environment Variables ==
# VS120COMNTOOLS: Path to VS Tools. Set by visual studio install (should be global)
# BUILD_NAME: Name of the build. e.g., DNET-VAN0-UIT-57
# BROWSERS: JSON array of capability objects.
# Example:
#[
#   {
#      "platform":"MAC",
#      "os":"Mac 10.9",
#      "browser":"ipad",
#      "url":"sauce-ondemand:?os=Mac 10.9&amp;browser=ipad&amp;browser-version=7.1.",
#      "browser-version":"7.1."
#   },
#   {
#      "platform":"MAC",
#      "os":"Mac 10.9",
#      "browser":"iphone",
#      "url":"sauce-ondemand:?os=Mac 10.9&amp;browser=iphone&amp;browser-version=7.1.",
#      "browser-version":"7.1."
#   },
#   {
#      "platform":"WIN8",
#      "os":"Windows 2012",
#      "browser":"firefox",
#      "url":"sauce-ondemand:?os=Windows 2012&amp;browser=firefox&amp;browser-version=29",
#      "browser-version":"29"
#   }
#]
# -- Test Value - "[{`"platform`":`"WIN8`",`"os`":`"Windows 2012`",`"browser`":`"firefox`",`"url`":`"sauce-ondemand:?os=Windows 2012&browser=firefox&browser-version=29`",`"browser-version`":`"29`"},{`"platform`":`"WIN8_1`",`"os`":`"Windows 2012 R2`",`"browser`":`"firefox`",`"url`":`"sauce-ondemand:?os=Windows 2012 R2&browser=firefox&browser-version=31`",`"browser-version`":`"31`"}]"
#
#
#
# == Example Usage ==
# .\ui-test.ps1
#

param([string]$TestContainer = "Website.Tests.UI.dll")

if($env:CONFIGURATION -ne "Debug") {
	exit 0
}

function Edit-XmlNodes {
param (
	[xml] $doc = $(throw "doc is a required parameter"),
	[string] $xpath = $(throw "xpath is a required parameter"),
	[string] $append = $(throw "append is a required parameter")
)    
	$ns = @{mstest="http://microsoft.com/schemas/VisualStudio/TeamTest/2010"}
	Select-Xml -Xml $doc -XPath $xpath -Namespace $ns | % {
		$_.Node.Value = $_.Node.Value + $append
	}
}
$env:path = $env:path + ";" + $env:VS120COMNTOOLS + "..\IDE"
$time = Get-Date -format "yyMMdd-HHmm"
$failed = $False
$browsers = ConvertFrom-Json $Env:BROWSERS
$browsers | % {
	Write-Host $_.platform
	Write-Host $_.os
	Write-Host $_.browser
	Write-Host $_."browser-version"
	$env:TEST_PLATFORM = $_.platform
	$env:TEST_OS = $_.os
	$env:TEST_BROWSER = $_.browser
	$env:TEST_BROWSER_VERSION = $_."browser-version"
	$browserString = $env:TEST_PLATFORM.Replace(" ","") + "-" + $env:TEST_BROWSER.Replace(" ","") + "-" + $env:TEST_BROWSER_VERSION
	
	$testresultsFileName = "uitests-${env:BUILD_NAME}-${browserString}-${time}.trx"
	
	cmd /c mstest /detail:stdout /category:"Interesting" /testcontainer:"${testContainer}" /resultsfile:"$testresultsFileName"
	
	if($LASTEXITCODE -ne 0) {
		$failed = $TRUE
	}

	$xml = [xml](Get-Content $testresultsFileName)
	Edit-XmlNodes $xml -xpath "//mstest:UnitTest/@name" -append "_${browserString}"
	Edit-XmlNodes $xml -xpath "//mstest:UnitTestResult/@testName" -append "_${browserString}"

	$xml.save($testresultsFileName)
	
	# upload results to AppVeyor
	$wc = New-Object 'System.Net.WebClient'
	$wc.UploadFile("https://ci.appveyor.com/api/testresults/mstest/${env:APPVEYOR_JOB_ID}", (Resolve-Path ".\${testresultsFileName}"))
}

if($failed) {
	exit 1
}