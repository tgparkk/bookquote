"""책글귀 Play Store 스크린샷 정규화 — 9:16(세로) 비율로 패딩.

휴대전화 스크린샷은 보통 9:16보다 길어(예: 968x2376 = 2.46:1) Play Console의
'9:16 또는 16:9 + 각 면 320~3840px' 규칙에 걸린다. 콘텐츠를 자르지 않고
좌우에 크림(#FDF6ED) 패딩을 더해 9:16에 맞춘다.

입력: tool/screenshot/*.jpg|*.jpeg|*.png  (출력 폴더 store/ 는 자동 제외)
출력: tool/screenshot/store/play_NN.png
실행: python tool/process_screenshots.py   (저장소 루트에서)
"""

import os

from PIL import Image

BG = (0xFD, 0xF6, 0xED)        # #FDF6ED 따뜻한 크림
SRC_DIR = "tool/screenshot"
OUT_DIR = "tool/screenshot/store"
TARGET = 9 / 16                # width / height (세로 9:16)


def normalize(path: str, out_path: str) -> tuple[int, int]:
    """이미지를 9:16 캔버스 중앙에 올리고 빈 공간은 크림으로 채운다."""
    im = Image.open(path).convert("RGB")
    w, h = im.size
    if w / h > TARGET:
        # 9:16보다 넓음 → 위아래 패딩
        canvas_w, canvas_h = w, round(w / TARGET)
    else:
        # 9:16보다 김(휴대전화 일반) → 좌우 패딩
        canvas_w, canvas_h = round(h * TARGET), h
    canvas = Image.new("RGB", (canvas_w, canvas_h), BG)
    canvas.paste(im, ((canvas_w - w) // 2, (canvas_h - h) // 2))
    canvas.save(out_path)
    return canvas_w, canvas_h


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    files = sorted(
        f for f in os.listdir(SRC_DIR)
        if os.path.isfile(os.path.join(SRC_DIR, f))
        and f.lower().endswith((".jpg", ".jpeg", ".png"))
    )
    for i, f in enumerate(files, 1):
        out = os.path.join(OUT_DIR, f"play_{i:02d}.png")
        cw, ch = normalize(os.path.join(SRC_DIR, f), out)
        kb = os.path.getsize(out) / 1024
        ratio = round(max(cw, ch) / min(cw, ch), 4)
        print(f"{f} -> {out}  {cw}x{ch}  ratio {ratio}:1  {kb:.0f}KB")


if __name__ == "__main__":
    main()
