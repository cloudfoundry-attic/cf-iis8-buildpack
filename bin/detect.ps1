$path = $args[0]

$files = @(Get-ChildItem $path -Name)
$solutionFile = Get-ChildItem (Join-Path $path '*.sln')

IF (($files -contains "web.config") -or ($solutionFile -ne $null))
{
  Write-Output "IIS8/.NET"
  exit 0
}
ELSE
{
  exit 1
}