write-output "Started Compilation Script";
$build_path = $args[0]
$cache_path = $args[1]

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$iisPath = Join-Path (get-item $scriptPath ).parent.FullName 'iishwc\*'
$nugetPath = Join-Path $scriptPath 'nuget.exe'

$solutionFile = Get-ChildItem (Join-Path $build_path '*.sln')

if ($solutionFile -ne $null)
{
    $solutionFile = $solutionFile[0]
    Write-Output "Detected solution file ${solutionFile.Name} - building it ..."
    [Console]::Out.Flush() 
    
    Write-Output 'Restoring nuget packages ...'
    [Console]::Out.Flush() 
    (& $nugetPath restore -noninteractive) | Write-Output

    Write-Output 'Running msbuild ...'
    [Console]::Out.Flush()
    
    $msbuild = 'C:\Windows\Microsoft.Net\Framework64\v4.0.30319\MSBuild.exe'
    $buildDirName = [guid]::NewGuid().ToString("N")
    $outDir = Join-Path (get-item $scriptPath ).parent.FullName $buildDirName
    
    $null = mkdir $outDir
    
    $env:EnableNuGetPackageRestore = 'true'

    (& $msbuild $solutionFile.fullname /t:Rebuild /p:Platform="Any CPU" /p:OutDir="${outDir}") | Write-Output

    $publishedFolder = Get-ChildItem (Join-Path $outDir '_PublishedWebsites\*')
    
    if ($publishedFolder -ne $null)
    {
        $publishedFolder = $publishedFolder[0]

        Write-Output "Cleaning build directory ..."
        Remove-Item (Join-Path $build_path '*') -Recurse -Force

        Write-Output "Copying published files ..."
        $bpAppPath = Join-Path $publishedFolder '*'
        $null = Copy-Item $bpAppPath $build_path -Recurse -Force
    }
    else
    {
        Write-Output 'Could not find a published website after build. Exiting.'
        exit 1
    }

    [Console]::Out.Flush()
}

$iishwcPath = Join-Path $build_path "iishwc"
$null = mkdir $iishwcPath
$bpAppPath = Join-Path (get-item $scriptPath ).parent.FullName 'app\*'

write-output "Copying IIS Executable to App directory"

$null = Copy-Item $bpAppPath $build_path -Recurse -Force
$null = Copy-Item $iisPath $iishwcPath -Recurse -Force

[Console]::Out.Flush() 

write-output "Done"

exit 0
