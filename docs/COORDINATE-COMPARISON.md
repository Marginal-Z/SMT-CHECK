# 坐标差异检测与 FAI450 回读核验

## 结构检查与修改范围

现有架构为 Flutter 原生桌面工作台。BOM/SMT 按料号聚合，并检查数量与位号集合；合并流程保留人工确认与原始行追溯。CAD 读取、生成、OOXML 导出分别位于 coordinate_reader.dart、cad_coordinates.dart、cad_workbook_export.dart。后台计算使用独立顶层隔离任务。

本次保留 BOM/SMT 和合并流程，不更换框架或依赖。新增独立比较领域模块、比较界面和设置面板，复用并补强原 CAD 读取器；FAI450 导出增加回读核验。Excel 行号只用于追溯，不用于元件配对。

修改文件清单：

- 核心：lib/core/cad_coordinates.dart、coordinate_reader.dart、cad_decimal.dart、coordinate_comparison.dart、special_pattern.dart。
- 服务：lib/services/background_tasks.dart、cad_workbook_export.dart、coordinate_comparison_export.dart。
- 界面：lib/app.dart、lib/ui/desktop_shell.dart、coordinate_comparison_workspace.dart、coordinate_compare_settings.dart。
- 语言：lib/l10n/catalog.dart、coordinate_compare_catalog.dart。
- 测试：test/coordinate_comparison_test.dart、coordinate_comparison_workflow_test.dart、coordinate_integrity_test.dart。
- 复查工具：tools/verify_cad_samples.dart。
- 版本与文档：pubspec.yaml、installer/windows.iss、README.md、本说明、docs/releases/v1.12.0.md。

## 使用

1. 打开“坐标差异检测”，分别导入 A/B（XLSX、UTF-8 CSV/TXT），不需要先完成 BOM 核对。
2. 确认每份文件的 mm/mil/inch 单位。明确带单位的表头可预选；裸 X/Y 不猜测单位。
3. 核实原点、轴方向、Top/Bottom 镜像约定并勾选确认。未确认时仅检查位号和属性，数值检查显示待确认。没有自动平移或镜像操作。
4. 按差异类型、RefDes、仅异常筛选。宽窗口右侧显示详情，窄窗口点击记录打开详情。
5. 特殊特征默认保留。人工保留/排除需要原因；排除后移入独立“已排除物料”视图，可通过“全部”查看。原始差异统计不被改写。配置为人工确认或排除建议的规则显示待人工确认，直到逐项决定。JSON 报告包含来源、差异、当前决定和全部历史。
6. 在“设置 → 坐标比较设置”修改容差与分类规则。保存后旧比较及决定失效；比较容差不影响 BOM 核对与 CAD 生成。

## 匹配与精度

- RefDes 去除前后空白并统一大写，保留内部字符和拼板前缀。
- 按位号与明确板号分组，唯一记录直接比较层别。重复位号使用板号、Top/Bottom 进一步区分；仍重复或缺必要板号则展示歧义，保留所有原始行，不挑第一条配对。
- 重复检查包含无效坐标行。多张坐标表需明确另存目标表；重复表头、缺少位号/X/Y/层别/比较角度列报错。缺少可选属性展示数据质量问题，不伪造一致结论。
- X/Y 用十进制整数与小数位算术，转换至 mm 后与默认 ±0.001 mm 比较，包含边界。角度取 360° 周期的最短差值，默认 ±0.001°。该容差不是设备检测公差。
- 保留原始数字文本。比较不四舍五入，不修改 FAI450 数值。极端指数、无效/非有限数字、空坐标及混合单位明确暴露。
- 排序与容差内差异单独提示，不判为元件 NG；未知坐标系不自动“修复”。

## 特殊元件

内置 TP、FID、MH、NPTH；完整字段匹配，可组合 RefDes、PartType、PartDecal，同规则的非空条件为 AND。用户可增删改规则，选择保留、排除建议、人工确认。规则仅开放有长度及量词限制的正则子集，不支持分组、回溯引用和花括号量词。

普通元件与特殊特征分开统计。TP10_1 只存在一侧时保留缺失差异并标注 TP，不自动过滤。分类不决定是否需要设备检测，由工艺人员确认。

## FAI450 兼容

保留完整有效原坐标参与镜像范围计算；Top 不变，Bottom 的 Y = minY + maxY − Y，角度加 180° 后规范化。原点、X 方向、Sheet1、十列顺序、mm 输出及四位小数显示样式不变。

生成前检查冲突、缺失、数字/层别、数量与位号数；歧义记录不生成猜测预览。导出后回读实际 OOXML，按位号检查数量、唯一性、X/Y/角度及全部元数据字段；缺失、重复或值改变中止保存。回读不以比较容差掩盖输出错误。

## 真实样本验收（2026-10-17）

两份用户样本只读验证，没有预设哪份更正确。测试明确指定 mm 和同一坐标基准：

| 指标 | 结果 |
|---|---:|
| A / B 元件 | 447 / 446 |
| 共有位号 | 446 |
| A 独有 | TP10_1 |
| B 独有 | 0 |
| 坐标 / 角度 / 属性 NG | 0 / 0 / 0 |
| 容差内差异的共有元件 | 118 |

逆序自比较无实质差异。修改前后两份输入对应的 447 + 446 行生成基线，全部十字段及镜像范围一致。自动测试另覆盖容差边界、角度周期、坐标越差、属性/层别变化、重复/板号歧义、空值/缺字段、异步清空、人工操作及中英泰窄宽窗口。

PowerShell 7（项目目录执行；样本不纳入 Git）：

```powershell
dart run tools/verify_cad_samples.dart 'C:/Users/zhangyouyi/Downloads/SMT-CHECK-BOM_FAI450正确坐标.xlsx' 'D:/自研项目资料/CAD坐标/X-CY028-H1-M12-MAIN-A+B-130701670-NPI-S5-A_FAI450正确坐标.xlsx' 'outputs/cad-real-comparison.json'
flutter analyze --no-pub
flutter test --no-pub
./tools/build-windows.ps1 -SkipChecks
```

仍需工艺确认 TP10_1 的实际检测需求，以及不同项目的单位、原点、轴方向和镜像约定；软件测试不代替实机导入与定位验证。
