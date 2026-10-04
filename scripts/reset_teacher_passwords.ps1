# Repõe a password de TODOS os professores @colegio-ramalhao.com já
# existentes para o novo padrão por omissão individual: [apelido],csj2026
# (ex: antonio.appleton@colegio-ramalhao.com -> "appleton,csj2026").
#
# Porque é preciso: até agora todas as contas estavam na antiga password
# partilhada única ("P@ssword" nesta app, ou outra se criadas à mão/via
# scripts/create_users.ps1 do Scriptorium). A partir de
# db/add_deve_mudar_password.sql, o login só aceita a password pessoal de
# cada professor OU, na primeira entrada, a nova password de omissão — por
# isso as contas antigas ficam bloqueadas até correr este script uma vez.
#
# Usa a Admin API do Supabase (service_role) — por isso corre só localmente,
# nunca a partir do browser/frontend (ver
# Scriptorium/db/password_reset_requires_service_role.sql, que documenta a
# mesma regra: service_role nunca pode ir para app/js).
#
# Uso:
#   1) Cria um .env na raiz de direcao-turma com:
#        SERVICE_ROLE_KEY=eyJ...   (Supabase > Project Settings > API > service_role — NÃO comitar)
#        PROJECT_URL=https://pllmyptwuvxryxfeufcm.supabase.co
#      (mesmo projeto Supabase do Scriptorium — podes copiar de Scriptorium/.env)
#   2) powershell -ExecutionPolicy Bypass -File .\scripts\reset_teacher_passwords.ps1
#
# Depois de correr, confirma no Supabase Dashboard > Authentication > Users
# que as contas @colegio-ramalhao.com foram atualizadas.

$envFile = Join-Path $PSScriptRoot '..\.env'
if (-Not (Test-Path $envFile)) {
  Write-Error ".env não encontrado em $envFile. Cria um com SERVICE_ROLE_KEY e PROJECT_URL (ver Scriptorium/.env) e tenta novamente."
  exit 1
}
Get-Content $envFile | ForEach-Object {
  if ($_ -match "^\s*#") { return }
  if ($_ -match "^(\w+)=(.*)$") {
    [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2].Trim('"'), 'Process')
  }
}

$serviceKey = $env:SERVICE_ROLE_KEY
$projectUrl = $env:PROJECT_URL
if (-not $serviceKey -or -not $projectUrl) {
  Write-Error "SERVICE_ROLE_KEY ou PROJECT_URL não definidos no .env"
  exit 1
}

$headers = @{
  "apikey"        = $serviceKey
  "Authorization" = "Bearer $serviceKey"
  "Content-Type"  = "application/json"
}

# Mesma regra que app/js/core/auth.js (defaultPasswordFor): apelido = parte
# depois do primeiro ponto, antes do @. Emails que não seguem o padrão
# nome.apelido@... (ex: contas de serviço como scriptorium@...) são
# ignorados de propósito — não são professores pessoais.
function Get-DefaultPassword($email) {
  $localPart = $email.Split('@')[0]
  $partes = $localPart.Split('.')
  if ($partes.Length -lt 2 -or -not $partes[1]) { return $null }
  return "$($partes[1]),csj2026"
}

Write-Host "A listar utilizadores Auth..."
$users = @()
$page = 1
do {
  $resp = Invoke-RestMethod -Method GET -Uri "$projectUrl/auth/v1/admin/users?page=$page&per_page=200" -Headers $headers -ErrorAction Stop
  $batch = $resp.users
  $users += $batch
  $page++
} while ($batch.Count -eq 200)

$professores = $users | Where-Object { $_.email -and $_.email.ToLower().EndsWith('@colegio-ramalhao.com') }
Write-Host "Encontradas $($professores.Count) contas @colegio-ramalhao.com."

foreach ($u in $professores) {
  $novaPassword = Get-DefaultPassword $u.email
  if (-not $novaPassword) {
    Write-Warning "Email $($u.email) não segue o padrão nome.apelido@... — ignorado (provavelmente conta de serviço)."
    continue
  }
  try {
    $body = @{ password = $novaPassword } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method PUT -Uri "$projectUrl/auth/v1/admin/users/$($u.id)" -Headers $headers -Body $body -ErrorAction Stop | Out-Null
    Write-Host "OK   $($u.email) -> password reposta para o padrão por omissão"
  } catch {
    Write-Warning "Falhou $($u.email): $($_.Exception.Message)"
  }
}

Write-Host ""
Write-Host "Nota: isto só repõe a password em Supabase Auth. A coluna professores.deve_mudar_password"
Write-Host "já fica 'true' para todos por via de db/add_deve_mudar_password.sql, por isso todos passam"
Write-Host "pelo ecrã de mudança de password no próximo login."
Write-Host "Concluído."
