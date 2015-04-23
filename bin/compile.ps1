write-output "Started Compilation Script";
$build_path = $args[0]
$cache_path = $args[1]

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$iisPath = Join-Path (get-item $scriptPath ).parent.FullName 'iishwc\*'
$nugetPath = Join-Path $scriptPath 'nuget.exe'
$msbuild = Join-Path ([System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()) "MSBuild.exe"

$null = Copy-Item "${build_path}\*" $cache_path -Recurse -Force

Write-Output "Cleaning build directory ..."
Remove-Item (Join-Path $build_path '*') -Recurse -Force

$solutionFiles = Get-ChildItem (Join-Path $cache_path '*.sln')

if ($solutionFiles -ne $null)
{
    # *.sln file present
    if ($solutionFiles.Count -gt 1)
    {
        # more than 1 *.sln file
        Write-Output "More than 1 .sln files present"
        [Console]::Out.Flush()         
        exit 1
    }

    $solutionFile = $solutionFiles[0]
    $solutionName= $solutionFile.Name
    Write-Output "Detected solution file ${solutionName} - building it ..."
    [Console]::Out.Flush() 
    
    Write-Output 'Restoring nuget packages ...'
    [Console]::Out.Flush()
    
    Push-Location $cache_path
    (& $nugetPath restore -noninteractive) | Write-Output
    Pop-Location

    Write-Output 'Running msbuild ...'
    [Console]::Out.Flush()
    
    $buildDirName = [guid]::NewGuid().ToString("N")
    $outDir = Join-Path (get-item $scriptPath ).parent.FullName $buildDirName
    
    $null = mkdir $outDir
    
    $env:EnableNuGetPackageRestore = 'true'

    $buildPlatform = "Any CPU"
    if(![String]::IsNullOrEmpty($env:MSBUILD_PLATFORM))
    {
        $buildPlatform = $env:MSBUILD_PLATFORM
    }

    $buildConfiguration = ""
    if(![String]::IsNullOrEmpty($env:MSBUILD_CONFIGURATOIN))
    {
        $buildConfiguration = "/p:Configuration=`"${env:MSBUILD_CONFIGURATOIN}`""
    }

    (& $msbuild $solutionFile.fullname /t:Rebuild /p:Platform="${buildPlatform}" /p:OutDir="${outDir}" ${buildConfiguration}) | Write-Output

    $publishedFolder = Get-ChildItem (Join-Path $outDir '_PublishedWebsites\*')

    if ($publishedFolder -ne $null)
    {
        if([String]::IsNullOrEmpty($env:PUBLISH_WEBSITE))
        {
            if($publishedFolder.Count -gt 1)
            {
                Write-Output "Found more than 1 published website. PUBLISH_WEBSITE is not specified"
                exit 1
            }
            $appPath = $publishedFolder[0]
        }
        else
        {
            if(!(Test-Path ($publishedFolder | Where-Object -Property Name -EQ $env:PUBLISH_WEBSITE)))
            {
                Write-Output "$env:PUBLISH_WEBSITE not found"
                exit 1
            }
            $appPath = $publishedFolder | Where-Object -Property Name -EQ $env:PUBLISH_WEBSITE 
        }
        Write-Output "Copying published files ..."

        $null = Copy-Item "${appPath}\*" $build_path -Recurse -Force
    }
    else
    {
        Write-Output 'Could not find a published website after build. Exiting.'
        exit 1
    }

    [Console]::Out.Flush()
}
else
{
    Write-Output "No .sln found. Looking for *.*proj"
    $projFiles = Get-ChildItem (Join-Path $cache_path '*.*proj')
    if($projFiles -ne $null)
    {
        Write-Output "Found *.*proj. Running msbuild ..."
        $pubXml = Join-Path $scriptPath "publish.pubxml"
        Push-Location $cache_path
        (& $msbuild /p:DeployOnBuild=true /p:PublishProfile="${pubXml}" /p:PublishUrl="${build_path}") | Write-Output
        Pop-Location
    }
    else
    {
        $null = Copy-Item "${cache_path}\*" $build_path -Recurse -Force
    }
}

if(!(Test-Path (Join-Path $build_path "web.config")))
{
    Write-Output "Web.config not found"
    exit 1
}

$iishwcPath = Join-Path $build_path "iishwc"
$null = mkdir $iishwcPath
$bpAppPath = Join-Path (get-item $scriptPath ).parent.FullName 'app\*'

write-output "Copying IIS Executable to App directory"

$null = Copy-Item $bpAppPath $build_path -Recurse -Force
$null = Copy-Item $iisPath $iishwcPath -Recurse -Force

Write-Output "Cleaning cache directory ..."
Remove-Item (Join-Path $cache_path '*') -Recurse -Force

[Console]::Out.Flush() 

write-output "Done"

exit 0
