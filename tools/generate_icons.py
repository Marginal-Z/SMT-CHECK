"""Package the finished artwork; only resize and convert to platform formats.

The rounded transparent silhouette is part of the supplied PNG, not drawn here.
Requires Pillow. Run from PowerShell 7 / Python or WSL Ubuntu / Python 3.
"""
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent.parent
image = Image.open(root / 'assets/icons/app_icon.png').convert('RGBA')
if image.width != image.height or image.width < 1024:
    raise ValueError('The source icon must be square and at least 1024 pixels.')
if any(image.getpixel(p)[3] != 0 for p in [(0, 0), (0, image.height-1), (image.width-1, 0), (image.width-1, image.height-1)]):
    raise ValueError('The rounded icon must have transparent outer corners.')

sizes = [(size, size) for size in (16, 24, 32, 48, 64, 128, 256)]
image.save(root / 'windows/runner/resources/app_icon.ico', sizes=sizes)
for size in (16, 32, 64, 128, 256, 512, 1024):
    image.resize((size, size), Image.Resampling.LANCZOS).save(
        root / f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png')
image.resize((256, 256), Image.Resampling.LANCZOS).save(root / 'docs/app-icon.png')

# Inno Setup requires opaque BMPs. Place the same icon on its white canvases.
for name, canvas_size, icon_size in [('wizard-large.bmp', (164, 314), 144), ('wizard-small.bmp', (55, 55), 55)]:
    bitmap = Image.new('RGB', canvas_size, 'white')
    icon = image.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    bitmap.paste(icon, ((canvas_size[0]-icon_size)//2, (canvas_size[1]-icon_size)//2), icon)
    bitmap.save(root / 'installer' / name)
print('Packaged Windows ICO, macOS PNGs, Linux menu PNG and installer bitmaps.')
