$env:PORT=31221
$env:VCAP_WINDOWS_USER="user"
$env:VCAP_WINDOWS_USER_PASSWORD="pass"
$env:VCAP_SERVICES="{}"
$env:HOME="F:\jenkins\workspace\als-cf-iis8-buildpack-verify\TestApps\iis8"
$env:HOMEPATH="F:\jenkins\workspace\als-cf-iis8-buildpack-verify"

Start-Process -FilePath "TestApps\iis8\iishwc\start.bat" -PassThru

Start-Sleep -s 10

echo "Invoking web request"
if ( $(invoke-webrequest http://localhost:${env:PORT} ).statuscode -ne 200 ) {
    throw "Statuscode for invoke-webrequest is not 200"
}

echo "Killing iis process"
foreach ($ppid in $(gwmi win32_process | select ProcessID, CommandLine | Where-Object { $_.CommandLine -like "F:\jenkins\workspace\als-cf-iis8-buildpack-verify*" } | select ProcessID)) 
  {
  Stop-Process -force -id $ppid.ProcessID
  }

