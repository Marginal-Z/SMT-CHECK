# 应用图标

用户提供的芯片和对勾图案，经内置 image_gen 图像编辑工具处理为透明四角的圆角矩形图标。最终图稿保存在 `assets/icons/app_icon.png`，保留原图的蓝色、青绿色和明暗效果；这些图稿效果不作为界面背景渐变使用。

`tools/generate_icons.py` 仅执行尺寸和平台格式转换，生成 Windows 多尺寸 ICO、macOS PNG、Linux 菜单 PNG，以及安装程序所需 BMP；不会重新绘制或修改图标主体。需要 Python 3 和 Pillow，在 PowerShell 7 或 WSL Ubuntu 中执行 `python tools/generate_icons.py`（WSL 使用 `python3`）。

最终编辑提示词：

> Edit target: the supplied SMT-CHECK chip/checkmark artwork. Make a production desktop application icon from this exact artwork. Preserve the central microchip, all circuit traces and pins, the cyan-to-blue checkmark, composition, original dark navy background inside the icon, and existing lighting/shading. Change ONLY the outer canvas silhouette: a square-canvas rounded rectangle (rounded square), with clean smoothly antialiased corners about 18% of the icon width in radius and a small consistent transparent outer margin. Outside the rounded rectangle must be true transparent alpha, not white, not a checkerboard. Keep the entire artwork legible and centered; do not crop off any circuit trace tips. No extra text, no letters, no badge, no new border, no external shadow, no recoloring toward purple, and no additional decoration. Deliver one 1024x1024 RGBA application icon.
