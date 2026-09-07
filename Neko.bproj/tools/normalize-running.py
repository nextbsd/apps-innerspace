"""Normalize the generated 4x3 running sheet; requires Pillow.

Keep one scale for all poses, align their left edge and ground baseline, and
quantize the generated red/black/white art to a transparent pixel-art palette.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = Image.open(root / 'neko_running_steps.png').convert('RGB')
poses = []
for index in range(12):
    col, row = index % 4, index // 4
    cell = source.crop((round(col * source.width / 4), round(row * source.height / 3),
                        round((col + 1) * source.width / 4), round((row + 1) * source.height / 3)))
    pixels = []
    for r, g, b in cell.getdata():
        if r > 100 and r > g * 1.5 and r > b * 1.5:
            pixels.append((0, 0, 0, 0))
        elif (r + g + b) / 3 < 128:
            pixels.append((0, 0, 0, 255))
        else:
            pixels.append((255, 255, 255, 255))
    rgba = Image.new('RGBA', cell.size)
    rgba.putdata(pixels)
    box = rgba.getbbox()
    assert box is not None, f'Empty frame {index}'
    poses.append(rgba.crop(box))

# A shared scale prevents the body and head growing/shrinking with each stride.
scale = min(28 / max(p.width for p in poses), 28 / max(p.height for p in poses))
sheet = Image.new('RGBA', (128, 96))
for index, pose in enumerate(poses):
    pose = pose.resize((round(pose.width * scale), round(pose.height * scale)),
                       Image.Resampling.NEAREST)
    sheet.paste(pose, ((index % 4) * 32 + 2, (index // 4) * 32 + 30 - pose.height))
sheet.save(root / 'neko_running_32.png')
assert set(sheet.getdata()) <= {(0, 0, 0, 0), (0, 0, 0, 255), (255, 255, 255, 255)}
print('Saved neko_running_32.png: 128x96, twelve 32x32 RGBA frames')
