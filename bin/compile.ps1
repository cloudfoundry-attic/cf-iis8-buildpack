write-output "Started Compilation Script";
$build_path = $args[0]
$cache_path = $args[1]

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$iisPath = Join-Path (get-item $scriptPath ).parent.FullName 'iishwc\*'

if(!(Test-Path (Join-Path $build_path "web.config")))
{
    Write-Output "Web.config not found"
    [Console]::Out.Flush()
    exit 1
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
