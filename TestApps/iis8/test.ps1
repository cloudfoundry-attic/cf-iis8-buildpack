$env:PORT=31221
$env:VCAP_WINDOWS_USER="user"
$env:VCAP_WINDOWS_USER_PASSWORD="pass"
$env:VCAP_SERVICES="{}"
$env:HOME="F:\jenkins\workspace\als-cf-iis8-buildpack-verify\TestApps\iis8"
$env:HOMEPATH="F:\jenkins\workspace\als-cf-iis8-buildpack-verify"

Start-Process -FilePath "TestApps\iis8\iishwc\start.bat" -PassThru

$NrRetries=5
$Counter=1
$Success=$false

echo "Invoking web request"
while( $Success -eq $false )
{
  try
  {
    $statcode=$(invoke-webrequest http://localhost:${env:PORT}).statuscode
  }
  catch {}
  finally
  {
    if ( $statcode -ne 200 )
    {
      $Counter++
      if ( $Counter -eq $NrRetries ) { throw "App is not reachable on port ${env:PORT}" }
      echo "Sleeping 2 seconds"
      Start-Sleep -s 2
    }
    else
    {
      $Success=$true
    }
  }
}

echo "Killing iis process"
foreach ($ppid in $(gwmi win32_process | select ProcessID, CommandLine | Where-Object { $_.CommandLine -like "F:\jenkins\workspace\als-cf-iis8-buildpack-verify*" } | select ProcessID)) 
  {
  Stop-Process -force -id $ppid.ProcessID
  }

