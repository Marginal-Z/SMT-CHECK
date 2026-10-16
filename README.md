# SMT-CHECK

[![Windows and Linux builds](https://github.com/Marginal-Z/SMT-CHECK/actions/workflows/desktop.yml/badge.svg)](https://github.com/Marginal-Z/SMT-CHECK/actions/workflows/desktop.yml)

用于 T100-BOM 与 SMT 站位表原始 `.xlsx` 的双向核对桌面应用。使用 Flutter / Dart，提供 Windows、macOS、Linux 运行器。界面采用桌面侧栏、工具栏、可滚动数据表和证据详情，默认浅色，支持深色；禁用 Material 3，没有渐变或紫色。

## 功能

- 单站位表核对；A+B 合并核对。
- 自动定位工作表和四个必需表头，保持原文件只读。
- 字段对应：料件编号 ↔ 料号，品名 ↔ 物料描述，组成用量 ↔ 数量，插件位置 ↔ 位号。
- 同料号跨行、跨面汇总，双向报告缺料、多料、描述差异、数量差异、位号缺失/多出、重复位号及归属冲突。
- 绿色一致、红色异常；可按状态和料号、位号、原因搜索。
- 顶部显示料号总数量、BOM 料号数量和 SMT 站位表料号数量。按去掉首尾空白、统一大小写后的非空料号去重，包含已排除和候选料；总数量为 BOM 与 SMT 的并集，A+B 重复料号只计一次，不等同于贴装用量或结果记录数。
- 结果表直接并列显示 BOM 插件位置和 SMT 站位表位号，保留原始分隔符和跨行顺序。长内容可横向滚动、悬停查看或点击行查看完整来源。
- 每个结果保留原始字段、工作表、行号、站位和 A/B 来源。
- 可编辑关键词排除非贴片物料，逐条记录排除原因。默认：锡膏、PCB、助焊剂、包装材料、高温贴纸、碳带。
- 所有命中关键词的来源行直接列入“已排除物料”，保留全部命中词及导入问题，不计入一致数；同料号未命中规则的其他行仍正常核对。筛选入口显示排除记录数，CSV / JSON 同步导出统计、两侧位号和命中词。
- 候选替代料单独审计，不自动继承上一行数量/位号，不自动替换 BOM 料号。
- 导出 CSV（Excel 可打开）和完整 JSON，包含规则和审计记录。
- 可自行填写 Chat Completions 兼容接口地址、模型和 API Key；支持云端 HTTPS 和 localhost HTTP（例如 Ollama）。密钥仅保存在内存，关闭程序后清除。AI 分析前显示数据发送范围，AI 结果不修改确定性核对状态。
- Ctrl+O 导入 BOM，Ctrl+Enter 核对，Ctrl+E 导出 CSV。
- “清空重来”或 Ctrl+N 清除导入文件、结果和 AI 分析，保留语言、主题、规则及接口配置，并使旧异步任务失效。
- 右上角提供中文、English、ไทย 切换，自动保存选择；界面、异常原因和导出报告支持三语，原始 Excel 内容保持原文。随应用提供 Noto Sans Thai 字体及 OFL 许可。

## 安装完整应用

从 [GitHub Releases](https://github.com/Marginal-Z/SMT-CHECK/releases/latest) 直接下载当前版本安装包：

- **Windows x64：`SMT-CHECK-Setup-x64.exe`**。运行安装向导，选择安装目录（可选择 D 盘）；安装完成后从开始菜单启动 SMT-CHECK，可在系统“已安装的应用”中卸载。安装程序自动管理全部运行库和资源，无需解压或手动维护文件。安装向导也提供中、英、泰语言选择。
- **Ubuntu / Debian x64：`SMT-CHECK-linux-amd64.deb`**。通过系统软件安装器打开，安装后在应用菜单启动 SMT-CHECK。

软件本地核对不依赖 Excel、Python 或 AI 服务。当前 Windows 安装程序尚未进行代码签名。

## 下载 GitHub 构建

正式下载入口是上面的 Releases，提供直接下载的 EXE / DEB 安装文件。开发构建也会保存在 [Windows / Linux 构建列表](https://github.com/Marginal-Z/SMT-CHECK/actions/workflows/desktop.yml) 的 **Artifacts** 中，保留 30 天；手动点击 **Run workflow** 或向 `main` 推送源码可生成新的构建。

- `SMT-CHECK-windows-x64`：包含 Windows EXE 安装程序与 SHA256 校验文件。
- `SMT-CHECK-linux-x64`：包含 Linux DEB 安装包与 SHA256 校验文件。

Artifacts 是供开发验证的外层 ZIP；日常安装请直接使用 Releases 的安装文件。

Linux 包在 Ubuntu 22.04 x64 上构建。运行命令在 **WSL Ubuntu / Linux 图形桌面终端** 中执行；WSL 需有 WSLg 图形支持：

```bash
sudo apt install ./SMT-CHECK-linux-amd64.deb
smt-check
# 卸载
sudo apt remove smt-check
```

安装包将应用及资源放入 `/opt/smt-check` 并注册应用菜单，由包管理器管理安装和卸载。当前提供 `.deb`，适用于具备 GTK 3 的 Ubuntu 22.04+ / 兼容 Debian 系统。

## 开发与构建

Flutter 3.47.2 / Dart 3.13.2。安装 Flutter 官方桌面开发依赖。Windows 需要 Visual Studio C++ 桌面开发工具与 Windows SDK；macOS 需要 Xcode；Linux 需要 clang、cmake、ninja-build、pkg-config、libgtk-3-dev。

Windows 开发、测试、打包命令在 **PowerShell 7** 中执行：

```powershell
Set-Location D:\SMT-CHECK
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter run -d windows
# 生成完整发行包
./tools/build-windows.ps1
```

Windows 若未开启开发者模式，且 Flutter 提示插件符号链接权限不足，可在首次 `flutter pub get` 生成插件元数据后，以 **PowerShell 7** 执行 `./tools/prepare-plugin-links.ps1`，再重试 `flutter pub get`。该脚本只在本项目内创建指向 Pub 缓存的目录联接，不修改系统设置。

Windows 安装程序使用 Inno Setup 6.4.3 编译。安装 Inno Setup 后，或将 `ISCC_PATH` 指向 `ISCC.exe`，上述脚本会输出 `dist/SMT-CHECK-Setup-x64.exe`。云端工作流会自动准备编译器。

Linux 开发命令在 **WSL Ubuntu / Linux 终端** 中执行，使用 Linux 版 Flutter SDK，不使用挂载盘中的 Windows SDK：

```bash
cd /mnt/d/SMT-CHECK
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
bash tools/build-linux.sh --skip-checks
```

macOS 构建命令在 **macOS 终端** 中执行：

```bash
flutter pub get
flutter build macos --release
```

`.github/workflows/desktop.yml` 自动执行 Windows / Linux 的静态检查、测试、release 构建、完整安装、启动及卸载检查和制品上传。macOS 保留源码运行器，需要在 Mac 上另行构建验证。

可在 **PowerShell 7** 通过参数直接导入并核对文件：

```powershell
& "$env:LOCALAPPDATA/Programs/SMT-CHECK/SMT-CHECK.exe" --bom 'D:/资料/BOM.xlsx' --a 'D:/资料/站位A.xlsx' --b 'D:/资料/站位B.xlsx'
# 单表省略 --b
```

## 核对边界

- 单表与完整 BOM 比较，未覆盖另一面仍明确列为异常，不自动缩小 BOM 范围。
- 描述仅忽略空白与英文大小写，规格、品牌、封装、公差和符号差异不会自动视为等效。
- 排除记录和候选料不计入一致数。关键词可能覆盖过宽，应查看排除列表。
- 支持逗号/空格/分号/中文分隔符、数字前缀位号、下划线子位号、R1-R4 与 R1~R4 区间。T100 的数字续接折行会还原；未知格式会显式报错。
- 支持缓存公式值并记录审计说明，不执行 Excel 公式、宏或单元格内指令。没有公式缓存值会提示重算保存。
- 不读取图片、批注或隐藏附件中的物料数据；仅对识别到四个必需表头的数据区域核对，工作表覆盖在导入审计中列明。
- 当前支持 `.xlsx`，旧版 `.xls` 请先转换。

## 参考数据验证

公开测试使用合成数据，覆盖双向核对、排除规则、位号解析、Excel 读取、后台任务、AI 接口与窗口布局。真实参考 Excel、实际核对报告和本地验证明细不纳入公开仓库。AI 真实服务需要用户填写地址、模型和密钥后通过“测试连接”验证。

核心模块：`lib/core/xlsx_reader.dart`（读取），`positions.dart`（位号），`checker.dart`（核对），`lib/services/ai_service.dart`（AI），`report_export.dart`（导出），`lib/ui/`（桌面视觉组件）。
