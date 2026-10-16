"""Generate the code-native black/white app monogram; no external artwork."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root=Path(__file__).resolve().parent.parent
image=Image.new('RGBA',(1024,1024),(255,255,255,0))
draw=ImageDraw.Draw(image)
draw.rounded_rectangle((24,24,1000,1000),radius=180,fill='#171717')
draw.rounded_rectangle((165,165,859,859),radius=75,outline='white',width=35)
for point in (300,440,580,720):
    for box in ((point-18,94,point+18,177),(point-18,847,point+18,930),(94,point-18,177,point+18),(847,point-18,930,point+18)):
        draw.rectangle(box,fill='white')
font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',375)
draw.text((512,520),'SC',font=font,fill='white',anchor='mm')
image.save(root/'windows/runner/resources/app_icon.ico',sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
for size in (16,32,64,128,256,512,1024):
    image.resize((size,size),Image.Resampling.LANCZOS).save(root/f'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_{size}.png')
image.resize((256,256),Image.Resampling.LANCZOS).save(root/'docs/app-icon.png')
