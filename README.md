# SMT-CHECK

[![Windows and Linux builds](https://github.com/Marginal-Z/SMT-CHECK/actions/workflows/desktop.yml/badge.svg)](https://github.com/Marginal-Z/SMT-CHECK/actions/workflows/desktop.yml)

用于 T100-BOM 与 SMT 站位表原始 `.xlsx` 的双向核对桌面应用。使用 Flutter / Dart，提供 Windows、macOS、Linux 运行器。界面采用顶部功能菜单、紧凑文件栏、大面积数据表及可收起的右侧证据详情，默认浅色和黑色主题色，可选蓝色或绿色，支持深色；禁用 Material 3，界面不使用渐变或紫色。

## 功能

- 新增原生“CAD 坐标”工作区：支持单站位表或 A+B 核对后的 CAD 生成：使用完成核对及人工确认的 BOM，导入原始 XLSX / UTF-8 CSV / TXT 坐标，明确选择 mm / mil / inch，预览并自定义名称导出 FAI-i450 十列 Excel。Bottom 使用已验证的 V1.6 全表 Y 范围镜像和角度 +180°，缺坐标、重复位号、空坐标、数量不符或面别错误会阻止导出；改变来源、单位或人工确认会使旧预览失效。详见 [CAD 坐标使用说明](docs/CAD-COORDINATES.md)。

- 单站位表核对；A+B 合并核对。
- “合并与导出”将站位表 A / B 合并为单工作表 Excel，固定保留“料号、物料描述、数量、位号”四列，支持软件内预览和自定义名称，自动生成 `自定义名称-BOM.xlsx`。
- 合并方式、人工确认与预览入口集中于顶部左侧，文件名、导出按钮及确认进度位于顶部右侧；窄窗口自动换行，标签不浮出边框，顶部内容较多时可独立滚动。
- NG、已排除物料和候选料逐项人工选择“确认纳入合并 / 确认不纳入合并”；全部确认后才能生成预览和导出。确认记录显示时间，原核对类别及统计保持不变。只有 BOM 记录的异常需确认知悉，不补造 SMT 内容；PASS 自动纳入。撤销确认、重新核对、更改模式、文件或规则都会使旧预览失效。
- 合并提供“同料号汇总 / 保留 A+B 明细”。汇总仅合并料号、描述完全一致且数量有效的记录，数量使用十进制精确累加，位号原样拼接并保留重复；其余保留明细。预览可悬停查看来源，导出保留前导零及原始文本，不执行公式，不覆盖原始 Excel。
- 保留系统窗口标题栏的应用图标与名称，内容区直接显示导航，避免重复标识。
- “设置 → 关于与更新 → 检查更新”手动查询 GitHub 最新正式版本，显示当前版本、更新说明及 按操作系统及当前程序架构匹配的 Windows / Linux / macOS 安装包下载入口。版本从已安装程序读取；超时、网络错误及 GitHub 限流均可重试，不会误报已是最新。使用系统浏览器下载完整安装包，不会发送 Excel、AI 配置或密钥。
- 自动定位工作表和四个必需表头，保持原文件只读。
- 字段对应：料件编号 ↔ 料号，品名 ↔ 物料描述，组成用量 ↔ 数量，插件位置 ↔ 位号。
- 同料号跨行、跨面汇总，双向报告缺料、多料、描述差异、数量差异、位号缺失/多出、重复位号及归属冲突。
- 核对状态、筛选及导出统一使用 PASS / NG。PASS 为绿色；NG、已排除物料及候选料使用红色行底和实色状态标记，各自类别和统计保持独立。详情原因使用鲜红色文字。主题色不会改变状态含义，可按状态、料号、位号及原因搜索。
- 在“设置 → 导入与规则”维护排除关键词并查看导入审计；工作台保留原文件导入按钮。设置内另有“关于与更新”和“外观与 AI 接口”，顶部导航为核对工作台、合并与导出、CAD 坐标、AI 分析核对、设置和使用说明。
- 在“设置 → 外观 → 主题色”选择黑色、蓝色或绿色，即时生效并保存选择，不清除已导入文件、核对报告及 AI 分析。
- 使用用户指定的芯片 / 对勾圆角矩形图标，四角透明，覆盖应用顶栏、Windows 程序与安装向导、Linux 菜单图标和 macOS 运行器图标资源。图稿处理与格式转换说明见 [APP-ICON.md](docs/APP-ICON.md)。
- 顶部显示料号总数量、BOM 料号数量和 SMT 站位表料号数量。按去掉首尾空白、统一大小写后的非空料号去重，包含已排除和候选料；总数量为 BOM 与 SMT 的并集，A+B 重复料号只计一次，不等同于贴装用量或结果记录数。
- 默认结果与筛选顺序为全部、PASS、NG、已排除物料、候选料；各类别内部按料号排序。
- 结果表并列显示 BOM 插件位置和 SMT 站位表位号，每个位号独立方框显示，PASS 使用绿色描边，NG、已排除和候选料使用红色描边。每个来源行独立解析，重复项和无效位号仍可见；较多位号通过“+数量”展开完整清单。悬停、详情与导出保留原始分隔符和跨行顺序。
- 工作台使用组合式单表 / A+B 模式切换、主次工具按钮和紧凑导航；文件栏保留完整路径提示和直接导入入口，导出 CSV / JSON 与详情开关集中于结果工具区。
- 每个结果保留原始字段、工作表、行号、站位和 A/B 来源。
- NG 结果提供“查看具体差异”入口，在详情中按料号、描述、数量、位号并列显示 BOM / SMT 原值与来源。描述变化片段和缺失 / 多出位号标红，数量明确说明 SMT 比 BOM 多或少多少；同一位号对应不同料号时同时列出两侧料号，不自动认定为替代料。
- 描述仅忽略大小写和空白，原文不被修改。多行描述冲突会列出全部描述及原始行，避免随意一一配对；CSV 的“字段差异”和 JSON 的 `fieldDifferences` 同步保留原值、差异原因、标红片段及来源。
- 可编辑关键词排除非贴片物料，逐条记录排除原因。默认：锡膏、PCB、助焊剂、包装材料、贴纸、碳带（覆盖高温贴纸、树脂碳带等描述）。
- 关键词命中的非空料号及其在 BOM / A+B 中的对应行，全部直接列入“已排除物料”，保留命中词、命中来源及导入问题，不计入 PASS 或 NG；空料号只排除命中本行。未命中关键词的缺位号物料仍为 NG，避免漏检。旧版默认词表自动升级，自定义词表及禁用选择保留。筛选入口显示排除记录数，CSV / JSON 同步导出统计、两侧位号和命中词。
- 候选替代料单独审计，不自动继承上一行数量/位号，不自动替换 BOM 料号。
- 导出 CSV（Excel 可打开）和完整 JSON，包含规则和审计记录。
- 独立“设置”页管理 Chat Completions 兼容接口地址、模型、API Key 和单批原文大小；支持云端 HTTPS 和 localhost HTTP（例如 Ollama）。地址、模型、分批上限可保存；密钥仅保存在内存，关闭程序后清除。连接测试独立显示，不覆盖分析报告。
- 原始文件 AI 核对无需先执行本地核对。保留导入时的原始单元格、额外列、公式文本、表头、候选料、排除料及已读取的补充/隐藏工作表。按料号分批，BOM / A+B 同料号放在同一批；额外工作表原文和跨行位号归属单独审阅。超长记录明确报错，不静默丢弃。
- AI 原始文件核对及本地异常解读均需先确认接收地址和发送范围。发送的是提取后的文本，不上传 Excel 二进制文件，不执行文件内指令或公式。AI 结果不修改原文件或确定性核对状态。
- 原始文件分析逐批显示进度和结果，支持取消及“重试未完成批次”；取消、失败时保留已完成内容并明确标记“不完整”。使用 SSE 流式接收，兼容 JSON 返回；每次请求最多等待 5 分钟，超时、上下文过长或输出截断时会在完整料号组之间拆小重试。服务商的上下文容量、响应速度及结论准确度仍由所选模型决定。
- 原文件 AI 页显示持续活动动画、真实接口阶段、等待时长、接收字符数和已完成批次。结果区仅显示异常料号、原因、BOM / SMT 原文和来源位置，不展示一致项及模型推理。无有效异常清单或仅部分批次完成时，不宣称“未发现异常”。
- 分析阶段显示“AI正在分析”。原文件异常的类别、原因与本地异常解读保存中、英、泰三语版本，已有结果、复制内容及完成 / 失败 / 取消说明随软件语言切换；切换语言不重跑核对或发起新请求。料号、位号、BOM / SMT 原始证据与文件来源不翻译。兼容接口若仅返回单语，在分析完成前只补译已生成的说明，不重新发送原文件；缺少语言或翻译失败时不计为完成，可取消或重试。翻译由用户配置的 AI 模型生成。
- 选中结果采用中性单选标记、左侧细线和加粗料号；去掉彩色整行外框和额外提示横幅，当前选择在表格底部显示。核对状态使用鲜艳绿色和红色，切换主题不会改变其含义。
- Ctrl+O 导入 BOM，Ctrl+Enter 核对，Ctrl+E 导出 CSV。
- “清空重来”或 Ctrl+N 清除导入文件、结果和 AI 分析，保留语言、主题、规则及接口配置，并使旧异步任务失效。
- 右上角提供中文、English、ไทย 切换，自动保存选择；界面、异常原因和导出报告支持三语，原始 Excel 内容保持原文。随应用提供 Noto Sans Thai 字体及 OFL 许可。

## 安装完整应用

从 [GitHub Releases](https://github.com/Marginal-Z/SMT-CHECK/releases/latest) 直接下载当前版本安装包：

- **Windows x64：`SMT-CHECK-Setup-x64.exe`**。运行安装向导，选择安装目录（可选择 D 盘）；安装完成后从开始菜单启动 SMT-CHECK，可在系统“已安装的应用”中卸载。安装程序自动管理全部运行库和资源，无需解压或手动维护文件。安装向导也提供中、英、泰语言选择。
- **Windows ARM64：`SMT-CHECK-Setup-arm64.exe`**。用于 ARM64 Windows 11 设备，原生运行；安装方法同 x64。
- **macOS Intel / Apple Silicon：`SMT-CHECK-macos-universal.dmg`**。macOS 12+ 通用安装镜像，打开后将单个 SMT-CHECK.app 拖到 Applications。应用为临时签名，未进行 Apple Developer ID 签名或公证；系统首次阻止启动时需在“系统设置 → 隐私与安全性”允许打开。
- **Ubuntu / Debian x64 / ARM64：`SMT-CHECK-linux-amd64.deb` / `SMT-CHECK-linux-arm64.deb`**。按设备架构选择，通过系统软件安装器打开，安装后在应用菜单启动 SMT-CHECK。

软件本地核对不依赖 Excel、Python 或 AI 服务。当前 Windows 安装程序尚未进行代码签名。

## 原始文件 AI 核对

1. 在工作台选择单站位表或 A+B 模式，导入对应原始文件。
2. 打开顶部“设置”，填写兼容接口地址、模型、会话密钥；可调整单批字符上限并测试连接。
3. 点击工作台“原始文件 AI 核对”，或进入“AI 分析核对”选择“原始文件核对”，确认发送范围后开始。
4. 各批结果含文件、工作表、行号等证据引用。只有全部批次完成才显示分析完成；取消或失败的部分结果需继续复核。

“本地异常解读”使用本地核对的异常证据，原始文件核对使用完整导入快照。两类 AI 结果分别保留；本地 CSV / JSON 导出仍表示确定性核对报告。

## 下载 GitHub 构建

正式下载入口是上面的 Releases，提供直接下载的 EXE / DEB / DMG 安装文件。开发构建也会保存在 [多平台构建列表](https://github.com/Marginal-Z/SMT-CHECK/actions/workflows/desktop.yml) 的 **Artifacts** 中，保留 30 天；手动点击 **Run workflow** 或向 `main` 推送源码可生成新的构建。

- `SMT-CHECK-windows-x64`：包含 Windows EXE 安装程序与 SHA256 校验文件。
- `SMT-CHECK-windows-arm64`、`SMT-CHECK-linux-arm64`：ARM64 原生安装包和 SHA256。
- `SMT-CHECK-linux-x64`：Linux amd64 DEB 和 SHA256。
- `SMT-CHECK-macos-universal`：同时包含 Intel / Apple Silicon 代码的 DMG 和 SHA256。

Artifacts 是供开发验证的外层 ZIP；日常安装请直接使用 Releases 的安装文件。

Linux 两种架构分别在 Ubuntu 22.04 x64 / ARM64 原生构建。运行命令在 **WSL Ubuntu / Linux 图形桌面终端** 中执行；WSL 需有 WSLg 图形支持：

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
bash tools/build-macos.sh
```

`.github/workflows/desktop.yml` 自动执行 Windows / Linux x64 与 ARM64、macOS 通用包的静态检查、测试、release 构建、完整安装、启动及卸载检查和制品上传；同一 macOS DMG 还在 Intel 构建机上安装及启动验证。ARM64 使用官方 Flutter 3.47.2 源码标签引导原生 Dart SDK，避免用 x64 SDK 误构建。

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
