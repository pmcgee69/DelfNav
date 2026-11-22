"""A screen recording of the IDE, at 5 frames a second: when the window changes, when the CodeInsight status
text changes, and how full its progress bar is. ffmpeg gives raw RGB, so no imaging library.
usage: timeline.py <ffmpeg.exe> <video> <out-dir>"""
import hashlib, pathlib, subprocess, sys

ff, video, out = sys.argv[1], sys.argv[2], pathlib.Path(sys.argv[3])
FPS = 5
W, H = 1336, 1350


def frames(vf, w, h):
    raw = subprocess.run([ff, '-hide_banner', '-loglevel', 'error', '-i', video, '-vf', vf,
                          '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], capture_output=True, check=True).stdout
    n = w * h * 3
    return [raw[i:i + n] for i in range(0, len(raw) - n + 1, n)]


# the status line, text and bar, in the full-size frame (from the 1280-wide stills x 1.044)
TX, TY, TW, TH = 565, 1100, 590, 34          # "CodeInsight: Loading LSIF [vcl.lsif] 43%"
BX, BY, BW, BH = 1202, 1104, 120, 18         # the progress bar
text = frames(f'fps={FPS},crop={TW}:{TH}:{TX}:{TY}', TW, TH)
bar = frames(f'fps={FPS},crop={BW}:{BH}:{BX}:{BY}', BW, BH)
whole = frames(f'fps={FPS},scale=64:64', 64, 64)


def filled(b):
    """the bar's green share: columns whose middle row is green-ish"""
    row = BH // 2
    cols = 0
    for x in range(4, BW - 4):
        r, g, bl = b[(row * BW + x) * 3:(row * BW + x) * 3 + 3]
        if g > 150 and g > r and g > bl + 40:
            cols += 1
    return cols / (BW - 8)


def diff(a, b):
    return sum(abs(x - y) for x, y in zip(a, b)) / len(a)


prev_t = prev_w = None
marks = []
for i, (t, b, w) in enumerate(zip(text, bar, whole)):
    sec = i / FPS
    h = hashlib.md5(t).hexdigest()[:8]
    dw = diff(w, prev_w) if prev_w else 0
    change = []
    if prev_w and dw > 6:
        change.append(f'window changes ({dw:.0f})')
    if prev_t and h != prev_t:
        change.append('status text changes')
    print(f'{sec:5.1f}s  bar {filled(b):4.0%}  text {h}  ' + '; '.join(change))
    if change or i == 0:
        marks.append(i)
    prev_t, prev_w = h, w
# the status line at each change, one PNG per mark, to read by eye
for i in marks:
    subprocess.run([ff, '-hide_banner', '-loglevel', 'error', '-y', '-i', video, '-vf',
                    f'fps={FPS},select=eq(n\\,{i}),crop={TW + BW + 60}:{TH}:{TX}:{TY}',
                    '-frames:v', '1', str(out / f'status_{i:03d}.png')], check=True)
print('marks', marks)
