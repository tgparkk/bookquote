"""북로그 Play Store 자산 생성 — 앱 아이콘(512x512) + 피처 그래픽(1024x500).

브랜드 톤(Ink-Paper-Copper): 크림 종이 배경 위 잉크 책 + 카퍼 태그라인.
실행: python tool/generate_store_assets.py   (저장소 루트에서)
출력:
  tool/store/play_icon_512.png             512x512 스토어 아이콘
  tool/store/feature_graphic_1024x500.png  1024x500 피처 그래픽
"""

import os

from PIL import Image, ImageDraw, ImageFont

BG = (0xFD, 0xF6, 0xED)      # #FDF6ED 따뜻한 크림
INK = (0x1C, 0x19, 0x17)     # #1C1917 잉크 블랙
COPPER = (0xB8, 0x73, 0x33)  # #B87333 카퍼 액센트

OUT_DIR = "tool/store"
PRETENDARD_SB = "assets/fonts/pretendard/Pretendard-SemiBold.otf"
PRETENDARD_MD = "assets/fonts/pretendard/Pretendard-Medium.otf"


def make_icon() -> None:
    """512x512 스토어 아이콘 — 레거시 런처 아이콘(크림 배경)을 다운스케일."""
    src = Image.open("assets/icon/icon.png").convert("RGB")
    icon = src.resize((512, 512), Image.LANCZOS)
    out = os.path.join(OUT_DIR, "play_icon_512.png")
    icon.save(out)
    print(f"saved {out} {icon.size}")


def make_feature_graphic() -> None:
    """1024x500 피처 그래픽 — 크림 배경 + 책 아이콘 + 워드마크 + 태그라인.

    책 아이콘과 (워드마크+태그라인) 텍스트 블록을 한 그룹으로 가로 중앙,
    각 요소는 세로 중앙 정렬. 4배 supersampling으로 텍스트 안티앨리어싱.
    """
    width, height = 1024, 500
    ss = 4
    cw, ch = width * ss, height * ss
    img = Image.new("RGB", (cw, ch), BG)
    draw = ImageDraw.Draw(img)

    book_sz = 280 * ss
    gap = 70 * ss
    wordmark_font = ImageFont.truetype(PRETENDARD_SB, 122 * ss)
    tagline_font = ImageFont.truetype(PRETENDARD_MD, 38 * ss)
    wordmark = "북로그"
    tagline = "책 속 한 줄을 모으는 곳"

    wm_box = draw.textbbox((0, 0), wordmark, font=wordmark_font)
    tg_box = draw.textbbox((0, 0), tagline, font=tagline_font)
    wm_w, wm_h = wm_box[2] - wm_box[0], wm_box[3] - wm_box[1]
    tg_w, tg_h = tg_box[2] - tg_box[0], tg_box[3] - tg_box[1]

    text_w = max(wm_w, tg_w)
    group_w = book_sz + gap + text_w
    group_x = (cw - group_w) // 2

    # 책 아이콘(투명 전경) — 그룹 왼쪽, 세로 중앙
    book = Image.open("assets/icon/icon_foreground.png").convert("RGBA")
    book = book.resize((book_sz, book_sz), Image.LANCZOS)
    img.paste(book, (group_x, (ch - book_sz) // 2), book)

    # 텍스트(워드마크 + 태그라인) 스택 — 그룹 오른쪽, 세로 중앙
    text_x = group_x + book_sz + gap
    inner_gap = 24 * ss
    stack_h = wm_h + inner_gap + tg_h
    top = (ch - stack_h) // 2
    draw.text((text_x - wm_box[0], top - wm_box[1]), wordmark,
              font=wordmark_font, fill=INK)
    draw.text((text_x - tg_box[0], top + wm_h + inner_gap - tg_box[1]),
              tagline, font=tagline_font, fill=COPPER)

    img = img.resize((width, height), Image.LANCZOS)
    out = os.path.join(OUT_DIR, "feature_graphic_1024x500.png")
    img.save(out)
    print(f"saved {out} {img.size}")


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    make_icon()
    make_feature_graphic()


if __name__ == "__main__":
    main()
