param([ValidateSet('staff1','staff2','user1','user2')][string]$Identifier='staff1')
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
$state=Get-Content (Join-Path $root '.runtime/recovery-state.json') -Raw | ConvertFrom-Json
$rows=Get-Content (Join-Path $root '.runtime/demo-login-aliases.json') -Raw | ConvertFrom-Json
$row=$rows | Where-Object identifier -eq $Identifier
if(!$row){throw 'Existing demo alias not found'}
$login=Invoke-RestMethod "$($state.origin)/api/auth/login" -Method Post -ContentType application/json -Body (@{identifier=$row.identifier;password=$row.password} | ConvertTo-Json) -TimeoutSec 15
$me=Invoke-RestMethod "$($state.origin)/api/auth/me" -Headers @{Authorization="Bearer $($login.data.access_token)"} -TimeoutSec 15
if($me.data.user_id -ne $row.user_id){throw 'Returned token belongs to a different user'}
$file=Join-Path $root ".runtime/api-token-$Identifier.json"
@{base_url=$state.origin;identifier=$Identifier;role=$me.data.role;access_token=$login.data.access_token;token_type='Bearer';expires_in=$login.data.expires_in;issued_at_utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath $file -Encoding utf8
$who=[Security.Principal.WindowsIdentity]::GetCurrent().Name
& icacls $file /inheritance:r /grant:r "${who}:(F)" | Out-Null
Write-Output "PASS login/me HTTP 200. Token saved privately: $file"
Write-Output "Base URL: $($state.origin). Use Authorization: Bearer <access_token>."
