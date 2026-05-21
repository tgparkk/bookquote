"""책귀 앱 아이콘 생성 — 펼친 책 + 텍스트 줄.

크림 종이 배경(#FDF6ED) 위 잉크 블랙(#1C1917) 펼친 책 실루엣 + 페이지 글줄.
곡선 외곽선(quadratic bezier) + 4배 supersampling 안티앨리어싱.

두 가지를 생성한다:
  - icon.png            레거시 런처 아이콘 (크림 배경, 책이 정사각 꽉 참)
  - icon_foreground.png Android 적응형 아이콘 전경 (투명 배경, 책이 안전영역 안)
적응형 배경색은 flutter_launcher_icons 설정의 adaptive_icon_background.

실행: python tool/generate_icon.py   (저장소 루트에서)
"""

import os
from PIL import Image, ImageDraw

SIZE = 1024
SS = 4                       # supersample 배율
BG = (0xFD, 0xF6, 0xED)      # #FDF6ED 따뜻한 크림
INK = (0x1C, 0x19, 0x17)     # #1C1917 잉크 블랙


def quad(p0, p1, p2, n=72):
    """2차 베지어 곡선 샘플링."""
    out = []
    for i in range(n + 1):
        t = i / n
        m = 1 - t
        out.append((
            m * m * p0[0] + 2 * m * t * p1[0] + t * t * p2[0],
            m * m * p0[1] + 2 * m * t * p1[1] + t * t * p2[1],
        ))
    return out


def render(out_path, k, bg):
    """k: 책 크기 배율(1.0=레거시 꽉참, 0.70=적응형 안전영역).
       bg: 배경색 튜플 또는 None(투명)."""
    w = SIZE * SS
    if bg is None:
        img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
        ink_fill, line_fill = INK + (255,), BG + (255,)
    else:
        img = Image.new("RGB", (w, w), bg)
        ink_fill, line_fill = INK, bg
    d = ImageDraw.Draw(img)

    u = SS * k
    cx = w / 2
    cy = w / 2 - 21 * u      # 책 실루엣 상하 중심을 캔버스 정중앙에 맞춤

    gutter = 15 * u
    outer_x = 452 * u
    outer_top = cy - 244 * u
    spine_top = cy - 100 * u
    outer_bot = cy + 152 * u
    spine_bot = cy + 286 * u

    def page(sign):           # -1 왼쪽, +1 오른쪽
        gx = cx + sign * gutter
        ox = cx + sign * outer_x
        midx = cx + sign * 232 * u
        top = quad((gx, spine_top), (midx, cy - 284 * u), (ox, outer_top))
        bot = quad((ox, outer_bot), (midx, cy + 250 * u), (gx, spine_bot))
        return top + bot

    d.polygon(page(-1), fill=ink_fill)
    d.polygon(page(+1), fill=ink_fill)

    # 페이지 글줄 — 끝 줄은 짧게(문단 끝), 양 끝 둥글게.
    line_th = 30 * u
    ys = [cy - 78 * u, cy + 20 * u, cy + 118 * u]

    def text_line(p1, p2):
        d.line([p1, p2], fill=line_fill, width=max(1, int(line_th)))
        r = line_th / 2
        for (x, y) in (p1, p2):
            d.ellipse([x - r, y - r, x + r, y + r], fill=line_fill)

    for sign in (-1, 1):
        if sign < 0:
            sx, ex = cx - outer_x + 86 * u, cx - gutter - 60 * u
        else:
            sx, ex = cx + gutter + 60 * u, cx + outer_x - 86 * u
        for i, ly in enumerate(ys):
            last = i == len(ys) - 1
            text_line((sx, ly), (sx + (ex - sx) * (0.56 if last else 1.0), ly))

    img = img.resize((SIZE, SIZE), Image.LANCZOS)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path)
    print(f"saved {out_path}")


def main() -> None:
    # 적응형 전경도 책을 꽉 차게 — flutter_launcher_icons가 xml에서 16% inset을
    # 적용하므로, 이미지를 가득 채워야 inset 후 책이 안전영역을 채운다.
    render("assets/icon/icon.png", 1.0, BG)               # 레거시 (크림 배경)
    render("assets/icon/icon_foreground.png", 1.0, None)  # 적응형 전경 (투명)


if __name__ == "__main__":
    main()
