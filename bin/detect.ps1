$path = $args[0]

$files = @(Get-ChildItem $path -Name)

if ($files -contains "web.config")
{
  Write-Output "IIS8/.NET"
  exit 0
}
else
{
  exit 1
}