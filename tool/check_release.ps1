# 책글귀 출시 상태 자동 점검 (docs/OPERATIONS.md 8절)
# 사용법: powershell -File tool\check_release.ps1
# 콘솔 로그인이 필요 없는 외부 표면만 검사한다. Crashlytics/vitals/AdMob은 링크로 안내.

$ErrorActionPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$script:fail = 0

function Test-Http {
    param(
        [string]$Name,
        [string]$Url,
        [string]$MustContain = $null,
        [hashtable]$Headers = @{},
        [int[]]$AcceptCodes = @(200)  # 가용성만 볼 땐 401 등도 '서비스 살아있음'으로 허용
    )
    $ok = $false
    $detail = ''
    try {
        $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 15 -Headers $Headers
        if ($AcceptCodes -contains [int]$r.StatusCode) {
            if ($MustContain -and ($r.Content -notmatch [regex]::Escape($MustContain))) {
                $detail = "$([int]$r.StatusCode) 이지만 기대 문자열('$MustContain') 없음"
            } else {
                $ok = $true
                $detail = "HTTP $([int]$r.StatusCode)"
            }
        } else {
            $detail = "HTTP $([int]$r.StatusCode)"
        }
    } catch {
        $code = $null
        if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
        if ($code -and ($AcceptCodes -contains $code)) {
            $ok = $true
            $detail = "HTTP $code (서비스 응답 확인)"
        } elseif ($code) {
            $detail = "HTTP $code"
        } else {
            $detail = $_.Exception.Message
        }
    }
    if ($ok) {
        Write-Host ("[OK]   {0} - {1}" -f $Name, $detail) -ForegroundColor Green
    } else {
        Write-Host ("[FAIL] {0} - {1}" -f $Name, $detail) -ForegroundColor Red
        Write-Host ("       {0}" -f $Url) -ForegroundColor DarkGray
        $script:fail++
    }
}

Write-Host "=== 책글귀 출시 상태 점검 $(Get-Date -Format 'yyyy-MM-dd HH:mm') ===" -ForegroundColor Cyan

# 1) Play 스토어 페이지 (게시 상태 + 개발자 웹사이트 링크 존재)
Test-Http -Name "Play 스토어 페이지" `
    -Url "https://play.google.com/store/apps/details?id=io.github.tgparkk.bookquote&hl=ko" `
    -MustContain "tgparkk.github.io"

# 2) app-ads.txt (AdMob 인증의 전제 — 내용까지 확인)
Test-Http -Name "app-ads.txt" `
    -Url "https://tgparkk.github.io/app-ads.txt" `
    -MustContain "pub-7230084799824817"

# 3) 법적 문서 (스토어 등록정보가 참조)
Test-Http -Name "개인정보처리방침" -Url "https://tgparkk.github.io/bookquote/privacy/"
Test-Http -Name "이용약관"         -Url "https://tgparkk.github.io/bookquote/terms/"

# 4) Supabase (.env.json에서 URL/키 로드 — 값은 출력하지 않음)
$envPath = Join-Path $PSScriptRoot '..\.env.json'
if (Test-Path $envPath) {
    $env_ = Get-Content $envPath -Raw | ConvertFrom-Json
    $headers = @{ apikey = $env_.SUPABASE_ANON_KEY }
    Test-Http -Name "Supabase Auth health" -Url ($env_.SUPABASE_URL + "/auth/v1/health") -Headers $headers
    # REST 루트는 신형 publishable 키로 401을 주지만, 401 응답 자체가 게이트웨이
    # 정상 가동의 증거 — 가용성 체크이므로 200/401 모두 통과로 본다.
    Test-Http -Name "Supabase REST(가용성)" -Url ($env_.SUPABASE_URL + "/rest/v1/") -Headers $headers -AcceptCodes @(200, 401)
} else {
    Write-Host "[SKIP] Supabase - .env.json 없음 (리포 루트에서 실행했는지 확인)" -ForegroundColor Yellow
}

Write-Host ""
if ($script:fail -eq 0) {
    Write-Host "모든 자동 점검 통과." -ForegroundColor Green
} else {
    Write-Host "$($script:fail)건 실패 — 위 [FAIL] 항목을 확인하세요." -ForegroundColor Red
}

Write-Host ""
Write-Host "-- 수동 점검 (로그인 필요, 출시 첫 주 매일) --" -ForegroundColor Cyan
Write-Host "  Android vitals : https://play.google.com/console/u/0/developers/7910626417257295631/app/4974877844432261185/vitals/crashes"
Write-Host "  Crashlytics    : https://console.firebase.google.com"
Write-Host "  AdMob 수익     : https://apps.admob.com"
Write-Host "  정책 상태      : https://play.google.com/console/u/0/developers/7910626417257295631/app/4974877844432261185/policy-status"

exit $script:fail
