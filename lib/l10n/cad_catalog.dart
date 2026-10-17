// CAD application messages; original spreadsheet fields remain unchanged.
const cadCatalog = <String, List<String>>{
  'BOM 文件预览': ['BOM preview', 'ตัวอย่างไฟล์ BOM'],
  '导出 BOM Excel': ['Export BOM Excel', 'ส่งออก BOM Excel'],
  '单表 CAD': ['Single-table CAD', 'CAD ตารางเดียว'],
  'A+B CAD': ['A+B CAD', 'CAD A+B'],
  '原坐标文件': ['Coordinate file', 'ไฟล์พิกัดต้นฉบับ'],
  '核对与人工确认': ['Check & review', 'ตรวจสอบและยืนยัน'],
  '保留设备十列格式': ['Device ten-column format', 'รูปแบบสิบคอลัมน์สำหรับเครื่อง'],
  '待完成人工确认与 BOM 预览': [
    'Manual review and BOM preview required',
    'ต้องยืนยันโดยผู้ใช้และสร้างตัวอย่าง BOM',
  ],
  '已确认 BOM · {count} 行': [
    'Reviewed BOM · {count} rows',
    'BOM ที่ยืนยันแล้ว · {count} แถว',
  ],
  '坐标转换说明': ['Coordinate conversion details', 'รายละเอียดการแปลงพิกัด'],
  '单站位表整理与导出': [
    'Single-table preparation & export',
    'จัดเตรียมและส่งออกตารางเดียว',
  ],
  '保留原始明细': ['Keep source detail', 'เก็บรายละเอียดต้นฉบับ'],
  '生成 BOM 预览': ['Generate BOM preview', 'สร้างตัวอย่าง BOM'],
  '请先完成单站位表或 A+B 核对': [
    'Complete a single-table or A+B check first',
    'ตรวจสอบตารางเดียวหรือ A+B ให้เสร็จก่อน',
  ],
  '请先导入 BOM 和站位表，完成单表或 A+B 核对。': [
    'Import BOM and placement data, then complete a single-table or A+B check.',
    'นำเข้า BOM และข้อมูลตาราง SMT แล้วตรวจสอบตารางเดียวหรือ A+B ให้เสร็จ',
  ],
  '仅整理当前 SMT 站位表原始记录，保留四列；人工确认不改变核对状态。': [
    'Prepare the current SMT source rows in four columns; manual review preserves check status.',
    'จัดเตรียมข้อมูลต้นฉบับ SMT ปัจจุบันเป็นสี่คอลัมน์ การยืนยันโดยผู้ใช้ไม่เปลี่ยนสถานะตรวจสอบ',
  ],
  'CAD 原始字段': ['Source fields', 'ฟิลด์ต้นฉบับ'],
  '先完成单表或 A+B 核对、人工确认及 BOM 预览，再导入原坐标并选择单位。生成 CAD 预览后可自定义名称导出十列 Excel；Bottom 已按 V1.6 规则预镜像，导入设备时不要二次镜像。':
      [
        'Complete a single-table or A+B check, manual review and BOM preview, then import source coordinates and choose units. Preview and export the ten-column CAD Excel with a custom name. Bottom is already mirrored using V1.6 rules; do not mirror it again on the device.',
        'ตรวจสอบตารางเดียวหรือ A+B ยืนยันโดยผู้ใช้และสร้างตัวอย่าง BOM ก่อน จากนั้นนำเข้าพิกัดต้นฉบับและเลือกหน่วย สร้างตัวอย่างแล้วส่งออก CAD Excel สิบคอลัมน์โดยกำหนดชื่อได้ Bottom ถูกกลับภาพตาม V1.6 แล้ว อย่ากลับภาพซ้ำในเครื่อง',
      ],
  'CAD 原坐标含 Excel 错误或缺少公式缓存': [
    'Source coordinate contains an Excel error or lacks a formula cache',
    'พิกัดต้นฉบับมีข้อผิดพลาด Excel หรือไม่มีค่าที่คำนวณไว้ของสูตร',
  ],
  "CAD 坐标": ["CAD coordinates", "พิกัด CAD"],
  "FAI-i450 CAD 坐标": ["FAI-i450 CAD coordinates", "พิกัด CAD สำหรับ FAI-i450"],
  "使用已确认合并 BOM 和原坐标，生成设备十列坐标文件。": [
    "Generate the device's ten-column coordinate file from the reviewed merged BOM and original coordinates.",
    "สร้างไฟล์พิกัดสิบคอลัมน์สำหรับเครื่องจาก BOM ที่รวมและยืนยันแล้วกับพิกัดต้นฉบับ",
  ],
  "导入原坐标": ["Import coordinates", "นำเข้าพิกัดต้นฉบับ"],
  "原坐标单位": ["Source coordinate unit", "หน่วยพิกัดต้นฉบับ"],
  "请选择坐标单位": ["Select coordinate unit", "เลือกหน่วยพิกัด"],
  "毫米（mm）": ["Millimetres (mm)", "มิลลิเมตร (mm)"],
  "密耳（mil）": ["Mils (mil)", "มิล (mil)"],
  "英寸（inch）": ["Inches (inch)", "นิ้ว (inch)"],
  "生成 CAD 预览": ["Generate CAD preview", "สร้างตัวอย่าง CAD"],
  "合并与人工确认": ["Merge & review", "รวมและยืนยัน"],
  "CAD 文件名": ["CAD file name", "ชื่อไฟล์ CAD"],
  "CAD 文件名前缀": ["CAD file name prefix", "คำนำหน้าชื่อไฟล์ CAD"],
  "导出 CAD Excel": ["Export CAD Excel", "ส่งออก CAD Excel"],
  "导出 {face} CAD 坐标": [
    "Export {face} CAD coordinates",
    "ส่งออกพิกัด CAD {face}",
  ],
  "保留设备十列格式；分别导出 -TOP-CAD坐标.xlsx 与 -BOT-CAD坐标.xlsx": [
    "Preserves the device ten-column format; exports -TOP-CAD coordinates.xlsx and -BOT-CAD coordinates.xlsx separately.",
    "คงรูปแบบสิบคอลัมน์ของเครื่อง และส่งออกไฟล์ -TOP-CAD坐标.xlsx กับ -BOT-CAD坐标.xlsx แยกกัน",
  ],
  "请先完成核对、人工确认并生成合并预览。": [
    "Complete the check, manual review and merged preview first.",
    "ตรวจสอบ ยืนยันโดยผู้ใช้ และสร้างตัวอย่างไฟล์ที่รวมก่อน",
  ],
  "当前已确认合并 BOM：{count} 行": [
    "Reviewed merged BOM: {count} rows",
    "BOM ที่รวมและยืนยันแล้ว: {count} แถว",
  ],
  "尚未导入原坐标": ["No coordinates imported", "ยังไม่ได้นำเข้าพิกัดต้นฉบับ"],
  "原坐标 {count} 条有效记录": [
    "Source coordinates: {count} valid records",
    "พิกัดต้นฉบับ: {count} รายการที่ใช้ได้",
  ],
  "V1.6 兼容：Top 保持，Bottom 按完整原坐标 Y 范围镜像，角度 +180°。": [
    "V1.6 compatibility: preserve Top; mirror Bottom using the full source Y range and add 180°.",
    "เข้ากันได้กับ V1.6: คง Top เดิม กลับภาพ Bottom ตามช่วง Y ของพิกัดต้นฉบับทั้งหมด และเพิ่มมุม 180°",
  ],
  "镜像范围：{min} ～ {max} mm": [
    "Mirror range: {min} to {max} mm",
    "ช่วงกลับภาพ: {min} ถึง {max} mm",
  ],
  "输出已预镜像，导入 FAI-i450 时 Bottom 不要再次勾选“镜面”。": [
    "Output is already mirrored. Leave Bottom Mirror unchecked when importing into FAI-i450.",
    "ไฟล์ถูกกลับภาพแล้ว อย่าเลือก Mirror ของ Bottom ซ้ำเมื่อนำเข้า FAI-i450",
  ],
  "坐标预览": ["Coordinate preview", "ตัวอย่างพิกัด"],
  "坐标问题（{count}）": ["Coordinate issues ({count})", "ปัญหาพิกัด ({count})"],
  "PASS · {count} 个位号": ["PASS · {count} references", "PASS · {count} ตำแหน่ง"],
  "NG · {count} 项坐标问题": [
    "NG · {count} coordinate issues",
    "NG · ปัญหาพิกัด {count} รายการ",
  ],
  "没有坐标问题": ["No coordinate issues", "ไม่มีปัญหาพิกัด"],
  "完成准备后生成 CAD 预览；修改文件、单位或人工确认会使旧预览失效。": [
    "Generate a CAD preview when ready. Changes to files, units or review decisions invalidate the previous preview.",
    "สร้างตัวอย่าง CAD เมื่อพร้อม การเปลี่ยนไฟล์ หน่วย หรือการยืนยันจะทำให้ตัวอย่างเดิมใช้ไม่ได้",
  ],
  "输出 {count} 行 · 未纳入 {omitted} 条原坐标 · 无位号 BOM {empty} 行": [
    "Output {count} rows · Omit {omitted} source coordinates · {empty} BOM rows without references",
    "ส่งออก {count} แถว · ไม่รวมพิกัดต้นฉบับ {omitted} รายการ · BOM ไม่มีตำแหน่ง {empty} แถว",
  ],
  "正在读取原坐标…": ["Reading source coordinates…", "กำลังอ่านพิกัดต้นฉบับ…"],
  "正在生成 CAD 坐标…": ["Generating CAD coordinates…", "กำลังสร้างพิกัด CAD…"],
  "正在导出 CAD 坐标…": ["Exporting CAD coordinates…", "กำลังส่งออกพิกัด CAD…"],
  "CAD 导入失败：{detail}": [
    "CAD import failed: {detail}",
    "นำเข้า CAD ไม่สำเร็จ: {detail}",
  ],
  "CAD 生成失败：{detail}": [
    "CAD generation failed: {detail}",
    "สร้าง CAD ไม่สำเร็จ: {detail}",
  ],
  "CAD 导出失败：{detail}": [
    "CAD export failed: {detail}",
    "ส่งออก CAD ไม่สำเร็จ: {detail}",
  ],
  "CAD 文件已导出：{path}": [
    "CAD file exported: {path}",
    "ส่งออกไฟล์ CAD แล้ว: {path}",
  ],
  "TOP CAD 文件已导出：{path}": [
    "TOP CAD file exported: {path}",
    "ส่งออกไฟล์ CAD TOP แล้ว: {path}",
  ],
  "BOT CAD 文件已导出：{path}": [
    "BOT CAD file exported: {path}",
    "ส่งออกไฟล์ CAD BOT แล้ว: {path}",
  ],
  "是否覆盖 CAD 文件？": ["Overwrite the CAD file?", "เขียนทับไฟล์ CAD หรือไม่"],
  "CAD 原坐标位号重复：首次位于 {sheet} 第 {row} 行": [
    "Duplicate source reference: first at {sheet}, row {row}",
    "ตำแหน่งต้นฉบับซ้ำ: พบครั้งแรกที่ {sheet} แถว {row}",
  ],
  "CAD 单位换算后坐标超出有效范围": [
    "Coordinate is outside the finite range after unit conversion",
    "พิกัดอยู่นอกช่วงที่ใช้ได้หลังแปลงหน่วย",
  ],
  "CAD BOM 有用量但没有位号": [
    "BOM has a quantity but no references",
    "BOM มีจำนวนแต่ไม่มีตำแหน่ง",
  ],
  "CAD BOM 位号无效：{reason}": [
    "Invalid BOM references: {reason}",
    "ตำแหน่ง BOM ไม่ถูกต้อง: {reason}",
  ],
  "CAD BOM 数量必须为非负整数": [
    "BOM quantity must be a non-negative integer",
    "จำนวน BOM ต้องเป็นจำนวนเต็มที่ไม่ติดลบ",
  ],
  "CAD BOM 数量 {value} 与位号数 {count} 不一致": [
    "BOM quantity {value} differs from reference count {count}",
    "จำนวน BOM {value} ไม่ตรงกับจำนวนตำแหน่ง {count}",
  ],
  "CAD BOM 位号重复或归属冲突": [
    "Duplicate BOM reference or conflicting ownership",
    "ตำแหน่ง BOM ซ้ำหรือขัดแย้งกัน",
  ],
  "CAD BOM 位号缺少原始坐标": [
    "BOM reference has no source coordinate",
    "ตำแหน่ง BOM ไม่มีพิกัดต้นฉบับ",
  ],
  "CAD 没有可导出的有效坐标": [
    "No valid coordinates to export",
    "ไม่มีพิกัดที่ใช้ได้สำหรับส่งออก",
  ],
  "CAD 支持 .xlsx、.csv、.txt 坐标文件；旧版 .xls 请先另存为 .xlsx": [
    "CAD accepts .xlsx, .csv and .txt coordinates; convert legacy .xls to .xlsx first",
    "CAD รองรับพิกัด .xlsx, .csv และ .txt โปรดแปลง .xls เก่าเป็น .xlsx ก่อน",
  ],
  "CAD 未找到位号、X、Y 坐标表头": [
    "Reference, X and Y coordinate headers were not found",
    "ไม่พบหัวคอลัมน์ตำแหน่ง X และ Y",
  ],
  "CAD 原坐标缺少 Layer／面别列": [
    "Source coordinates have no Layer/side column",
    "พิกัดต้นฉบับไม่มีคอลัมน์ Layer/ด้าน",
  ],
  "CAD 原坐标位号为空": ["Source reference is empty", "ตำแหน่งต้นฉบับว่าง"],
  "CAD X 坐标为空或不是有限数值": [
    "X is empty or is not a finite number",
    "X ว่างหรือไม่ใช่ค่าตัวเลขที่ใช้ได้",
  ],
  "CAD Y 坐标为空或不是有限数值": [
    "Y is empty or is not a finite number",
    "Y ว่างหรือไม่ใช่ค่าตัวเลขที่ใช้ได้",
  ],
  "CAD 角度为空或不是有限数值": [
    "Angle is empty or is not a finite number",
    "มุมว่างหรือไม่ใช่ค่าตัวเลขที่ใช้ได้",
  ],
  "CAD 无法识别面别：{value}": [
    "Unrecognized coordinate side: {value}",
    "ไม่รู้จักด้านของพิกัด: {value}",
  ],
  "CAD Pins 必须为非负整数": [
    "Pins must be a non-negative integer",
    "Pins ต้องเป็นจำนวนเต็มที่ไม่ติดลบ",
  ],
  "CAD 原坐标没有有效数据行": [
    "Source coordinate file has no valid data rows",
    "ไฟล์พิกัดต้นฉบับไม่มีแถวข้อมูลที่ใช้ได้",
  ],
  "CAD 原文件没有角度列，按 0° 处理，请复核": [
    "Source has no angle column; using 0°. Please review.",
    "ต้นฉบับไม่มีคอลัมน์มุม ใช้ 0° โปรดตรวจทาน",
  ],
  "CAD 工作表数据缺失": [
    "Coordinate worksheet data is missing",
    "ข้อมูลแผ่นงานพิกัดสูญหาย",
  ],
  "CAD 无表头文本需要 Ref X Y Angle 和可选封装": [
    "Headerless coordinates need Ref X Y Angle and an optional package",
    "พิกัดที่ไม่มีหัวตารางต้องมี Ref X Y Angle และอาจมีแพ็กเกจ",
  ],
  "CAD CSV 引号未闭合，请检查原文件": [
    "Unclosed CSV quote; check the source file",
    "เครื่องหมายคำพูด CSV ไม่ครบ โปรดตรวจสอบไฟล์ต้นฉบับ",
  ],
  "CAD 存在异常，不能导出": [
    "Coordinate issues prevent export",
    "มีปัญหาพิกัด ไม่สามารถส่งออกได้",
  ],
  "CAD 单元格内容无法完整写入 Excel": [
    "A coordinate cell cannot be written completely to Excel",
    "ไม่สามารถเขียนข้อมูลเซลล์พิกัดลง Excel ได้ครบถ้วน",
  ],
};
