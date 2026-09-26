"""내부 테스트 트랙의 최신 버전을 프로덕션으로 승격한다 (재빌드·재업로드 없음).

GitHub Actions `play-release.yml`의 `action=promote`가 호출한다. 내부 테스트에서
확인한 바로 그 AAB(versionCode)를 프로덕션 트랙 release로 지정 → edit commit.

- 출시 비율 ROLLOUT: 1 = 전체(completed), 0 < r < 1 = 단계적 출시(inProgress).
- 같은 versionCode가 이미 프로덕션 단계적 출시 중이면 비율만 올린다(낮추기 금지).
  이미 100%면 아무것도 안 하고 실패 처리.
- 출시 노트는 내부 테스트 release의 것을 그대로 복사한다.
- commit이 "자동으로 검토에 보낼 수 없음"으로 거부되면 changesNotSentForReview=True로
  다시 commit — 이때는 Play Console 게시 개요에서 [검토를 위해 전송]을 직접 눌러야 한다.

환경변수: PLAY_SERVICE_ACCOUNT_JSON(서비스 계정 JSON 원문) 또는
GOOGLE_APPLICATION_CREDENTIALS(JSON 파일 경로), ROLLOUT(기본 1).
로컬 확인: python tool/play_promote.py --dry-run  (edit를 만들었다 버린다 — 반영 없음)

셋업·권한: docs/ops/play-release-setup.md
"""

import json
import os
import sys

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

PACKAGE = "io.github.tgparkk.bookquote"
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def _credentials():
    raw = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON")
    if raw:
        info = json.loads(raw)
        return service_account.Credentials.from_service_account_info(
            info, scopes=SCOPES
        )
    path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if path:
        return service_account.Credentials.from_service_account_file(
            path, scopes=SCOPES
        )
    sys.exit("서비스 계정 정보 없음: PLAY_SERVICE_ACCOUNT_JSON 또는 "
             "GOOGLE_APPLICATION_CREDENTIALS 필요")


def _rollout():
    try:
        r = float(os.environ.get("ROLLOUT", "1"))
    except ValueError:
        sys.exit("ROLLOUT은 0보다 크고 1 이하인 숫자여야 함")
    if not 0 < r <= 1:
        sys.exit("ROLLOUT은 0보다 크고 1 이하인 숫자여야 함")
    return r


def _max_code(release):
    return max(int(c) for c in release.get("versionCodes", ["0"]))


def main():
    dry_run = "--dry-run" in sys.argv
    rollout = _rollout()
    edits = build(
        "androidpublisher", "v3", credentials=_credentials(),
        cache_discovery=False,
    ).edits()
    edit_id = edits.insert(packageName=PACKAGE, body={}).execute()["id"]

    def track(name):
        return edits.tracks().get(
            packageName=PACKAGE, editId=edit_id, track=name
        ).execute().get("releases", [])

    internal = [r for r in track("internal") if r.get("versionCodes")]
    if not internal:
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()
        sys.exit("내부 테스트 트랙에 release가 없음")
    source = max(internal, key=_max_code)
    code = _max_code(source)

    production = track("production")
    same = [r for r in production if code in
            [int(c) for c in r.get("versionCodes", [])]]
    print(f"내부 테스트 최신: {source.get('name')} (versionCode {code})")
    print("현재 프로덕션: " + (", ".join(
        f"{r.get('name')}[{r.get('status')}"
        + (f" {r.get('userFraction')}" if r.get("userFraction") else "") + "]"
        for r in production) or "없음"))

    if same:
        current = same[0]
        if current.get("status") == "completed":
            edits.delete(packageName=PACKAGE, editId=edit_id).execute()
            sys.exit(f"versionCode {code}는 이미 프로덕션 100% 출시됨")
        old = float(current.get("userFraction", 0))
        if rollout < old:
            edits.delete(packageName=PACKAGE, editId=edit_id).execute()
            sys.exit(f"출시 비율은 낮출 수 없음 (현재 {old} → 요청 {rollout})")

    release = {
        "name": source.get("name"),
        "versionCodes": [str(code)],
        "releaseNotes": source.get("releaseNotes", []),
        "status": "completed" if rollout >= 1 else "inProgress",
    }
    if rollout < 1:
        release["userFraction"] = rollout
    label = "100%" if rollout >= 1 else f"{rollout:.0%} 단계적"
    print(f"→ 프로덕션 {label} 출시: versionCode {code}")

    if dry_run:
        edits.delete(packageName=PACKAGE, editId=edit_id).execute()
        print("(dry-run) edit를 버렸습니다 — Play Console 변경 없음")
        return

    edits.tracks().update(
        packageName=PACKAGE, editId=edit_id, track="production",
        body={"track": "production", "releases": [release]},
    ).execute()
    try:
        result = edits.commit(packageName=PACKAGE, editId=edit_id).execute()
        print(f"완료 — 검토 제출됨 (edit {result.get('id')})")
    except HttpError as e:
        if "changesNotSentForReview" not in str(e):
            raise
        result = edits.commit(
            packageName=PACKAGE, editId=edit_id, changesNotSentForReview=True
        ).execute()
        print(f"완료 — 단, 자동 검토 제출이 막혀 있음 (edit {result.get('id')}). "
              "Play Console → 게시 개요 → [검토를 위해 변경사항 전송]을 눌러야 함")


if __name__ == "__main__":
    main()
