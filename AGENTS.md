# SMT-CHECK 开发约定

- Windows 终端使用 PowerShell 7；Windows 路径、平台构建和系统操作使用 PowerShell 7。
- Linux、Git、通用服务开发优先 WSL2 Ubuntu。输出命令时标明执行环境。
- 产品为 Flutter 原生桌面程序，禁止 WebView/浏览器替代交付。
- 默认浅色，黑白为主，绿色一致、红色异常。禁用 Material 3、紫色和渐变。
- 原始 Excel 只读。保留料号、原始字段、文件、工作表和一基行号的追溯。
- AI 不改变确定性核对状态；密钥不写日志、仓库或普通设置文件。
- 排除和候选料必须可见，不计入通过。修改规则后使旧核对失效。
- 后台任务在独立顶层入口创建隔离任务，避免捕获 Flutter State。
- 修改解析/核对/布局后，运行 flutter analyze 和相关 flutter test；Windows 交付执行 release 构建。
- `.tools/`、`outputs/`、`dist/` 和用户参考文件不进入 Git。
- 中文、英文、泰文文本统一由 lib/l10n 管理，不翻译原始 Excel 字段值。
- 交付 Windows Setup.exe 和 Linux DEB，验证安装、启动和卸载；正式下载提供 Releases 单文件安装包。
