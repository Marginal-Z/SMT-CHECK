# SMT Fusion 应用图标

图标采用用户提供的“SMT Fusion：BOM到CAD智能生成”插画，包含 BOM、CAD 和 BlueEye FAI-i450 设备。使用 imagegen 的 background-extraction 编辑模式去除外围白色空白并输出圆角透明 PNG，保留内部插画、文字及原图配色。图标插画中的渐变为用户指定图片的一部分；应用界面仍禁用渐变、紫色和 Material 3。

源资源为 `assets/icons/app_icon.png`，各平台共用同一图稿。`tools/generate_icons.py` 仅缩放和编码，生成 Windows ICO、macOS 16–1024 PNG、Linux 菜单 PNG 和安装向导 BMP，不重新绘制插画。

重新生成（PowerShell 7，使用安装了 Pillow 的 Python）：

```powershell
python tools/generate_icons.py
```

最终编辑提示词：

> Clean up ONLY the outer silhouette alpha of this SMT Fusion application icon. Make its outside edge a single perfectly smooth rounded rectangle with clean antialiased corners, with no white outside margin. Keep all content inside the rounded rectangle unchanged, including original machine, documents, text and colors. Output transparent square PNG at least 1024x1024.

尺寸与透明角、Windows ICO 多尺寸及 macOS/Linux 资源由 `test/appearance_test.dart` 验证。
