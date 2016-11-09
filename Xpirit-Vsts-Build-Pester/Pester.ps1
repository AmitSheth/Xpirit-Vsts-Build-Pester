    Param(
    [string] $ItemSpec = "*.tests.ps1",
	[string] $FailOnError = "false"
)
function Get-ModuleVersion($modulename){
    return (Get-Module -Name $modulename).Version
}

$TestFiles=$(get-childitem -path $env:BUILD_SOURCESDIRECTORY -recurse $ItemSpec).fullname

Write-Output "Test files found:"
Write-Output $TestFiles

$pesterversion = Get-ModuleVersion ("Pester")
if ($pesterversion) {
    #pester is installed on the system
	Write-Output "Pester is installed $pesterversion"
} else {
	Write-Output "Intalling latest version of pester"
    
    #install pester
    $tempFile = Join-Path $env:temp "pester.zip"
	$modulePath = Join-Path $env:temp "pester-master\Pester.psm1" 

	Invoke-WebRequest https://github.com/pester/Pester/archive/master.zip -OutFile $tempFile
 
	$unzipdir = Join-Path $env:temp "pester-master"
	if (Test-Path $unzipdir){
	    Remove-Item "$unzipdir" -recurse
	}

	Add-Type -Assembly System.IO.Compression.FileSystem
	[System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $env:temp)

	Import-Module $modulePath -DisableNameChecking -Verbose

    $pesterversion = Get-ModuleVersion ("Pester")
	Write-Output "Pester installed $pesterversion"
}

[string] $filepart1 = "TEST-pester"
[string] $filepart2 = ".xml"
[string] $filename = -Join ($filepart1, $filepart2)

$outputFile = Join-Path $env:COMMON_TESTRESULTSDIRECTORY $filename

if (Test-Path $outputFile){
    [int]$counter = 1
	while (Test-Path $outputFile){
        $filename = -Join ($filepart1,  (-Join ($counter, $filepart2)))
		$outputFile = Join-Path $env:COMMON_TESTRESULTSDIRECTORY $filename
        $counter = $counter+1
	}
}

Write-Output "Writing pester output to $outputfile"

$result = Invoke-Pester $TestFiles -PassThru -Outputformat nunitxml -Outputfile $outputFile

if ([boolean]::Parse($FailOnError)){
	if ($result.failedCount -ne 0)
	{ 
		Write-Error "Error Pester: 1 or more tests failed"
	}
}
