# check_release.ps1의 스케줄러용 래퍼 (docs/OPERATIONS.md 8절)
# - 결과를 %LOCALAPPDATA%\bookquote\check_release.log 에 누적 (최근 500줄 유지)
# - 실패 시에만 팝업 알림 (성공은 조용히 로그만)
# 등록 예: 매일 09:00, Windows 작업 스케줄러 (아래 주석의 등록 명령 참고)
#
# Register-ScheduledTask 등록 명령(관리자 불필요, 현재 사용자로 로그온 시 실행):
#   $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\GIT\bookquote\tool\check_release_task.ps1"'
#   $trigger = New-ScheduledTaskTrigger -Daily -At 09:00
#   $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
#   Register-ScheduledTask -TaskName 'Bookquote Release Check' -Action $action -Trigger $trigger -Settings $settings

$logDir = Join-Path $env:LOCALAPPDATA 'bookquote'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = Join-Path $logDir 'check_release.log'

$checkScript = Join-Path $PSScriptRoot 'check_release.ps1'
$output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $checkScript 2>&1 | Out-String
$exitCode = $LASTEXITCODE

# 로그 누적 + 최근 500줄 유지
Add-Content -Path $logFile -Value $output -Encoding UTF8
$lines = Get-Content $logFile -Encoding UTF8
if ($lines.Count -gt 500) {
    $lines | Select-Object -Last 500 | Set-Content $logFile -Encoding UTF8
}

if ($exitCode -ne 0) {
    # 실패 항목만 추려 팝업으로 알림
    $fails = ($output -split "`n") | Where-Object { $_ -match '\[FAIL\]' }
    $message = "책글귀 출시 점검 실패 $exitCode건`n`n" + ($fails -join "`n") +
        "`n`n로그: $logFile"
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        $message,
        '책글귀 모니터링 경보',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}

exit $exitCode
