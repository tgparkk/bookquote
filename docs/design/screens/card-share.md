# 화면 설계 — 카드 공유·저장 시트

> 그룹 1 · Stage 3/4. 카드 에디터의 "공유" → 모달 시트. 입력 근거: `competitor-screen-analysis §5.3`, QA-2 / Dart-2, `flows.md Flow B 4.1`. 바이럴 K-factor의 출구 — 받는 쪽은 `deep-link-receive.md`.

---

## 1. 목적 / 진입·이탈

- **목적**: 만든 카드를 가장 빠르게 단톡방에 쏜다. 1순위 = 카카오톡(단톡방), 2 = 인스타 스토리(9:16 자동), 3 = 이미지 저장. 북모리는 OS 공유 시트만(양방향 0) — 우리는 카톡 단톡방을 1급으로 올리고, 받는 사람이 카드를 탭하면 deep link로 책 담기까지 이어지게 한다.
- **진입**: 카드 에디터 우상단 "공유" 탭 → PNG 생성(로딩) → 시트 슬라이드업.
- **이탈**: 공유 앱 선택(카톡/인스타/저장/기타 OS 앱) → 시트 닫힘 → 에디터로 복귀(에디터 유지) / 시트 dismiss(드래그 다운·바깥 탭·뒤로) → 아무것도 안 일어남, 에디터 유지.

---

## 2. 와이어프레임

```
        ┌────────── (어둑한 backdrop) ──────────┐
        │              ┌──────┐                │   (위에 카드 미리보기 살짝 보임)
        │              │ 카드  │                │
        │              └──────┘                │
        ├───────────────────────────────────────┤
        │              ────                     │   드래그 핸들 (_DragHandle 재사용)
        │  ┌─────────────────────────────────┐  │
        │  │ 💬  카카오톡 단톡방으로 보내기  │  │   Primary — 카카오 노랑 #FEE500 / 검정 텍스트
        │  └─────────────────────────────────┘  │
        │  ┌─────────────────────────────────┐  │
        │  │ 📷  인스타그램 스토리 (9:16)    │  │   Secondary — outlined
        │  └─────────────────────────────────┘  │
        │  ┌─────────────────────────────────┐  │
        │  │ ⬇  이미지 저장      [권한 필요] │  │   Secondary — 권한 거부 시 비활성 + 뱃지
        │  └─────────────────────────────────┘  │
        │  ┌─────────────────────────────────┐  │
        │  │ ⋯  다른 앱으로 공유             │  │   OS share sheet 호출 (share_plus)
        │  └─────────────────────────────────┘  │
        │   저장 권한 없어도 공유는 그대로 — 막다른 골목 없음   │
        └───────────────────────────────────────┘
```

V1 단순화: "카카오톡 단톡방으로 보내기"·"인스타 스토리"·"다른 앱"은 모두 **`share_plus` OS share sheet**로 시작(카카오/인스타 SDK·OAuth 불필요, 셋업 0 — 사용자가 OS 시트에서 해당 앱 선택). 시트 안에서 우리가 미리 라벨링한 버튼은 "이 경로를 권장한다"는 안내 + 분석 이벤트용. **카카오 SDK 메시지 카드 형태 공유**(이미지+제목+deep link 버튼 카드)는 V1.1 — 그땐 Kakao Developers 앱 등록 + Android `<queries>`(카카오톡 패키지) / iOS `LSApplicationQueriesSchemes`(`kakaolink`) 추가가 묶여 옴. 카카오 *공유*는 카카오 *로그인*(V1.5)과 독립.

---

## 3. 상태

| 상태 | 처리 | 표시 | 심각도 |
|---|---|---|---|
| 로딩: PNG 생성 (시트 열기 전) | 카드 에디터 §3 L5 — 버튼 spinner / 모달-lite "카드 만드는 중…" | Modal-lite | 중간 |
| 로딩: 공유 시트 등장 대기 | 버튼 spinner 유지, OS 시트 뜨면 해제 | — | 낮음 |
| 빈 | 해당 없음 (카드는 항상 있음 — 에디터에서 옴) | — | — |
| 에러: PNG 생성 실패 (OOM 등) | 시트 열지 않음 → 에디터로 Toast "카드 만들기에 실패했어요. 다시 시도" + 디자인 유지. 재시도 시 1080→720 폴백 | Toast | **높음** |
| 에러: 카카오톡 미설치 | OS share sheet엔 자동으로 안 뜸(무해). "카카오톡으로 보내기" 전용 버튼(V1.1)이면 `canLaunchUrl(kakaolink://)` 체크 후 없으면 "카카오톡이 설치되어 있지 않아요" + [이미지 저장] 대안. **크래시 금지** | Toast | 중간 |
| 에러: 인스타 미설치 / 인스타가 이미지 거부 | OS 시트에 안 뜸. PNG가 인스타 스토리 규격(9:16, ≤30MB) 충족하도록 export. 실패 시 일반 OS 시트로 | (조용히) | 낮음 |
| 에러: 갤러리 저장 권한 거부 | **[이미지 저장]만 비활성 + [권한 필요] 뱃지 + [설정 열기], 나머지 버튼은 활성** + "공유는 그대로 할 수 있어요". iOS add-only(`NSPhotoLibraryAddUsageDescription`) / Android 11+ scoped storage(권한 불필요, `MediaStore` IS_PENDING) / Android 9↓ `WRITE_EXTERNAL_STORAGE`. **전체 시트를 막지 않는다** | 부분 비활성 + Toast | **높음** |
| 에러: 디스크 가득 (PNG 임시파일 쓰기 실패) | "저장 공간이 부족해요. 사진·앱을 정리하고 다시 시도" Toast. 디자인 유지 | Toast | 중간 |
| 에러: 네트워크 끊긴 상태로 공유 | **공유 자체는 됨**(PNG 로컬, OS 시트 로컬). `cards` 히스토리 INSERT만 큐로/skip. 사용자에겐 "성공"으로 보임 | (조용히) | 중간 |
| 공유 시트 취소 (아무 앱 안 고름) | `ShareResult.dismissed` = **에러 아님**. Toast 없음. 에디터 유지. `cards` 히스토리 저장 안 함(공유 안 했으므로) | (무표시) | 낮음 |

---

## 4. 인터랙션

- 시트 = `showModalBottomSheet`(`AppTheme.bottomSheetTheme` — 상단 둥글게, backdrop). `_DragHandle` 재사용. 드래그 다운/바깥 탭/뒤로 = dismiss(아무 일 없음).
- 버튼 탭 → `share_plus.shareXFiles([XFile(pngPath)], text: 셰어 카피)`. 셰어 카피(선택) = 인용구 + 책 제목 + (deep link URL — V1.1엔 카카오 메시지 카드에 deep link 버튼; V1엔 텍스트로 URL 첨부 가능하나 클릭 가능 링크 보장 X).
- 인스타 스토리: `share_plus`로 OS 시트 → 사용자가 "Instagram → 스토리" 선택. (인스타 link sticker는 2024부터 팔로워 수 조건 없이 전체 개방 — V1.1에 시도, 안 되면 텍스트 워터마크만으로.)
- "이미지 저장": `gal` 패키지(또는 V1은 OS 시트의 "이미지 저장"으로 커버하고 명시적 버튼은 V1.1). 성공 시 "사진에 저장됐어요" Toast.
- 공유 성공 후 분석: `card_shared {template, ratio, target}` — 단 OS 시트는 사용자가 뭘 골랐는지 대부분 안 알려줌(`ShareResult.raw`/`activityType`은 iOS만 부분) → `target='unknown'`도 허용. (PII 없음 — 인용구 텍스트 미전송, 템플릿 ID·비율만.)
- 같은 카드 연속 공유 = 매번 새 PNG 또는 직전 PNG 캐시(5s 윈도우) 재사용. 둘 다 OK.

---

## 5. 토큰

| 영역 | 토큰 |
|---|---|
| 시트 | `AppTheme.bottomSheetTheme` — `secondary100` 배경, 상단 `AppRadius.lg`, backdrop `primary900` @ ~0.45 |
| 드래그 핸들 | `_DragHandle` (book_search_sheet.dart에 있음) — `primary200`, 32×4 |
| 카카오톡 버튼 | 배경 `#FEE500`(카카오 브랜드 — 토큰 외 예외), 텍스트 `#191919` ui w600 14, `AppRadius.md` |
| 인스타·저장·다른앱 버튼 | outlined: border 1.5 `primary200`, 텍스트 `primary700` ui 14, `AppRadius.md` / 비활성 시 `secondary600` 배경·`primary400` 텍스트 |
| [권한 필요] 뱃지 | `semanticWarningLight` 배경 / `semanticWarning` 텍스트 xxs |
| 안내 카피 | ui xxs `primary400`, 중앙 |

---

## 6. 재사용 / 신규

**재사용**: `_DragHandle`(book_search_sheet.dart), `AppTheme.bottomSheetTheme`, `card_renderer.dart`(`card-editor.md` 신규)의 `renderCardPng`.
**신규**: `lib/features/card_editor/presentation/widgets/share_sheet.dart` (`showCardShareSheet(context, pngPath, cardMeta)`), `lib/features/card_editor/data/share_service.dart` (`shareCard`, `saveToGallery`). `pubspec.yaml`: `share_plus`·`path_provider`(필수, `card-editor.md`와 공유), `gal`(저장 버튼). `cards` 테이블 INSERT는 `quote_repository`/별도 `card_repository`.

---

## 7. 엣지 / 접근성

**교차 관심사**: ④ 막다른 골목 금지 = 이 화면의 핵심 — 어떤 권한 거부·미설치에도 최소 하나의 공유/저장 경로가 살아있다, 광고 0. ② 데이터 유실 = 카드는 PNG 로컬에 있고 인용구는 DB → 안전. ③ PII = 인용구 텍스트는 공유 *콘텐츠*로는 나가지만 *로그*엔 안 들어감. ⑥ 에러 표시 일관성. ⑧ 해당 없음.

| 엣지 | 심각도 | 처리 |
|---|---|---|
| 사진 라이브러리 권한 "한 번만 허용"(iOS) → 다음에 또 물음 | 낮음 | 매번 묻는 게 정상. 누적되면 "설정에서 항상 허용으로" 힌트 1회 |
| Android 13+ `READ_MEDIA_IMAGES`(읽기)와 쓰기 권한 혼동 | 낮음 | 저장만 한다면 권한 요청 자체 생략(`MediaStore` IS_PENDING 패턴) |
| PNG가 인스타 스토리 규격 초과(>30MB, 잘못된 비율) | 낮음 | export를 9:16 1080×1920 PNG로 고정 → 규격 내. 초과할 일 없음 |
| 워터마크 OFF인데 deep link도 빠짐 | 중간 | 워터마크 OFF여도 카카오 메시지 카드(V1.1)의 deep link 버튼은 별도 — OFF 영향 안 받게 설계. V1(텍스트 공유)은 셰어 카피에 URL 포함 옵션 |
| 공유했는데 카톡이 전송 실패(카톡 쪽 오프라인) | 낮음 | 그건 카톡 책임 — 우리 쪽은 "공유 시트 전달 완료"까지만 책임 |

**접근성**: 모든 버튼 ≥48dp, 라벨 명확("카카오톡 단톡방으로 보내기" — 아이콘만 아님). 카카오 노랑(#FEE500) on 검정 텍스트 = 대비 충분. 시트 열릴 때 포커스를 시트로 이동(스크린리더), 닫힐 때 에디터로 복귀. 비활성 [이미지 저장]에 `'이미지 저장, 사진 권한이 필요합니다, 두 번 탭하면 설정으로 이동'`.

---

## 변경 이력
- 2026-05-11 초안 (매니저 종합 — competitor-screen-analysis §5.3 + QA-2 + Dart-2 + flows.md Flow B).
