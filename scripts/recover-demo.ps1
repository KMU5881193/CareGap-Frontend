param([switch]$VerifyAI,[switch]$BuildApk)
$ErrorActionPreference='Stop'
$fe=Split-Path $PSScriptRoot
$workspace=Split-Path $fe
$be=Join-Path $workspace 'final-verification-CareGap-Backend'
$runtime=Join-Path $fe '.runtime'
$aliasesFile=Join-Path $runtime 'demo-login-aliases.json'
$accountsFile=Join-Path $be '.runtime/demo-credentials.json'
function Health([string]$url){try{return Invoke-RestMethod "$url/health" -TimeoutSec 5}catch{return $null}}
function PortBusy([int]$port){$c=[Net.Sockets.TcpClient]::new();try{$t=$c.ConnectAsync('127.0.0.1',$port);if(!$t.Wait(1000)){return $false};return $c.Connected}catch{return $false}finally{$c.Dispose()}}
function WaitHealth([string]$url){for($i=0;$i -lt 40;$i++){if(Health $url){return};Start-Sleep -Milliseconds 500};throw "API did not become ready: $url"}
function PrivateFile([string]$path){$who=[Security.Principal.WindowsIdentity]::GetCurrent().Name; & icacls $path /inheritance:r /grant:r "${who}:(F)" | Out-Null}
foreach($p in @($aliasesFile,$accountsFile,(Join-Path $be 'scripts/start-four-demo.ps1'))){if(!(Test-Path -LiteralPath $p)){throw "Required existing file missing: $p"}}
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$backup=Join-Path $runtime "recovery-backup-$stamp"
New-Item -ItemType Directory -Path $backup | Out-Null
foreach($name in 'demo-credentials.json','demo-seed-state.json','demo-summary.json'){$p=Join-Path $be ".runtime/$name";if(Test-Path -LiteralPath $p){Copy-Item -LiteralPath $p -Destination $backup}}
Copy-Item -LiteralPath $aliasesFile -Destination $backup
$who=[Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls $backup /inheritance:r /grant:r "${who}:(OI)(CI)F" | Out-Null
$ollama='http://127.0.0.1:11434'
try{$tags=Invoke-RestMethod "$ollama/api/tags" -TimeoutSec 5}catch{
 if(PortBusy 11434){throw 'Ollama port is occupied but unhealthy; no process was stopped.'}
 if(Get-Process ollama -ErrorAction SilentlyContinue){throw 'Ollama process exists without healthy API; inspect it manually, do not start a duplicate.'}
 Start-Process (Get-Command ollama).Source -ArgumentList 'serve' -WindowStyle Hidden -RedirectStandardOutput (Join-Path $runtime 'recovery-ollama.log') -RedirectStandardError (Join-Path $runtime 'recovery-ollama.error.log') | Out-Null
 Start-Sleep -Seconds 2
 $tags=Invoke-RestMethod "$ollama/api/tags" -TimeoutSec 5
}
if('qwen2.5vl:7b' -notin $tags.models.name){throw 'Installed Qwen is missing. This script never downloads models.'}
$loaded=Invoke-RestMethod "$ollama/api/ps" -TimeoutSec 5
if(@($loaded.models | Where-Object {$_.name -ne 'qwen2.5vl:7b'}).Count){throw 'Another model is loaded; refusing to load Qwen concurrently or unload someone else''s model.'}
$null=Invoke-RestMethod "$ollama/api/generate" -Method Post -ContentType application/json -Body '{"model":"qwen2.5vl:7b","keep_alive":"15m","stream":false}' -TimeoutSec 120
$startedApi=$false
if(!(Health 'http://127.0.0.1:4334')){
 if(PortBusy 4334){throw '4334 is occupied but unhealthy; refusing to replace it.'}
 foreach($p in @('CareGap-Backend/experiments/handwriting-ocr/.venv/Scripts/python.exe','CareGap-Backend/experiments/handwriting-ocr/worker.py','CareGap-Backend-STT/experiments/stt/.venv/Scripts/python.exe','CareGap-Backend-STT/experiments/stt/models/base/model.bin')){if(!(Test-Path (Join-Path $workspace $p))){throw "Existing model/runtime path missing: $p"}}
 & pwsh -NoProfile -File (Join-Path $be 'scripts/start-four-demo.ps1')
 if($LASTEXITCODE -ne 0){throw 'API start failed'}
 WaitHealth 'http://127.0.0.1:4334'
 $startedApi=$true
}
if($startedApi -or $VerifyAI){Push-Location $be;try{
 & pwsh -NoProfile -File scripts/four-demo-assets.ps1
 & (Join-Path $workspace 'CareGap-Backend/experiments/handwriting-ocr/.venv/Scripts/python.exe') scripts/four-demo-images.py
 if($LASTEXITCODE -ne 0){throw 'Synthetic image generation failed'}
 node --import tsx scripts/seed-four-demo.ts > .runtime/recovery-seed.log
 if($LASTEXITCODE -ne 0){throw 'Seed/real AI validation failed; see recovery-seed.log'}
 $summary=Get-Content .runtime/demo-summary.json -Raw | ConvertFrom-Json
 if(@($summary.summary | Where-Object {$_.analysis_status -ne 'succeeded' -or $_.welfare_candidates -lt 1}).Count){throw 'A model returned failed or no verified welfare result'}
}finally{Pop-Location}}
$webRoot='build/web-recovery'
if(!(Test-Path (Join-Path $fe "$webRoot/index.html"))){
 Push-Location $fe;try{
  $dart=Join-Path $workspace '.tools/flutter-3.47.4/bin/cache/dart-sdk/bin/dart.exe'
  $flutter=Join-Path $workspace '.tools/flutter-3.47.4/bin/cache/flutter_tools.snapshot'
  & $dart $flutter build web --no-pub --output=$webRoot --dart-define=USE_MOCK=false --dart-define=USE_SAME_ORIGIN=true --dart-define=ALLOW_LOOPBACK_HTTP=true > .runtime/recovery-web-build.log
  if($LASTEXITCODE -ne 0){throw 'Web build failed'}
 }finally{Pop-Location}
}
$origin=$null
foreach($name in 'recovery-state.json','recovery-web.json'){$p=Join-Path $runtime $name;if(Test-Path $p){$s=Get-Content $p -Raw | ConvertFrom-Json;if($s.origin -and (Health $s.origin)){$origin=$s.origin;break}}}
$gatewayHealthy=[bool](Health 'http://127.0.0.1:4339')
if(!$origin){
 if($gatewayHealthy){throw '4339 is healthy but its public tunnel is unavailable. Preserve the gateway; inspect Origin configuration before replacing its URL.'}
 $err=Join-Path $runtime "recovery-tunnel-$stamp.err.log"
 $out=Join-Path $runtime "recovery-tunnel-$stamp.out.log"
 $cloud=(Get-Command cloudflared).Source
 $tunnel=Start-Process $cloud -ArgumentList @('tunnel','--protocol','http2','--url','http://127.0.0.1:4339','--no-autoupdate') -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
 for($i=0;$i -lt 40;$i++){if(Test-Path $err){$origin=([regex]::Match((Get-Content $err -Raw),'https://[a-z0-9-]+\.trycloudflare\.com')).Value;if($origin){break}};Start-Sleep -Milliseconds 500}
 if(!$origin){throw 'No real Quick Tunnel URL in log'}
}
$env:DEMO_PUBLIC_ORIGIN=$origin
$env:DEMO_LOGIN_ALIASES_FILE=$aliasesFile
foreach($port in 4339,4335){if(!(Health "http://127.0.0.1:$port")){
 if(PortBusy $port){throw "Port $port belongs to an unhealthy process; refusing to replace it"}
 $env:DEMO_WEB_PORT="$port";$env:DEMO_WEB_ROOT=$webRoot
 $p=Start-Process (Get-Command node).Source -ArgumentList @('scripts/local-web-demo.mjs') -WorkingDirectory $fe -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtime "recovery-web-$port.log") -RedirectStandardError (Join-Path $runtime "recovery-web-$port.error.log")
 WaitHealth "http://127.0.0.1:$port"
}}
WaitHealth $origin
$rows=Get-Content $aliasesFile -Raw | ConvertFrom-Json
$tokens=foreach($row in $rows){$login=Invoke-RestMethod "$origin/api/auth/login" -Method Post -ContentType application/json -Body (@{identifier=$row.identifier;password=$row.password} | ConvertTo-Json);$me=Invoke-RestMethod "$origin/api/auth/me" -Headers @{Authorization="Bearer $($login.data.access_token)"};if($me.data.user_id -ne $row.user_id){throw 'Alias identity mismatch'};@{identifier=$row.identifier;role=$me.data.role;access_token=$login.data.access_token;expires_in=$login.data.expires_in}}
$tokenPath=Join-Path $runtime 'recovery-api-access.json'
@{base_url=$origin;issued_at_utc=[DateTime]::UtcNow.ToString('o');accounts=@($tokens)} | ConvertTo-Json -Depth 5 | Set-Content $tokenPath -Encoding utf8
PrivateFile $tokenPath
@{origin=$origin;api='http://127.0.0.1:4334';local_web='http://127.0.0.1:4339';local_web_alternate='http://127.0.0.1:4335';started_api=$startedApi;checked_at=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content (Join-Path $runtime 'recovery-state.json') -Encoding utf8
Write-Output "PASS 4 logins. Web/API: $origin"
Write-Output "API tokens: $tokenPath (private; never commit)."
if($BuildApk){Push-Location $fe;try{
 $dart=Join-Path $workspace '.tools/flutter-3.47.4/bin/cache/dart-sdk/bin/dart.exe'
 $flutter=Join-Path $workspace '.tools/flutter-3.47.4/bin/cache/flutter_tools.snapshot'
 & $dart $flutter build apk --debug --no-pub --dart-define=USE_MOCK=false --dart-define=USE_SAME_ORIGIN=false "--dart-define=BACKEND_URL=$origin" > .runtime/recovery-apk-build.log
 if($LASTEXITCODE -ne 0){throw 'API/web recovered, but mobile APK build failed; see recovery-apk-build.log'}
 Write-Output "APK rebuilt for $origin : build/app/outputs/flutter-apk/app-debug.apk"
}finally{Pop-Location}}
Write-Output '4324 and Docker were not modified. Stale pre-reboot Bearer tokens must not be reused.'
