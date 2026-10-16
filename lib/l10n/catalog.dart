// Application strings. Spreadsheet fields are never translated.
const catalog = <String, List<String>>{
  '原始文件较大时建议每批 12000 或 24000 字符；超时后会自动拆小重试。': [
    'For larger files, use 12000 or 24000 characters per batch. Timed-out batches are automatically split and retried.',
    'สำหรับไฟล์ขนาดใหญ่ แนะนำ 12000 หรือ 24000 อักขระต่อชุด หากหมดเวลาระบบจะแบ่งชุดให้เล็กลงแล้วลองใหม่',
  ],
  '当前选中料号': ['Selected part', 'รหัสวัสดุที่เลือก'],
  '已被筛选隐藏': ['Hidden by the current filter', 'ถูกซ่อนโดยตัวกรองปัจจุบัน'],
  '重试未完成批次': ['Retry unfinished batches', 'ลองชุดที่ยังไม่เสร็จอีกครั้ง'],
  '仅重试未完成批次，保留已完成结果。': [
    'Only unfinished batches will be retried. Completed results are preserved.',
    'ลองใหม่เฉพาะชุดที่ยังไม่เสร็จ โดยเก็บผลที่เสร็จแล้วไว้',
  ],
  '继续未完成批次': ['Resuming unfinished batches', 'ดำเนินการชุดที่ยังไม่เสร็จต่อ'],
  '正在等待 AI 返回当前批次，可取消；每批最多等待 5 分钟。': [
    'Waiting for the current AI batch. You can cancel; each request allows up to 5 minutes.',
    'กำลังรอผล AI ของชุดปัจจุบัน ยกเลิกได้ โดยรอแต่ละคำขอสูงสุด 5 นาที',
  ],
  '本批响应超时或超出接口限制，已自动拆小重试': [
    'Batch timed out or exceeded the service limit; retrying in smaller batches',
    'ชุดนี้หมดเวลาหรือเกินขีดจำกัดบริการ จึงแบ่งเป็นชุดเล็กเพื่อลองใหม่',
  ],
  'AI 请求超过 {count} 秒，请重试未完成批次或在设置中减小单批字符上限。': [
    'AI request exceeded {count} seconds. Retry unfinished batches or lower the batch character limit in Settings.',
    'คำขอ AI เกิน {count} วินาที ลองชุดที่ยังไม่เสร็จอีกครั้งหรือลดจำนวนอักขระต่อชุดในการตั้งค่า',
  ],
  'AI 网络连接失败，请检查网络、代理和接口地址后重试未完成批次。': [
    'AI connection failed. Check the network, proxy and API URL, then retry unfinished batches.',
    'เชื่อมต่อ AI ไม่สำเร็จ ตรวจเครือข่าย พร็อกซี และ URL ของ API แล้วลองชุดที่ยังไม่เสร็จอีกครั้ง',
  ],
  'AI 输出被截断，本批核对尚未完成。请减小单批字符上限后重试。': [
    'AI output was truncated. This batch is incomplete; lower the batch character limit and retry.',
    'ผลลัพธ์ AI ถูกตัด ชุดนี้ยังไม่เสร็จ โปรดลดจำนวนอักขระต่อชุดแล้วลองใหม่',
  ],
  'AI 服务过滤了本批内容，未完成核对。': [
    'The AI service filtered this batch. Verification is incomplete.',
    'บริการ AI กรองเนื้อหาชุดนี้ การตรวจสอบยังไม่เสร็จ',
  ],
  'AI 未返回最终核对文本，请检查模型是否只返回推理内容或接口是否兼容 Chat Completions。': [
    'AI returned no final verification text. Check whether the model returned reasoning only and whether the API supports Chat Completions.',
    'AI ไม่ได้ส่งข้อความผลตรวจสอบ ตรวจว่าโมเดลส่งเฉพาะการให้เหตุผลหรือไม่ และ API รองรับ Chat Completions หรือไม่',
  ],
  'AI 流式返回格式无效。': [
    'Invalid AI streaming response format.',
    'รูปแบบข้อมูลสตรีมจาก AI ไม่ถูกต้อง',
  ],
  'AI 流式接口返回错误：{detail}': [
    'AI streaming service error: {detail}',
    'ข้อผิดพลาดจากบริการสตรีม AI: {detail}',
  ],
  'AI 流式连接提前中断，本批核对尚未完成，请重试未完成批次。': [
    'The AI stream ended early. This batch is incomplete; retry unfinished batches.',
    'การเชื่อมต่อสตรีม AI สิ้นสุดก่อนเวลา ชุดนี้ยังไม่เสร็จ โปรดลองชุดที่ยังไม่เสร็จอีกครั้ง',
  ],
  '外观与 AI 接口': ['Appearance and AI connection', 'รูปลักษณ์และการเชื่อมต่อ AI'],
  '外观': ['Appearance', 'รูปลักษณ์'],
  '主题色': ['Accent color', 'สีธีม'],
  '黑色': ['Black', 'สีดำ'],
  '蓝色': ['Blue', 'สีน้ำเงิน'],
  '绿色': ['Green', 'สีเขียว'],
  '主题色即时生效并自动保存；一致为绿色，异常为红色。': [
    'Accent changes apply immediately and are saved. Matches stay green; mismatches stay red.',
    'สีธีมเปลี่ยนทันทีและบันทึกอัตโนมัติ รายการตรงกันเป็นสีเขียว ผิดปกติเป็นสีแดง',
  ],
  '主题色已切换，持久保存失败': [
    'Accent changed; saving the preference failed',
    'เปลี่ยนสีธีมแล้ว แต่บันทึกการตั้งค่าไม่สำเร็จ',
  ],
  '已取消发送': ['Sending cancelled', 'ยกเลิกการส่งแล้ว'],
  '原始文件 AI 分析失败': [
    'Original file AI analysis failed',
    'วิเคราะห์ไฟล์ต้นฉบับด้วย AI ไม่สำเร็จ',
  ],
  'CSV 可由 Excel 打开，JSON 保留来源和规则。在设置中配置 AI 接口，可选择原始文件核对或本地异常解读。确认发送范围后才发送提取的原文或异常证据；无需 AI 也能完成本地核对。':
      [
        'Excel opens CSV reports; JSON keeps sources and rules. Configure AI in Settings, then choose original file checks or local mismatch explanations. Extracted text or mismatch evidence is sent only after confirming its scope. Local checks work without AI.',
        'เปิดรายงาน CSV ด้วย Excel ได้ ส่วน JSON เก็บแหล่งข้อมูลและกฎ ตั้งค่า AI แล้วเลือกตรวจต้นฉบับหรืออธิบายข้อผิดพลาดในเครื่อง ระบบส่งข้อความหรือหลักฐานหลังยืนยันขอบเขตเท่านั้น ตรวจในเครื่องได้โดยไม่ต้องใช้ AI',
      ],
  'Ctrl+O 导入 BOM；Ctrl+Enter 开始核对；Ctrl+E 导出 CSV；Ctrl+N 清空重来。表格可横向滚动，点击行查看证据，右侧详情可以收起。':
      [
        'Ctrl+O imports BOM; Ctrl+Enter checks; Ctrl+E exports CSV; Ctrl+N clears the session. Scroll tables horizontally, click rows for evidence and collapse the detail pane when needed.',
        'Ctrl+O นำเข้า BOM; Ctrl+Enter ตรวจสอบ; Ctrl+E ส่งออก CSV; Ctrl+N ล้างและเริ่มใหม่ เลื่อนตารางแนวนอน คลิกแถวเพื่อดูหลักฐาน และซ่อนรายละเอียดด้านขวาได้',
      ],
  'AI 分析核对': ['AI checks', 'ตรวจสอบด้วย AI'],
  '设置': ['Settings', 'ตั้งค่า'],
  'AI 接口': ['AI connection', 'การเชื่อมต่อ AI'],
  'AI 接口设置': ['AI settings', 'ตั้งค่า AI'],
  '原始文件核对': ['Original files', 'ไฟล์ต้นฉบับ'],
  '原始文件 AI 核对': ['AI file check', 'ตรวจไฟล์ด้วย AI'],
  '本地异常解读': ['Explain local mismatches', 'อธิบายข้อผิดพลาดในเครื่อง'],
  '分析原始文件': ['Analyze original files', 'วิเคราะห์ไฟล์ต้นฉบับ'],
  '取消分析': ['Cancel analysis', 'ยกเลิกการวิเคราะห์'],
  '分析已取消': ['Analysis cancelled', 'ยกเลิกการวิเคราะห์แล้ว'],
  '原始文件 AI 核对结果': ['Original file AI results', 'ผลตรวจไฟล์ต้นฉบับด้วย AI'],
  '直接读取原始单元格核对，包含排除料、候选料和额外工作表信息；无需先运行本地核对。': [
    'Check original cells, including excluded materials, alternatives and extra worksheet content. A local check is not required first.',
    'ตรวจจากเซลล์ต้นฉบับ รวมวัสดุที่ยกเว้น วัสดุทางเลือก และข้อมูลแผ่นงานเพิ่มเติม โดยไม่ต้องตรวจในเครื่องก่อน',
  ],
  '依据本地核对结果解释异常；AI 建议不会改变本地核对状态。': [
    'Explain mismatches from the local check. AI advice does not change local check status.',
    'อธิบายข้อผิดพลาดจากผลตรวจในเครื่อง คำแนะนำ AI ไม่เปลี่ยนสถานะการตรวจ',
  ],
  '请在核对工作台导入原始文件': [
    'Import original files in the workbench',
    'นำเข้าไฟล์ต้นฉบับในพื้นที่ตรวจสอบ',
  ],
  '已完成 {count} / {total} 批': [
    'Completed {count} / {total} batches',
    'เสร็จแล้ว {count} / {total} ชุด',
  ],
  '尚未开始分析。配置接口后，选择分析方式并发送。': [
    'No analysis yet. Configure the AI connection, choose a mode and send.',
    'ยังไม่ได้วิเคราะห์ ตั้งค่าการเชื่อมต่อ AI เลือกวิธีวิเคราะห์แล้วส่ง',
  ],
  'AI 结论仅供复核，原文件和本地核对状态不会被修改。': [
    'AI conclusions are for review. Source files and local check status stay unchanged.',
    'ผล AI ใช้ประกอบการทบทวน ไม่แก้ไขต้นฉบับหรือสถานะการตรวจในเครื่อง',
  ],
  '原始文件分析分批': ['Original file batches', 'แบ่งชุดวิเคราะห์ไฟล์ต้นฉบับ'],
  '同料号的 BOM 和 A/B 记录放在同一批，所有批次完成才表示本次分析完整。': [
    'BOM and A/B records of the same part stay in one batch. All batches must finish for a complete analysis.',
    'รายการ BOM และ A/B รหัสเดียวกันอยู่ในชุดเดียวกัน ต้องครบทุกชุดจึงถือว่าวิเคราะห์ครบ',
  ],
  '单批原文字符上限': [
    'Source character limit per batch',
    'จำนวนอักขระต้นฉบับสูงสุดต่อชุด',
  ],
  '接收地址': ['Recipient host', 'ปลายทางรับข้อมูล'],
  '发送原始文件内容至 AI': [
    'Send original file content to AI',
    'ส่งเนื้อหาไฟล์ต้นฉบับไปยัง AI',
  ],
  '将发送 {files} 份文件中 {rows} 条物料记录及全部已读取的原始单元格、表头和公式文本，共 {total} 批。包括排除料、候选料和额外工作表内容；不上传 Excel 二进制文件。':
      [
        'Send {rows} material rows from {files} files and all retained original cells, headers and formula text in {total} batches. Includes excluded materials, alternatives and extra worksheets. Excel binary files are not uploaded.',
        'ส่งวัสดุ {rows} แถวจาก {files} ไฟล์ พร้อมเซลล์ต้นฉบับ หัวตาราง และข้อความสูตรที่อ่านได้ทั้งหมด รวม {total} ชุด รวมวัสดุที่ยกเว้น วัสดุทางเลือก และแผ่นงานเพิ่มเติม โดยไม่อัปโหลดไฟล์ไบนารี Excel',
      ],
  '正在准备原始文件分析…': [
    'Preparing original file analysis…',
    'กำลังเตรียมวิเคราะห์ไฟล์ต้นฉบับ…',
  ],
  '物料字段核对': ['Material field check', 'ตรวจข้อมูลวัสดุ'],
  '工作表原文审阅': ['Worksheet content review', 'ทบทวนข้อมูลแผ่นงาน'],
  '位号归属复核': ['Reference ownership review', 'ทบทวนเจ้าของตำแหน่ง'],
  '第 {count} / {total} 批': [
    'Batch {count} / {total}',
    'ชุดที่ {count} / {total}',
  ],
  '全部 {total} 批分析完成。AI 结论供复核，不改变本地核对状态。': [
    'All {total} batches finished. AI conclusions are for review and do not change local check status.',
    'วิเคราะห์ครบ {total} ชุดแล้ว ผล AI ใช้ประกอบการทบทวน ไม่เปลี่ยนสถานะการตรวจในเครื่อง',
  ],
  '分析已取消，已完成 {count} / {total} 批，结果不完整。': [
    'Analysis cancelled after {count} / {total} batches. Results are incomplete.',
    'ยกเลิกหลังเสร็จ {count} / {total} ชุด ผลยังไม่ครบ',
  ],
  '原始文件分析中断，已完成 {count} / {total} 批，结果不完整：{reason}': [
    'Original file analysis stopped after {count} / {total} batches. Results are incomplete: {reason}',
    'การวิเคราะห์ไฟล์ต้นฉบับหยุดหลังเสร็จ {count} / {total} ชุด ผลยังไม่ครบ: {reason}',
  ],
  '原始文件 AI 核对完成': [
    'Original file AI analysis finished',
    'ตรวจไฟล์ต้นฉบับด้วย AI เสร็จแล้ว',
  ],
  '原始记录超过单批上限：{detail}；请在设置中增大单批字符上限或拆分超长记录。': [
    'Original record exceeds the batch limit: {detail}. Increase the limit in Settings or split the oversized record.',
    'ข้อมูลต้นฉบับเกินขีดจำกัดต่อชุด: {detail} เพิ่มขีดจำกัดในตั้งค่าหรือแบ่งข้อมูลที่ยาวเกินไป',
  ],
  'AI 单批字符上限须为 12000 至 120000': [
    'AI batch character limit must be 12000–120000',
    'ขีดจำกัดอักขระต่อชุด AI ต้องอยู่ระหว่าง 12000–120000',
  ],
  '收起详情': ['Hide details', 'ซ่อนรายละเอียด'],
  '展开详情': ['Show details', 'แสดงรายละเอียด'],
  '来源与差异详情': ['Sources and differences', 'แหล่งข้อมูลและความแตกต่าง'],
  'BOM  料件编号 · 品名 · 组成用量 · 插件位置': [
    'BOM  Part number · Name · Usage · Positions',
    'BOM  รหัสวัสดุ · ชื่อ · จำนวนใช้ · ตำแหน่ง',
  ],
  'SMT  料号 · 物料描述 · 数量 · 位号': [
    'SMT  Part number · Description · Quantity · References',
    'SMT  รหัสวัสดุ · รายละเอียด · จำนวน · ตำแหน่ง',
  ],
  '料号总数量': ['Total unique parts', 'รหัสวัสดุทั้งหมด'],
  'BOM料号数量': ['BOM unique parts', 'รหัสวัสดุ BOM'],
  'SMT站位表料号数量': ['SMT unique parts', 'รหัสวัสดุ SMT'],
  '料号数按去重统计，含已排除和候选料；总数为 BOM 与 SMT 并集，A+B 相同料号只计一次，空料号不计。': [
    'Unique part counts include excluded and candidate rows. Total is the BOM/SMT union; A+B duplicates count once. Blank part numbers are omitted.',
    'นับรหัสวัสดุไม่ซ้ำ รวมรายการที่ยกเว้นและวัสดุทางเลือก ยอดรวมคือรหัสทั้งหมดจาก BOM และ SMT รหัสซ้ำใน A+B นับครั้งเดียว ไม่นับรหัสว่าง',
  ],
  '已排除物料': ['Excluded materials', 'วัสดุที่ยกเว้น'],
  'BOM插件位置': ['BOM positions', 'ตำแหน่ง BOM'],
  'SMT站位表位号': ['SMT references', 'ตำแหน่ง SMT'],
  '命中排除关键词': ['Matched exclusion keywords', 'คำสำคัญที่ตรงกับกฎยกเว้น'],
  'Excel 工作簿': ['Excel workbook', 'สมุดงาน Excel'],
  '导入': ['Import', 'นำเข้า'],
  '保存': ['Save', 'บันทึก'],
  "核对工作台": ["Workbench", "พื้นที่ตรวจสอบ"],
  "导入与规则": ["Imports & rules", "การนำเข้าและกฎ"],
  "AI 异常分析": ["AI analysis", "วิเคราะห์ด้วย AI"],
  "使用说明": ["Help", "วิธีใช้งาน"],
  "T100 BOM  /  SMT 站位表  ·  双向核对": [
    "T100 BOM / SMT placement · Bidirectional check",
    "T100 BOM / ตาราง SMT · ตรวจสอบสองทาง",
  ],
  "切换浅色主题": ["Switch to light theme", "เปลี่ยนเป็นธีมสว่าง"],
  "切换深色主题": ["Switch to dark theme", "เปลี่ยนเป็นธีมมืด"],
  "浅色": ["Light", "สว่าง"],
  "深色": ["Dark", "มืด"],
  "生产工程  /  QUALITY": ["ENGINEERING / QUALITY", "วิศวกรรม / คุณภาพ"],
  "本地核对引擎\n原文件只读 · 来源可追溯": [
    "Local checking engine\nRead-only files · Traceable sources",
    "ตรวจสอบภายในเครื่อง\nอ่านไฟล์อย่างเดียว · ตรวจสอบแหล่งที่มาได้",
  ],
  "单站位表": ["Single table", "ตารางเดียว"],
  "A + B 合并": ["Merge A + B", "รวม A + B"],
  "导入 BOM": ["Import BOM", "นำเข้า BOM"],
  "导入站位 A": ["Import SMT A", "นำเข้า SMT A"],
  "导入站位 B": ["Import SMT B", "นำเข้า SMT B"],
  "导入站位表": ["Import SMT", "นำเข้า SMT"],
  "开始核对": ["Run check", "เริ่มตรวจสอบ"],
  "清空重来": ["Clear / new check", "ล้างและเริ่มใหม่"],
  "已清空，可重新导入文件": [
    "Cleared. Ready to import new files.",
    "ล้างแล้ว พร้อมนำเข้าไฟล์ใหม่",
  ],
  "处理中…": ["Processing…", "กำลังประมวลผล…"],
  "正在处理…": ["Processing…", "กำลังประมวลผล…"],
  "待导入": ["Not imported", "ยังไม่ได้นำเข้า"],
  "尚未选择文件": ["No file selected", "ยังไม่ได้เลือกไฟล์"],
  "{count}行": ["{count} rows", "{count} แถว"],
  "单表模式对完整 BOM 核对；未覆盖另一面的料号仍列为异常。": [
    "Single-table mode checks the full BOM. Parts on the other side remain flagged as uncovered.",
    "โหมดตารางเดียวตรวจสอบกับ BOM ทั้งหมด รายการอีกด้านที่ไม่ครอบคลุมยังแสดงเป็นข้อผิดพลาด",
  ],
  "一致料号": ["Matched parts", "รายการตรงกัน"],
  "异常料号": ["Mismatched parts", "รายการผิดปกติ"],
  "排除记录": ["Excluded rows", "แถวที่ยกเว้น"],
  "候选料记录": ["Candidate rows", "แถววัสดุทางเลือก"],
  "从原始文件，核对每一项物料": [
    "Check every material against the source files",
    "ตรวจสอบวัสดุทุกรายการจากไฟล์ต้นฉบับ",
  ],
  "导入 T100-BOM 与一份或两份 SMT 站位表。自动识别表头，按料号汇总，用数量和位号交叉验证。": [
    "Import a T100 BOM and one or two SMT tables. Headers are detected automatically; quantities and reference designators are cross-checked by part number.",
    "นำเข้า T100 BOM และตาราง SMT หนึ่งหรือสองไฟล์ ระบบตรวจหาหัวตาราง รวมตามรหัสวัสดุ และตรวจสอบจำนวนกับตำแหน่งอุปกรณ์",
  ],
  "01   导入 BOM：料件编号 / 品名 / 组成用量 / 插件位置": [
    "01   Import BOM: Part number / Name / Usage / Positions",
    "01   นำเข้า BOM: รหัสวัสดุ / ชื่อ / จำนวนใช้ / ตำแหน่ง",
  ],
  "02   导入 SMT：料号 / 物料描述 / 数量 / 位号": [
    "02   Import SMT: Part number / Description / Quantity / References",
    "02   นำเข้า SMT: รหัสวัสดุ / รายละเอียด / จำนวน / ตำแหน่ง",
  ],
  "03   核对双向差异，逐项查看原因和原文件行号": [
    "03   Check both directions and inspect reasons and source row numbers",
    "03   ตรวจสอบความแตกต่างสองทาง พร้อมเหตุผลและเลขแถวต้นฉบับ",
  ],
  "查看排除规则": ["View exclusion rules", "ดูกฎการยกเว้น"],
  "非贴片物料排除规则": ["Non-SMT material exclusions", "กฎยกเว้นวัสดุที่ไม่ใช่ SMT"],
  "关键词排除：开启": ["Keyword exclusion: on", "ยกเว้นตามคำสำคัญ: เปิด"],
  "关键词排除：关闭": ["Keyword exclusion: off", "ยกเว้นตามคำสำคัญ: ปิด"],
  "恢复默认关键词": ["Restore default keywords", "คืนค่าคำสำคัญเริ่มต้น"],
  "按 BOM 品名 / SMT 物料描述包含关键词匹配，忽略大小写和空白。每行一条，也可用逗号分隔。": [
    "Match keywords within BOM names / SMT descriptions, ignoring case and whitespace. Enter one per line or separate with commas.",
    "ค้นหาคำสำคัญในชื่อ BOM หรือรายละเอียด SMT โดยไม่แยกตัวพิมพ์และช่องว่าง ใส่หนึ่งคำต่อบรรทัดหรือคั่นด้วยจุลภาค",
  ],
  "例如：锡膏\nPCB\n助焊剂\n包装材料": [
    "Example: solder paste\nPCB\nflux\npackaging",
    "ตัวอย่าง: ครีมบัดกรี\nPCB\nฟลักซ์\nวัสดุบรรจุภัณฑ์",
  ],
  "排除记录单独显示并写入报告，注明命中词与来源。零用量且无位号的总成记录单独排除；候选替代料不自动替换 BOM 料号。": [
    "Excluded rows stay visible in the report with matched keywords and sources. Zero-usage assemblies without positions are excluded separately. Candidate alternatives never replace BOM parts automatically.",
    "แถวที่ยกเว้นยังแสดงในรายงานพร้อมคำที่ตรงและแหล่งข้อมูล รายการชุดประกอบที่จำนวนเป็นศูนย์และไม่มีตำแหน่งจะแยกยกเว้น วัสดุทางเลือกจะไม่แทนรายการ BOM โดยอัตโนมัติ",
  ],
  "应用规则并重新核对": ["Apply rules and recheck", "ใช้กฎและตรวจสอบใหม่"],
  "导入审计": ["Import audit", "บันทึกการนำเข้า"],
  "导入文件后显示工作表、表头映射与读取记录。": [
    "Import files to see worksheets, header mappings and reading notes.",
    "นำเข้าไฟล์เพื่อดูแผ่นงาน การจับคู่หัวตาราง และบันทึกการอ่าน",
  ],
  "兼容 Chat Completions 的 AI 接口": [
    "Chat Completions compatible AI",
    "API ของ AI ที่รองรับ Chat Completions",
  ],
  "填写服务商或本地模型接口。分析前显示接收地址和发送范围；AI 建议独立显示，不改变核对状态。": [
    "Enter a provider or local model endpoint. The destination and scope are shown before sending. AI advice is separate from check results.",
    "ระบุ API ผู้ให้บริการหรือโมเดลภายในเครื่อง ระบบจะแสดงปลายทางและขอบเขตก่อนส่ง คำแนะนำ AI แสดงแยกจากผลตรวจสอบ",
  ],
  "API 基础地址": ["API base URL", "URL หลักของ API"],
  "https://服务商地址/v1 或 http://localhost:11434/v1": [
    "https://provider.example/v1 or http://localhost:11434/v1",
    "https://provider.example/v1 หรือ http://localhost:11434/v1",
  ],
  "模型名称": ["Model name", "ชื่อโมเดล"],
  "填写服务商实际支持的模型": [
    "Enter an available provider model",
    "ระบุโมเดลที่ผู้ให้บริการรองรับ",
  ],
  "API Key（本地无密钥服务可留空）": [
    "API key (optional for keyless local services)",
    "API Key (เว้นว่างได้สำหรับบริการในเครื่องที่ไม่ใช้คีย์)",
  ],
  "密钥仅在当前会话使用，不写入设置文件": [
    "The key stays in memory for this session only.",
    "คีย์ใช้เฉพาะเซสชันนี้และไม่บันทึกลงไฟล์ตั้งค่า",
  ],
  "保存设置": ["Save settings", "บันทึกการตั้งค่า"],
  "测试连接": ["Test connection", "ทดสอบการเชื่อมต่อ"],
  "正在分析…": ["Analyzing…", "กำลังวิเคราะห์…"],
  "分析异常": ["Analyze mismatches", "วิเคราะห์ข้อผิดพลาด"],
  "AI 分析结果": ["AI analysis result", "ผลการวิเคราะห์ AI"],
  "复制": ["Copy", "คัดลอก"],
  "分析结果已复制": ["Analysis copied", "คัดลอกผลการวิเคราะห์แล้ว"],
  "尚未调用 AI。可先测试连接，再分析核对异常。": [
    "No AI request yet. Test the connection, then analyze mismatches.",
    "ยังไม่ได้เรียก AI โปรดทดสอบการเชื่อมต่อแล้ววิเคราะห์ข้อผิดพลาด",
  ],
  "核对规则与操作": ["Checking rules and operation", "กฎและวิธีตรวจสอบ"],
  "文件与字段": ["Files and fields", "ไฟล์และฟิลด์"],
  "双向核对": ["Bidirectional check", "การตรวจสอบสองทาง"],
  "单表核对": ["Single-table check", "การตรวจสอบตารางเดียว"],
  "位号解析": ["Reference parsing", "การแยกตำแหน่งอุปกรณ์"],
  "排除与替代料": ["Exclusions and alternatives", "การยกเว้นและวัสดุทางเลือก"],
  "描述判断": ["Description matching", "การเทียบรายละเอียด"],
  "导出与 AI": ["Export and AI", "ส่งออกและ AI"],
  "快捷键": ["Keyboard shortcuts", "ปุ่มลัด"],
  "支持 .xlsx 原文件，自动扫描工作表寻找四个必需表头。旧版 .xls 请先另存为 .xlsx。BOM：料件编号→料号，品名→物料描述，组成用量→数量，插件位置→位号。":
      [
        "Reads .xlsx files and detects the four required headers across worksheets. Convert .xls to .xlsx first. BOM part number, name, usage and positions map to SMT part number, description, quantity and references.",
        "รองรับไฟล์ .xlsx และค้นหาหัวตารางที่จำเป็นสี่รายการในแผ่นงาน แปลง .xls เป็น .xlsx ก่อน รหัสวัสดุ ชื่อ จำนวนใช้ และตำแหน่งใน BOM จะจับคู่กับรหัสวัสดุ รายละเอียด จำนวน และตำแหน่งใน SMT",
      ],
  "以料号关联，同料号跨站位/跨 A、B 面累计数量并合并位号；检查 BOM 缺料、SMT 多料、描述不符、数量差异、缺失/多出位号、跨行重复位号和位号归属冲突。":
      [
        "Join by part number and combine quantities and references across stations and A/B sides. Check missing or extra parts, descriptions, quantities, reference sets, duplicate references and conflicting ownership.",
        "จับคู่ตามรหัสวัสดุ รวมจำนวนและตำแหน่งข้ามสถานีและด้าน A/B ตรวจวัสดุขาดหรือเกิน รายละเอียด จำนวน ตำแหน่งที่ขาดหรือเกิน ตำแหน่งซ้ำ และวัสดุที่ใช้ตำแหน่งเดียวกัน",
      ],
  "单表仍与完整 BOM 比较。另一面的料号可能没有覆盖，会明确列为异常，不能据此声称整板一致。": [
    "A single table is still compared with the full BOM. Parts on the other side may be uncovered and remain mismatches; this cannot establish full-board agreement.",
    "ตารางเดียวยังเทียบกับ BOM ทั้งหมด วัสดุอีกด้านอาจไม่ครอบคลุมและจะแสดงเป็นข้อผิดพลาด จึงไม่ถือว่าทั้งแผงตรงกัน",
  ],
  "支持逗号、空格、分号、中文分隔符和 R1-R4 / R1~R4 区间。T100 折行在数字续接或纯数字前缀处还原；无法识别的位号会报错，不静默丢弃。":
      [
        "Supports commas, spaces, semicolons, Chinese separators and R1-R4 / R1~R4 ranges. T100 numeric line wraps are restored. Unknown references are reported rather than discarded.",
        "รองรับจุลภาค ช่องว่าง อัฒภาค ตัวคั่นจีน และช่วง R1-R4 / R1~R4 ระบบเชื่อมตัวเลขที่ถูกตัดบรรทัดของ T100 ตำแหน่งที่ไม่รู้จักจะแจ้งข้อผิดพลาดโดยไม่ละทิ้ง",
      ],
  "关键词只匹配品名/物料描述。排除和候选替代料不会算入通过数，全部可复查。没有数量和位号的候选替代料不会自动替代主料号。": [
    "Keywords match names/descriptions only. Excluded and candidate rows are auditable and never counted as matched. Alternatives without quantities and references never replace primary BOM parts automatically.",
    "คำสำคัญจับคู่เฉพาะชื่อหรือรายละเอียด แถวที่ยกเว้นและวัสดุทางเลือกตรวจสอบย้อนหลังได้และไม่นับว่าตรงกัน วัสดุทางเลือกที่ไม่มีจำนวนและตำแหน่งจะไม่แทนวัสดุหลักอัตโนมัติ",
  ],
  "只忽略空白与英文大小写。±/+/数值/封装/品牌差异均保留并报告，不自动判断为等效。数量与各原始行的位号数也逐行交叉检查。": [
    "Only whitespace and letter case are ignored. Differences in ±/+, values, package and brand are reported, not assumed equivalent. Each source row's quantity is cross-checked against its reference count.",
    "ละเว้นเฉพาะช่องว่างและตัวพิมพ์ภาษาอังกฤษ ความต่างของ ±/+ ค่าตัวเลข แพ็กเกจ และยี่ห้อจะแจ้งโดยไม่ถือว่าเทียบเท่า พร้อมตรวจจำนวนเทียบกับจำนวนตำแหน่งในแต่ละแถว",
  ],
  "CSV 可由 Excel 打开，JSON 保留完整来源和规则。主动点击发送分析后才向所填 AI 接口发送异常数据。没有 AI 密钥也能完成本地核对。":
      [
        "Excel can open CSV; JSON retains full sources and rules. Mismatch data is sent only after you choose to send it to the configured AI endpoint. Local checks work without an AI key.",
        "Excel เปิด CSV ได้ ส่วน JSON เก็บแหล่งข้อมูลและกฎครบถ้วน ส่งข้อมูลผิดปกติไป API ที่ตั้งค่าเมื่อคุณเลือกส่งเท่านั้น การตรวจสอบในเครื่องทำได้โดยไม่ต้องมีคีย์ AI",
      ],
  "Ctrl+O 导入 BOM；Ctrl+Enter 开始核对；Ctrl+E 导出 CSV。表格可横向滚动，点击料号行查看完整证据。": [
    "Ctrl+O imports BOM; Ctrl+Enter runs checks; Ctrl+E exports CSV; Ctrl+N clears the session. Scroll tables horizontally and select a row for full evidence.",
    "Ctrl+O นำเข้า BOM; Ctrl+Enter ตรวจสอบ; Ctrl+E ส่งออก CSV; Ctrl+N ล้างเซสชัน เลื่อนตารางแนวนอนและเลือกแถวเพื่อดูหลักฐานครบถ้วน",
  ],
  "全部": ["All", "ทั้งหมด"],
  "异常": ["Mismatch", "ผิดปกติ"],
  "一致": ["Match", "ตรงกัน"],
  "已排除": ["Excluded", "ยกเว้น"],
  "候选料": ["Candidate", "ทางเลือก"],
  "候选替代料": ["Candidate", "ทางเลือก"],
  "搜索料号、位号或原因": [
    "Search part, reference or reason",
    "ค้นหารหัส ตำแหน่ง หรือเหตุผล",
  ],
  "导出 CSV": ["Export CSV", "ส่งออก CSV"],
  "没有符合筛选条件的记录": [
    "No records match this filter",
    "ไม่มีรายการที่ตรงกับตัวกรอง",
  ],
  "状态": ["Status", "สถานะ"],
  "料号": ["Part number", "รหัสวัสดุ"],
  "品名 / 物料描述": ["Name / description", "ชื่อ / รายละเอียด"],
  "BOM数量": ["BOM qty", "จำนวน BOM"],
  "SMT数量": ["SMT qty", "จำนวน SMT"],
  "核对结果 / 异常原因": ["Result / mismatch reason", "ผลตรวจสอบ / สาเหตุผิดปกติ"],
  "选择左侧一条物料，查看字段对照、异常原因和原文件证据。": [
    "Select a material to inspect field comparisons, mismatch reasons and source evidence.",
    "เลือกวัสดุเพื่อดูการเทียบฟิลด์ สาเหตุผิดปกติ และหลักฐานจากต้นฉบับ",
  ],
  "显示 {count} / {total} 条记录 · 点击行查看完整差异 · 已排除和候选料单独统计": [
    "Showing {count} / {total} rows · Select a row for details · Excluded and candidate rows counted separately",
    "แสดง {count} / {total} แถว · เลือกแถวเพื่อดูรายละเอียด · นับแถวที่ยกเว้นและทางเลือกแยกกัน",
  ],
  "空料号": ["Empty part number", "รหัสวัสดุว่าง"],
  "核对原因": ["Check reasons", "เหตุผลการตรวจสอบ"],
  "AI 分析此项": ["Analyze this item", "วิเคราะห์รายการนี้"],
  "T100-BOM 原始记录": ["T100 BOM source rows", "แถวต้นฉบับ T100 BOM"],
  "SMT 站位表原始记录": ["SMT source rows", "แถวต้นฉบับ SMT"],
  "没有对应记录": ["No corresponding row", "ไม่มีแถวที่ตรงกัน"],
  "第 {row} 行": ["Row {row}", "แถว {row}"],
  "站位 {station}": ["Station {station}", "สถานี {station}"],
  "数量": ["Quantity", "จำนวน"],
  "位号": ["References", "ตำแหน่งอุปกรณ์"],
  "空": ["Empty", "ว่าง"],
  "单表": ["Single table", "ตารางเดียว"],
  "就绪 · 文件在本机核对": [
    "Ready · Files checked locally",
    "พร้อม · ตรวจสอบไฟล์ในเครื่อง",
  ],
  "设置存储不可用 · 当前会话仍可核对": [
    "Settings storage unavailable · Checks still work in this session",
    "ไม่สามารถบันทึกการตั้งค่า · ยังตรวจสอบในเซสชันนี้ได้",
  ],
  "正在解析原始工作簿…": ["Reading source workbook…", "กำลังอ่านสมุดงานต้นฉบับ…"],
  "已导入 {file} · {count} 行": [
    "Imported {file} · {count} rows",
    "นำเข้า {file} · {count} แถวแล้ว",
  ],
  "导入失败": ["Import failed", "นำเข้าไม่สำเร็จ"],
  "导入失败：{message}": ["Import failed: {message}", "นำเข้าไม่สำเร็จ: {message}"],
  "文件选择失败：{message}": [
    "File selection failed: {message}",
    "เลือกไฟล์ไม่สำเร็จ: {message}",
  ],
  "核对失败：{message}": ["Check failed: {message}", "ตรวจสอบไม่สำเร็จ: {message}"],
  "请先导入 BOM、站位表 A 和 B": [
    "Import BOM and SMT A and B first",
    "โปรดนำเข้า BOM และ SMT A กับ B ก่อน",
  ],
  "请先导入 BOM 和一份站位表": [
    "Import BOM and one SMT table first",
    "โปรดนำเข้า BOM และตาราง SMT หนึ่งไฟล์ก่อน",
  ],
  "核对完成 · {pass} 项一致 / {error} 项异常": [
    "Check complete · {pass} matched / {error} mismatched",
    "ตรวจสอบเสร็จ · ตรงกัน {pass} / ผิดปกติ {error}",
  ],
  "规则已应用，持久保存失败": [
    "Rules applied; could not save settings",
    "ใช้กฎแล้ว แต่บันทึกการตั้งค่าไม่สำเร็จ",
  ],
  "排除规则已保存": ["Exclusion rules saved", "บันทึกกฎการยกเว้นแล้ว"],
  "语言已切换，持久保存失败": [
    "Language changed; could not save preference",
    "เปลี่ยนภาษาแล้ว แต่บันทึกค่าที่เลือกไม่สำเร็จ",
  ],
  "接口和模型已保存，密钥仅在当前会话使用": [
    "Endpoint and model saved; key remains in this session only",
    "บันทึก API และโมเดลแล้ว คีย์ใช้เฉพาะเซสชันนี้",
  ],
  "保存失败：{message}": ["Save failed: {message}", "บันทึกไม่สำเร็จ: {message}"],
  "请先完成一次核对": ["Run a check first", "โปรดตรวจสอบก่อน"],
  "发送异常数据至 AI": ["Send mismatch data to AI", "ส่งข้อมูลผิดปกติไปยัง AI"],
  "接收地址：{host}\n将发送{scope}的料号、描述、数量、位号及来源行号。原始 Excel 文件不会上传。": [
    "Destination: {host}\nPart numbers, descriptions, quantities, references and source rows for {scope} will be sent. Original Excel files are not uploaded.",
    "ปลายทาง: {host}\nจะส่งรหัสวัสดุ รายละเอียด จำนวน ตำแหน่ง และแถวต้นฉบับสำหรับ{scope} โดยไม่อัปโหลดไฟล์ Excel ต้นฉบับ",
  ],
  "最多前 40 项异常": [
    "up to the first 40 mismatches",
    "ข้อผิดพลาดสูงสุด 40 รายการแรก",
  ],
  "当前料号 {part}": ["part {part}", "รหัสวัสดุ {part}"],
  "发送并分析": ["Send and analyze", "ส่งและวิเคราะห์"],
  "取消": ["Cancel", "ยกเลิก"],
  "正在测试连接…": ["Testing connection…", "กำลังทดสอบการเชื่อมต่อ…"],
  "正在分析异常…": ["Analyzing mismatches…", "กำลังวิเคราะห์ข้อผิดพลาด…"],
  "调用失败：{message}\n请核对接口地址、模型、密钥与网络；规则核对结果仍然保留。": [
    "Request failed: {message}\nCheck the endpoint, model, key and network. Rule-based results remain available.",
    "เรียกใช้ไม่สำเร็จ: {message}\nโปรดตรวจ API โมเดล คีย์ และเครือข่าย ผลตรวจสอบตามกฎยังคงอยู่",
  ],
  "报告已导出：{file}": ["Report exported: {file}", "ส่งออกรายงานแล้ว: {file}"],
  "导出失败：{message}": ["Export failed: {message}", "ส่งออกไม่สำเร็จ: {message}"],
  "FormatException: {message}": [
    "Format error: {message}",
    "รูปแบบไม่ถูกต้อง: {message}",
  ],
  "Bad state: {message}": ["Error: {message}", "ข้อผิดพลาด: {message}"],
  "零用量且无插件位置的总成/占位记录": [
    "Zero-usage assembly/placeholder without positions",
    "ชุดประกอบหรือรายการตัวแทนที่จำนวนเป็นศูนย์และไม่มีตำแหน่ง",
  ],
  "品名/物料描述命中排除关键词「{keyword}」": [
    "Name/description matches exclusion keyword “{keyword}”",
    "ชื่อหรือรายละเอียดตรงกับคำสำคัญที่ยกเว้น “{keyword}”",
  ],
  "无站位、数量和位号：候选替代料记录，不累计贴装数量；不自动认定为BOM料号替代。": [
    "No station, quantity or references: candidate alternative; excluded from placement totals and never treated as an approved BOM replacement.",
    "ไม่มีสถานี จำนวน หรือตำแหน่ง: เป็นวัสดุทางเลือก ไม่นับรวมจำนวนติดตั้งและไม่ถือว่าได้รับอนุมัติให้แทน BOM",
  ],
  "料号为空，无法关联核对": [
    "Empty part number; cannot link rows",
    "รหัสวัสดุว่าง ไม่สามารถจับคู่แถวได้",
  ],
  "站位表多料：BOM 中没有该料号": [
    "Extra SMT material: part number absent from BOM",
    "วัสดุ SMT เกิน: ไม่พบรหัสนี้ใน BOM",
  ],
  "单站位表未覆盖此 BOM 料号；可能位于另一面，需完整站位资料确认": [
    "Single table does not cover this BOM part; it may be on the other side. Complete SMT data is required.",
    "ตารางเดียวไม่ครอบคลุมวัสดุ BOM นี้ อาจอยู่ด้านอื่น ต้องยืนยันด้วยข้อมูล SMT ที่ครบถ้วน",
  ],
  "BOM 有料，A+B 合并站位表缺少此料号": [
    "BOM part missing from merged SMT A+B",
    "มีวัสดุใน BOM แต่ไม่พบใน SMT A+B รวม",
  ],
  "品名/物料描述不一致（仅忽略大小写和空白，未自动认定规格或品牌等效）": [
    "Name/description differs (only case and whitespace ignored; specifications and brands are not assumed equivalent)",
    "ชื่อหรือรายละเอียดไม่ตรงกัน (ละเว้นเฉพาะตัวพิมพ์และช่องว่าง ไม่ถือว่าสเปกหรือยี่ห้อเทียบเท่ากัน)",
  ],
  "料号、描述、汇总数量与位号集合全部一致": [
    "Part number, description, total quantity and reference set all match",
    "รหัสวัสดุ รายละเอียด จำนวนรวม และชุดตำแหน่งตรงกันทั้งหมด",
  ],
  "SMT 缺少位号：{positions}": [
    "SMT missing references: {positions}",
    "SMT ขาดตำแหน่ง: {positions}",
  ],
  "SMT 多出位号：{positions}": [
    "SMT extra references: {positions}",
    "SMT มีตำแหน่งเกิน: {positions}",
  ],
  "数量不符：BOM {bom}，SMT {smt}，差额 {difference}（SMT − BOM）": [
    "Quantity mismatch: BOM {bom}, SMT {smt}, difference {difference} (SMT − BOM)",
    "จำนวนไม่ตรง: BOM {bom}, SMT {smt}, ผลต่าง {difference} (SMT − BOM)",
  ],
  "{side} 位号 {position} 跨行重复/冲突：{owners}": [
    "{side} reference {position} duplicated/conflicting across rows: {owners}",
    "ตำแหน่ง {position} ของ {side} ซ้ำหรือขัดแย้งข้ามแถว: {owners}",
  ],
  "{file} 第 {row} 行：{message}": [
    "{file}, row {row}: {message}",
    "{file}, แถว {row}: {message}",
  ],
  "数量「{quantity}」不是有效正数": [
    "Quantity “{quantity}” is not a valid positive number",
    "จำนวน “{quantity}” ไม่ใช่ตัวเลขบวกที่ถูกต้อง",
  ],
  "品名/物料描述为空": ["Name/description is empty", "ชื่อหรือรายละเอียดว่าง"],
  "没有有效位号，请确认是否为非贴片物料或资料缺失": [
    "No valid references; check for non-SMT material or missing data",
    "ไม่มีตำแหน่งที่ถูกต้อง โปรดยืนยันว่าเป็นวัสดุที่ไม่ใช่ SMT หรือข้อมูลขาดหาย",
  ],
  "数量 {quantity} 与位号数 {count} 不一致": [
    "Quantity {quantity} differs from reference count {count}",
    "จำนวน {quantity} ไม่ตรงกับจำนวนตำแหน่ง {count}",
  ],
  "无法解析位号区间「{range}」": [
    "Cannot parse reference range “{range}”",
    "ไม่สามารถแยกช่วงตำแหน่ง “{range}”",
  ],
  "无法识别位号「{position}」": [
    "Unknown reference “{position}”",
    "ไม่รู้จักตำแหน่ง “{position}”",
  ],
  "位号 {position} 在同一行重复 {count} 次": [
    "Reference {position} occurs {count} times in the same row",
    "ตำแหน่ง {position} ซ้ำ {count} ครั้งในแถวเดียว",
  ],
  "需要一份或两份站位表": [
    "One or two SMT tables are required",
    "ต้องมีตาราง SMT หนึ่งหรือสองไฟล์",
  ],
  "A、B 不可使用同一份文件，以免重复累计": [
    "A and B must use different files to avoid double counting",
    "A และ B ต้องใช้คนละไฟล์เพื่อไม่ให้นับซ้ำ",
  ],
  "请输入有效的 API 基础地址，不包含密钥、查询参数或片段。": [
    "Enter a valid API base URL without credentials, query parameters or fragments.",
    "ระบุ URL หลักของ API ที่ถูกต้อง โดยไม่ใส่คีย์ พารามิเตอร์ หรือส่วน fragment",
  ],
  "云端接口需要 HTTPS，本地接口可用 HTTP。": [
    "Cloud endpoints require HTTPS. Local endpoints may use HTTP.",
    "API บนคลาวด์ต้องใช้ HTTPS ส่วน API ในเครื่องใช้ HTTP ได้",
  ],
  "请填写模型名称。": ["Enter a model name.", "โปรดระบุชื่อโมเดล"],
  "请填写 API Key。": ["Enter an API key.", "โปรดระบุ API Key"],
  "本次异常内容过长，请选中单个料号后分析。": [
    "The mismatch data is too long. Select one part to analyze.",
    "ข้อมูลผิดปกติยาวเกินไป โปรดเลือกวัสดุหนึ่งรายการเพื่อวิเคราะห์",
  ],
  "AI 返回的不是有效 JSON，请确认兼容接口地址。": [
    "AI returned invalid JSON. Check the compatible endpoint URL.",
    "AI ส่ง JSON ไม่ถูกต้อง โปรดตรวจ URL ของ API",
  ],
  "AI 未返回可显示的文本，需检查模型和接口兼容性。": [
    "AI returned no displayable text. Check model and endpoint compatibility.",
    "AI ไม่ส่งข้อความที่แสดงได้ โปรดตรวจโมเดลและความเข้ากันได้ของ API",
  ],
  "AI 接口 HTTP {detail}": [
    "AI endpoint HTTP {detail}",
    "API ของ AI HTTP {detail}",
  ],
  "核对模式": ["Check mode", "โหมดตรวจสอบ"],
  "A+B合并": ["Merge A+B", "รวม A+B"],
  "单站位表与完整BOM比较": [
    "Single SMT table vs full BOM",
    "ตาราง SMT เดียวเทียบ BOM ทั้งหมด",
  ],
  "单站位表（与完整BOM比较）": [
    "Single SMT table (vs full BOM)",
    "ตาราง SMT เดียว (เทียบ BOM ทั้งหมด)",
  ],
  "时间": ["Time", "เวลา"],
  "排除启用": ["Exclusion enabled", "เปิดใช้การยกเว้น"],
  "排除关键词": ["Exclusion keywords", "คำสำคัญที่ยกเว้น"],
  "BOM品名": ["BOM name", "ชื่อใน BOM"],
  "SMT物料描述": ["SMT description", "รายละเอียด SMT"],
  "BOM用量": ["BOM usage", "จำนวนใช้ BOM"],
  "BOM位号": ["BOM references", "ตำแหน่ง BOM"],
  "SMT位号": ["SMT references", "ตำแหน่ง SMT"],
  "异常/原因": ["Mismatch / reason", "ข้อผิดพลาด / เหตุผล"],
  "BOM来源": ["BOM source", "แหล่ง BOM"],
  "SMT来源": ["SMT source", "แหล่ง SMT"],
  "表头映射": ["Header mappings", "การจับคู่หัวตาราง"],
  "导入说明": ["Import notes", "หมายเหตุการนำเข้า"],
  "请使用 .xlsx 文件；旧版 .xls 请先另存为 .xlsx。": [
    "Use .xlsx files. Save legacy .xls files as .xlsx first.",
    "โปรดใช้ไฟล์ .xlsx และแปลงไฟล์ .xls เป็น .xlsx ก่อน",
  ],
  "文件超过 30 MB，请拆分工作簿后导入。": [
    "File exceeds 30 MB. Split the workbook before importing.",
    "ไฟล์เกิน 30 MB โปรดแบ่งสมุดงานก่อนนำเข้า",
  ],
  "工作簿解压体积超过限制。": [
    "Expanded workbook exceeds the size limit.",
    "ขนาดสมุดงานหลังแตกไฟล์เกินขีดจำกัด",
  ],
  "无法读取工作簿，文件可能损坏或已加密。": [
    "Cannot read workbook; it may be corrupted or encrypted.",
    "อ่านสมุดงานไม่ได้ ไฟล์อาจเสียหายหรือถูกเข้ารหัส",
  ],
  "{sheet}：工作表关系缺失": [
    "{sheet}: worksheet relationship missing",
    "{sheet}: ไม่พบความสัมพันธ์ของแผ่นงาน",
  ],
  "{sheet}：缺少工作表数据，无法完成完整核对": [
    "{sheet}: worksheet data missing; a complete check is impossible",
    "{sheet}: ไม่มีข้อมูลแผ่นงาน จึงตรวจสอบอย่างครบถ้วนไม่ได้",
  ],
  "{sheet}：未检测到四个必需表头，未作为数据表导入": [
    "{sheet}: four required headers not found; not imported as a data table",
    "{sheet}: ไม่พบหัวตารางที่จำเป็นสี่รายการ จึงไม่ได้นำเข้าเป็นตารางข้อมูล",
  ],
  "{sheet}：导入 {count} 行，含候选替代料行": [
    "{sheet}: imported {count} rows, including candidate alternatives",
    "{sheet}: นำเข้า {count} แถว รวมแถววัสดุทางเลือก",
  ],
  "{sheet} 第 {row} 行使用公式缓存值，请确保原文件已重算保存": [
    "{sheet}, row {row}: cached formula value used; recalculate and save the source file",
    "{sheet}, แถว {row}: ใช้ค่าที่เก็บไว้ของสูตร โปรดคำนวณและบันทึกต้นฉบับใหม่",
  ],
  "{field} 含公式但没有缓存值，请用 Excel 重算并保存": [
    "{field} contains a formula without a cached value; recalculate and save in Excel",
    "{field} มีสูตรแต่ไม่มีค่าที่เก็บไว้ โปรดคำนวณและบันทึกใน Excel ใหม่",
  ],
  "{field} 含 Excel 错误值 {error}": [
    "{field} contains Excel error {error}",
    "{field} มีค่าผิดพลาด Excel {error}",
  ],
  "未找到有效{kind}数据。必需字段：{fields}": [
    "No valid {kind} data found. Required headers: {fields}",
    "ไม่พบข้อมูล {kind} ที่ถูกต้อง หัวตารางที่ต้องมี: {fields}",
  ],
};
