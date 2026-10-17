window.FUSION_CONTENT = {
  "zh": {
    "lang": "zh-CN",
    "title": "SMT Fusion · BOM 核对与 CAD 坐标生成",
    "nav": [
      "功能",
      "下载",
      "使用教程",
      "常见问题"
    ],
    "eyebrow": "原生桌面 · Windows / Linux / macOS",
    "hero": [
      "把核对做准。",
      "把坐标接上。"
    ],
    "lead": "从 T100 BOM 与 SMT 站位表的双向核对，到人工确认、合并导出和 FAI-i450 坐标生成。让每一项物料、每一个位号都有据可查。",
    "download": "下载桌面版",
    "guide": "阅读使用教程",
    "release": "最新正式版",
    "local": "本地核对，无需安装 Excel",
    "demo": "原生应用界面 · 数据为演示样例",
    "enlarge": "查看完整界面 ↗",
    "workflowTitle": "一条清晰的工作路径",
    "workflowLabel": "工作流程",
    "workflow": [
      [
        "导入原文件",
        "读取 T100 BOM 与单份或 A+B SMT 站位表，保留文件、工作表和原始行号。"
      ],
      [
        "核对与复核",
        "分别检查料号、描述、数量和位号。PASS、NG、排除和候选料各自可见。"
      ],
      [
        "人工确认后合并",
        "逐项确认 NG、排除及候选料的纳入方式，再生成四列预览并自定义文件名。"
      ],
      [
        "生成与检查坐标",
        "导入原坐标、明确单位，按 RefDes 关联并生成十列 FAI-i450 Excel。"
      ]
    ],
    "evidenceLabel": "差异与证据",
    "evidenceTitle": "逐项定位差异，保留原始证据。",
    "evidenceText": "直接看到哪一项字段不同，以及差异来自哪一份文件、哪一个原始记录。",
    "evidencePoints": [
      "BOM 插件位置与 SMT 位号并排显示。",
      "数量、描述、缺失及多出位号分别说明。",
      "排除和候选物料保留独立分类，不计入 PASS。"
    ],
    "sampleHeaders": [
      "料号",
      "BOM / SMT 位号",
      "结果"
    ],
    "sampleNote": "示例：C104 在 SMT 站位表中缺失，数量比 BOM 少 1。",
    "coordinateLabel": "可靠的坐标处理",
    "coordinateTitle": "以位号关联，保留坐标精度。",
    "coordinateText": "按 RefDes、板号和层别匹配，区分真实差异、数据质量问题，以及不影响使用的排序和浮点精度差异。",
    "coordinateNote": "坐标默认比较容差 ±0.001 mm，角度 ±0.001°，支持 0°/360° 等效比较。这些是文件数据比较容差，不代表设备检测公差。",
    "specialText": "TP / FID / MH / NPTH 单独标记。默认保留原始记录，可配置规则或人工确认，不将测试点自动认定为无需检测。",
    "downloadsTitle": "选择适合你的桌面版本",
    "downloadsText": "完整单文件安装包。安装后直接启动，日常更新在软件内部完成。",
    "winNote": "Windows 10/11 · x64 / ARM64",
    "linuxNote": "Ubuntu 22.04+ / 兼容 Debian 环境",
    "macNote": "macOS 12+ · Intel / Apple Silicon",
    "setup": "安装程序",
    "deb": "DEB 安装包",
    "pkg": "通用 PKG 安装包",
    "dmg": "通用 DMG 镜像",
    "winSmall": "已包含应用运行库；安装向导支持中文、英文、泰文。",
    "linuxSmall": "请由系统软件安装器安装，并按提示补齐系统依赖。",
    "macSmall": "PKG 用于直接安装和应用内更新；DMG 可用于拖放安装。",
    "downloadNote": "安装包沿用 SMT-CHECK 文件名以兼容旧版升级。",
    "checksums": "版本记录与 SHA-256 校验",
    "faqTitle": "使用前，你可能想了解",
    "faq": [
      [
        "必须安装 Excel 或 AI 服务吗？",
        "不需要。确定性核对、合并和坐标生成均在本地运行。AI 是可选辅助功能。"
      ],
      [
        "原始文件会被修改或上传吗？",
        "原始 Excel 只读，本地流程不上传。仅在选择 AI 功能并确认发送范围后，相关内容才发送到你自行配置的接口。"
      ],
      [
        "人工确认会把 NG 变成 PASS 吗？",
        "不会。人工确认只决定是否将相应 SMT 记录纳入合并，原始核对状态及证据会保留。CAD 数据错误仍会阻止坐标导出。"
      ],
      [
        "TP 测试点会自动被删除吗？",
        "不会。特殊元件默认保留，分类与处置可配置。排除需保留决定与原因，缺失的 TP10_1 等位号仍明确报告。"
      ],
      [
        "软件内更新如何使用？",
        "打开“设置 → 关于与更新”。下载进度、取消、文件大小与 SHA-256 校验在软件内完成，通过后再启动系统安装器。"
      ]
    ],
    "footer": "为可追溯的 SMT 核对与 CAD 文件准备而设计。",
    "source": "源码",
    "versions": "版本记录",
    "guideTitle": "从第一次导入，到完成核对与导出。",
    "guideIntro": "按下面的顺序操作。每章都说明需要准备什么、点击哪里、如何判断结果，以及遇到问题后怎么处理。",
    "search": "搜索教程关键词",
    "contents": "操作目录",
    "noResults": "未找到相关章节，请尝试其他关键词。",
    "fieldHeaders": [
      "T100 BOM 原字段",
      "SMT 原字段"
    ],
    "sections": [
      {
        "id": "start",
        "title": "快速开始",
        "steps": [
          "安装与你的系统和架构匹配的完整安装包，启动 SMT Fusion。",
          "在核对工作台选择“单站位表”或“A+B 合并”。",
          "从文件栏导入 T100 BOM、SMT A，以及合并模式需要的 SMT B。",
          "点击“开始核对”，按 PASS、NG、已排除物料和候选料筛选。",
          "点击记录查看原始字段和异常原因；完成复核后进入“合并与导出”。"
        ],
        "note": "单表仍与完整 BOM 比较。另一面没有覆盖的料号会列为异常，不能据此判断整板通过。",
        "intro": "第一次使用时，先用一份 BOM 和对应站位表完成本地核对。AI 为可选步骤，不影响本地功能。",
        "before": [
          "准备 T100 BOM 原始 .xlsx。",
          "准备同一项目、同一版本的 SMT A；需要双面核对时同时准备 SMT B。"
        ],
        "expected": "工作台出现 PASS、NG、已排除物料、候选料分类；点击 NG 能看到具体字段差异。",
        "example": "推荐顺序：安装 → 导入 → 本地核对 → 逐项复核 → 合并预览 → 导出。需要坐标时，再进入 CAD 坐标工作区。"
      },
      {
        "id": "install",
        "after": "start",
        "title": "安装与选择平台",
        "intro": "下载与你的操作系统和处理器架构对应的完整安装包，安装后直接启动。无需解压文件集合。",
        "before": [
          "Windows 在系统设置 → 关于中查看 x64 或 ARM64。",
          "Linux 按发行版和架构选择；macOS 通用包同时支持 Intel 与 Apple Silicon。"
        ],
        "steps": [
          "Windows：运行 Setup.exe，选择安装目录并完成安装向导，从开始菜单启动 SMT Fusion。",
          "Linux：用系统软件安装器打开 AMD64 或 ARM64 的 .deb，并按提示安装依赖。",
          "macOS：优先使用通用 .pkg；也可打开 .dmg，将应用拖到 Applications。",
          "首次启动进入核对工作台，默认浅色；在右上角切换中文、English 或 ไทย。"
        ],
        "expected": "软件作为独立桌面窗口启动。本地核对不要求安装 Excel、Python 或配置 AI。",
        "note": "如果 macOS 首次启动被系统阻止，请使用系统设置中的正式允许打开流程；安装包的签名状态以发布说明为准。"
      },
      {
        "id": "files",
        "title": "字段映射与导入检查",
        "steps": [
          "BOM / SMT 核对支持 .xlsx 原文件。旧 .xls 请先另存为 .xlsx。",
          "表头会自动扫描识别；在“设置 → 导入与规则”查看导入审计。",
          "导入后检查文件名和行数，在设置中的导入审计核实读取来源。"
        ],
        "note": "排除不等于通过，不能用关键词规则隐藏真实贴装差异。",
        "fields": true,
        "intro": "BOM 和站位表表头不同，软件根据下面四组字段读取。原文件只读，不以 Excel 行号配对元件。",
        "before": [
          "确认文件可正常打开，且是 .xlsx，而不是仅修改后缀的 .xls。",
          "检查料号、描述、数量、位号四个必需表头；位号列表属于同一个物料时放在对应内容中。"
        ],
        "expected": "每个导入栏显示文件名和读取行数；悬停可查看完整路径。在设置 → 导入与规则查看工作表、字段和原始记录审计。",
        "example": "BOM 的“组成用量”2、“插件位置”R101,R102，对应 SMT 的“数量”2、“位号”R101,R102。两份文件行顺序可以不同。"
      },
      {
        "id": "check",
        "after": "files",
        "title": "开始核对与判读结果",
        "intro": "根据同一项目的 BOM 与站位表核对料号、描述、数量和位号。先判断分类，再查看具体差异。",
        "before": [
          "选择单站位表或 A+B 合并模式并导入完整文件。"
        ],
        "steps": [
          "单站位表只导入一份 SMT 文件；A+B 模式分别导入 A 和 B。",
          "点击“开始核对”，等待工作台显示结果。料号总数是两侧去重并集，不等于结果记录条数。",
          "按 PASS、NG、已排除物料或候选料筛选；用料号、位号或原因搜索。",
          "点击某行或“查看具体差异”，在详情中比较两侧字段、工作表和原始行号。",
          "处理 NG 时先确认实际差异：数量多/少、缺失/多出位号、同位号归属冲突或描述不同。"
        ],
        "expected": "每个 NG 都有可追溯原因。PASS 不包含排除和候选料；单表对完整 BOM 时，另一面的物料仍可能显示缺失。",
        "table": {
          "heads": [
            "类别",
            "含义",
            "下一步"
          ],
          "rows": [
            [
              "PASS",
              "四项核对满足当前规则",
              "按需要复查或进入合并"
            ],
            [
              "NG",
              "真实差异或数据质量问题",
              "查看原因并确认源数据"
            ],
            [
              "已排除物料",
              "描述命中排除关键词",
              "复查命中词，合并前人工确认"
            ],
            [
              "候选料",
              "候选替代记录单独列出",
              "人工确认，不自动替换主料"
            ]
          ]
        }
      },
      {
        "id": "rules",
        "after": "check",
        "title": "非贴片物料与排除规则",
        "intro": "排除规则只影响核对分类，原始数据仍可见。规则不应被用来掩盖真正的贴装差异。",
        "before": [
          "由实际工艺确认哪些耗材或非贴片物料需要排除。"
        ],
        "steps": [
          "打开设置 → 导入与规则 → 非贴片物料排除规则。",
          "每行输入一个关键词，也可用逗号分隔，例如“贴纸”“碳带”“锡膏”。",
          "关键词匹配 BOM 品名或 SMT 物料描述，忽略大小写和空白，不按料号任意猜测。",
          "应用规则后重新核对；命中词的料号及对应记录直接列入已排除物料。",
          "点击排除记录检查命中关键词、来源和导入问题；合并前仍需逐项人工确认。"
        ],
        "expected": "排除记录不计入 PASS 或 NG，且能够搜索、查看来源和导出。改变规则会使旧核对和预览失效。",
        "note": "“缺少位号”并不自动等于非贴片物料。没有命中规则的记录仍需检查；TP 测试点的处理应由实际工艺决定。"
      },
      {
        "id": "review",
        "title": "人工确认、合并与导出",
        "steps": [
          "打开顶部“合并与导出”。NG、已排除和候选物料必须逐项确认纳入或不纳入。",
          "全部必需项目确认后，选择保留明细或同料号汇总，生成合并预览。",
          "汇总仅适用于料号、描述相同且数量有效的记录；位号按原样拼接，不擅自去重。",
          "软件内检查预览中的“料号、物料描述、数量、位号”四列。",
          "输入文件名并导出 .xlsx，文件名自动以 BOM 结尾。撤销确认会使旧预览失效。"
        ],
        "note": "人工确认保留原 NG / 排除 / 候选分类，并不改写源文件或自动补造 SMT 记录。",
        "intro": "人工确认表示你决定如何处理一项记录，不会把 NG 改成 PASS。所有待确认项完成后，才能生成和导出合并文件。",
        "before": [
          "先完成当前导入文件的本地核对。",
          "先检查每项差异原因，再根据实际工艺决定是否纳入 SMT 合并文件。"
        ],
        "expected": "待确认计数为 0，生成合并预览可用；预览只包含“料号、物料描述、数量、位号”四列。",
        "example": "BOM 有料但 SMT 没有对应记录：确认知悉该问题，不能通过“纳入”凭空生成 SMT 行。排除物料若确认不纳入，原始记录仍保留在核对结果中。 文件命名示例：输入 CY028，输出 CY028-BOM.xlsx。",
        "table": {
          "heads": [
            "选择",
            "适用情况",
            "输出影响"
          ],
          "rows": [
            [
              "确认纳入合并",
              "已核实应保留的 SMT 记录",
              "纳入四列表格，保留原文"
            ],
            [
              "确认不纳入合并",
              "经工艺确认不应纳入的记录",
              "本次合并文件不包含该记录"
            ],
            [
              "撤销确认",
              "需要重新判断",
              "旧预览立即失效，需重新生成"
            ]
          ]
        }
      },
      {
        "id": "cad",
        "title": "FAI-i450 CAD 坐标生成",
        "steps": [
          "先完成核对、人工确认和 BOM 预览，再打开“CAD 坐标”。",
          "导入原坐标 XLSX、UTF-8 CSV 或 TXT，明确选择 mm、mil 或 inch。",
          "位号通过 RefDes 关联，不以 Excel 行号配对。重复、缺失或无效坐标会阻止导出。",
          "生成预览后查看坐标问题、原始记录和转换前后数值。",
          "输入名称并导出十列 Excel：PartType、RefDes、PartDecal、Pins、Layer、Orient.、X、Y、SMD、Glued。"
        ],
        "note": "沿用已验证规则：Top 位置保持；Bottom 的 Y 按完整原坐标的最小/最大 Y 预镜像，角度加 180°。设备导入时不要二次镜像，实际定位仍需按工艺复核。",
        "red": true,
        "intro": "CAD 生成将已确认的物料位号与原坐标关联，输出设备使用的十列文件。应先核实单位及 Top/Bottom 转换约定。",
        "before": [
          "完成本地核对、人工确认和 BOM 预览。",
          "准备包含 RefDes、X、Y、角度和层别的原始坐标 .xlsx / UTF-8 CSV / TXT。",
          "确认原坐标单位是 mm、mil 还是 inch；不要凭显示的小数位判断。"
        ],
        "expected": "预览无阻止导出的问题；元件数量、位号、Top/Bottom 和坐标符合预期，再导出。缺坐标、重复位号或无效数字需要先解决。",
        "example": "RefDes=R101 的坐标只关联 R101，不关联“第 10 行”。输出字段依次为 PartType、RefDes、PartDecal、Pins、Layer、Orient.、X、Y、SMD、Glued。",
        "table": {
          "heads": [
            "参数",
            "如何处理"
          ],
          "rows": [
            [
              "mm / mil / inch",
              "按原文件实际单位明确选择"
            ],
            [
              "Top",
              "使用现有已验证的 Top 规则"
            ],
            [
              "Bottom",
              "按全表 Y 范围镜像并转换角度，不在设备端重复转换"
            ],
            [
              "异常记录",
              "检查来源与原因，未解决的阻止项不能导出"
            ]
          ]
        }
      },
      {
        "id": "compare",
        "title": "坐标差异检测",
        "steps": [
          "导入文件 A 与 B，先确认单位、原点、坐标方向和 Top/Bottom 镜像规则。",
          "确认两文件的坐标系可以直接比较后再检查数值差异。",
          "按 RefDes、板号和层别识别对应元件。无法唯一匹配时提示歧义，不任意覆盖重复位号。",
          "默认 X/Y 容差 ±0.001 mm，角度 ±0.001°，可在“设置 → 坐标比较设置”修改。",
          "按差异类型、RefDes 或只显示异常筛选；点击行查看原始数值和差值。",
          "特殊特征默认保留，排除或人工确认的决定与原因会记录在报告中。"
        ],
        "note": "排序不同仅提示。107.675 与 107.67500000000001 可视为容差内一致；缺少 TP10_1 仍报告缺失。这些容差仅用于文件比较。",
        "intro": "比较两份坐标文件的元件、数值与属性。先确认两份文件能直接比较，再判断坐标是否异常。",
        "before": [
          "准备待比较 A、B 文件；不预设某一份绝对正确。",
          "确认单位、原点、坐标轴方向和 Top/Bottom 镜像规则。",
          "如坐标规则不同，先由工艺确认，不能直接忽略大量差异。"
        ],
        "expected": "顶部显示数量及各类差异统计。搜索 RefDes 或只看异常，点击记录查看原值、差异值和来源。",
        "example": "107.675 与 107.67500000000001 在默认容差内视为一致；107.675 与 107.680 超过 0.001 mm；0° 与 360° 等效；缺少 TP10_1 仍明确报告缺失。",
        "table": {
          "heads": [
            "检测项目",
            "判读方式"
          ],
          "rows": [
            [
              "排序不同",
              "仅提示，不作为元件 NG"
            ],
            [
              "X / Y",
              "默认 ±0.001 mm，可在设置调整"
            ],
            [
              "角度",
              "默认 ±0.001°，按周期比较"
            ],
            [
              "同名位号重复",
              "结合板号和层别；不能唯一匹配时报告问题"
            ],
            [
              "TP / FID / MH / NPTH",
              "单独识别，默认保留；是否排除由工艺和人工确认决定"
            ]
          ]
        }
      },
      {
        "id": "ai",
        "title": "可选 AI 分析",
        "steps": [
          "在“设置 → 外观与 AI 接口”填写兼容接口地址、模型和会话 API Key。",
          "密钥仅在本次会话中保留，不写入普通设置文件或报告。",
          "进入“AI 分析核对”，选择原始文件核对或本地异常解读。",
          "确认发送范围后开始，观察真实阶段、已完成批次和接收文字量。",
          "原文件分析只展示异常。中断或取消后的部分结果不是完整核对结论，可调小批次并继续。"
        ],
        "note": "AI 结论用于复核，不修改确定性 PASS / NG 状态。数据发送到你配置的服务商，使用前确认接口及信息范围。",
        "intro": "AI 用于辅助复核原始内容或解释本地异常，不替代确定性核对，也不会改变 PASS / NG 状态。",
        "before": [
          "在设置 → 外观与 AI 接口填写兼容地址、模型和本次会话 API Key。",
          "云端使用 HTTPS；本地服务按软件允许的 localhost 地址配置。",
          "先测试连接，确认发送范围和服务商符合你的数据使用要求。"
        ],
        "expected": "可看到真实请求阶段、已完成批次和异常列表。完成全部批次才是完整结果；取消或超时保留的内容标为不完整。",
        "example": "遇到 DeepSeek 等接口长时间等待：先检查连接，减小单批字符上限，再使用“重试未完成批次”。不要把“0 批完成”当作“没有异常”。"
      },
      {
        "id": "exports",
        "title": "结果与追溯",
        "steps": [
          "在结果区“导出结果”选择 CSV 或 JSON，Ctrl+E 可直接导出 CSV。",
          "CSV 便于在 Excel 中复查；JSON 保留规则、来源及结构化差异。",
          "合并文件固定四列，CAD 固定十列，均有软件内预览。",
          "位号和坐标原始精度保留，比较时的容差不会对实际导出坐标进行四舍五入。",
          "文件生成后会回读校验；不得覆盖原始输入文件。"
        ],
        "note": "核对报告、合并 Excel 和 CAD Excel 是不同输出，请按用途选择。",
        "intro": "按使用目的选择输出格式。核对报告、合并 BOM 和 CAD 坐标是不同文件，不能互相替代。",
        "before": [
          "检查当前语言、核对状态和人工确认是否正确。",
          "为输出选择新的文件名与保存位置，避免覆盖原始输入。"
        ],
        "expected": "导出后检查保存路径、后缀、列数、元件数量和位号；保留 JSON 以便追溯规则和来源。",
        "table": {
          "heads": [
            "输出",
            "位置与用途"
          ],
          "rows": [
            [
              "CSV 核对报告",
              "工作台 → 导出结果 → CSV，适合表格复查"
            ],
            [
              "JSON 完整报告",
              "工作台 → 导出结果 → JSON，保留结构化差异及规则"
            ],
            [
              "四列合并 Excel",
              "合并与导出，文件名自动以 BOM 结尾"
            ],
            [
              "十列 CAD Excel",
              "CAD 坐标工作区，供设备坐标准备使用"
            ]
          ]
        }
      },
      {
        "id": "updates",
        "title": "软件内更新",
        "steps": [
          "“设置 → 关于与更新 → 检查更新”会匹配当前程序的系统及架构。",
          "点击“下载更新”，可查看大小和真实进度；需要时可取消并重新下载。",
          "通过文件大小和 SHA-256 校验后，先导出要保留的结果，再点击“安装更新”。",
          "Windows 完成安装后重启；Linux/macOS 需完成系统安装授权，并点击重新启动。"
        ],
        "note": "安装前先导出需要保留的结果；本地核对、AI 分析和文件导出进行中时暂不能安装。",
        "intro": "从设置检查并安装正式版本，软件会按当前系统和程序架构匹配安装包。",
        "before": [
          "先导出本次需要保留的结果。",
          "等待本地核对、AI 和文件导出结束，并确保网络可用。"
        ],
        "expected": "下载和校验完成后才能安装；取消或下载失败可以重试。Windows 安装后重启，Linux / macOS 按系统提示授权并重新启动。"
      },
      {
        "id": "shortcuts",
        "title": "快捷键与重新导入",
        "steps": [
          "横向滚动查看宽表；大窗口在右侧展开详情，小窗口以对话框显示。",
          "清空会使迟到的导入、AI 和保存任务失效，不影响保存的语言、主题及规则。",
          "字段缺失或数字无效时，按报错定位到文件、工作表和一基行号进行检查。",
          "坐标大量异常时，先复核单位、原点与镜像规则，不要直接忽略全部差异。"
        ],
        "note": "需要反馈时提供软件版本、错误信息和脱敏样例，请勿在公开问题中提交 API Key 或生产敏感数据。",
        "intro": "常用操作可使用键盘完成。清空重来用于重新导入另一组文件，会清除当前会话中的文件、结果和预览。",
        "before": [
          "清空前先导出需要保留的结果。"
        ],
        "expected": "清空后可重新导入；语言、主题、排除规则和接口地址等保存设置保留，API Key 不写入普通设置文件。",
        "table": {
          "heads": [
            "快捷键",
            "操作"
          ],
          "rows": [
            [
              "Ctrl+O",
              "导入 BOM"
            ],
            [
              "Ctrl+Enter",
              "开始本地核对"
            ],
            [
              "Ctrl+E",
              "导出 CSV 核对报告"
            ],
            [
              "Ctrl+N",
              "清空当前会话，重新导入"
            ]
          ]
        }
      },
      {
        "id": "troubleshooting",
        "after": "shortcuts",
        "title": "常见问题与处理方法",
        "intro": "按具体错误定位原因，避免通过删除元件、扩大容差或忽略结果让文件看起来通过。",
        "steps": [
          "先确认两侧文件属于同一项目、同一版本与同一拼板。",
          "根据错误中的文件、工作表和一基行号回查原始数据。",
          "确需改动源文件时由文件负责人确认，另存副本后重新导入和核对。"
        ],
        "expected": "修复后重新生成核对与预览；旧会话的人工确认不应沿用到变更后的数据。",
        "table": {
          "heads": [
            "现象",
            "先检查",
            "处理方式"
          ],
          "rows": [
            [
              "找不到必需字段",
              "格式、表头和工作表",
              "确认 .xlsx 与四组必需字段"
            ],
            [
              "合并/导出按钮不可用",
              "人工确认及预览",
              "完成所有待确认项，再重新生成预览"
            ],
            [
              "位号重复",
              "板号、层别、重复行",
              "提供唯一标识，不随意覆盖或配对"
            ],
            [
              "大批坐标 NG",
              "单位、原点、镜像和方向",
              "先确认坐标规则，再判断数值差异"
            ],
            [
              "AI 超时或结果不完整",
              "接口、模型与批次大小",
              "测试连接、减小批次、重试未完成批次"
            ],
            [
              "更改规则后预览消失",
              "会话是否已失效",
              "重新核对、确认并生成预览"
            ]
          ]
        }
      }
    ],
    "heroTitle": "从 BOM 到 CAD，\n每一步都有据可查。",
    "heroLead": "核对原始清单，定位字段差异，完成人工复核，再生成可追溯的合并文件与 FAI-i450 坐标。为 SMT 制造现场建立清晰、可靠的工作流程。",
    "nativeLabel": "Windows、Linux、macOS 原生桌面应用",
    "productTitle": "看清差异，再继续下一步。",
    "productText": "料号、数量与位号并排核对。点击任一结果，直接回到原始记录和具体原因。",
    "artAlt": "PCB、坐标标记与光学检测设备的宽幅概念宣传图",
    "artCaption": "从物料清单到坐标准备的工作流概念图",
    "guideLabels": {
      "before": "开始前准备",
      "steps": "操作步骤",
      "expected": "完成后检查",
      "example": "操作示例",
      "important": "注意事项",
      "next": "下一章",
      "search": "搜索功能、按钮或问题",
      "contents": "操作目录",
      "count": "个相关章节",
      "clear": "清除搜索",
      "table": "参考表",
      "figure": "演示数据界面"
    },
    "featureTitles": [
      "位号对照",
      "差异原因",
      "独立分类"
    ]
  },
  "en": {
    "lang": "en",
    "title": "SMT Fusion · BOM verification & CAD generation",
    "nav": [
      "Features",
      "Downloads",
      "User guide",
      "FAQ"
    ],
    "eyebrow": "Native desktop · Windows / Linux / macOS",
    "hero": [
      "Verify every part.",
      "Connect every coordinate."
    ],
    "lead": "From bidirectional T100 BOM and SMT placement checks to human review, merged files and FAI-i450 coordinates. Keep every part and reference designator traceable.",
    "download": "Download desktop app",
    "guide": "Read the user guide",
    "release": "Latest stable release",
    "local": "Local checks. No Excel required.",
    "demo": "Native app interface · synthetic demonstration data",
    "enlarge": "View full interface ↗",
    "workflowTitle": "One clear path from source to output.",
    "workflowLabel": "The workflow",
    "workflow": [
      [
        "Import original files",
        "Read T100 BOM and a single or A+B placement table. Keep file, worksheet and source-row evidence."
      ],
      [
        "Check and review",
        "Compare part numbers, descriptions, quantities and positions. PASS, NG, excluded and candidate pools stay separate."
      ],
      [
        "Confirm, then merge",
        "Review NG, excluded and candidate records before creating the four-column preview and named export."
      ],
      [
        "Generate coordinates",
        "Import source coordinates, confirm units and match by RefDes to generate the ten-column FAI-i450 workbook."
      ]
    ],
    "evidenceLabel": "Differences & evidence",
    "evidenceTitle": "Field differences with source evidence.",
    "evidenceText": "See exactly which field differs and which original record provides the evidence.",
    "evidencePoints": [
      "BOM and SMT positions are shown side by side.",
      "Quantity, description, missing and extra positions have explicit reasons.",
      "Excluded and candidate materials remain visible and never count as PASS."
    ],
    "sampleHeaders": [
      "Part",
      "BOM / SMT RefDes",
      "Result"
    ],
    "sampleNote": "Example: C104 is absent from SMT. The SMT quantity is one lower than BOM.",
    "coordinateLabel": "Reliable coordinate handling",
    "coordinateTitle": "Match by reference. Retain coordinate precision.",
    "coordinateText": "Match by RefDes, board and layer. Distinguish real differences from data quality issues, sorting changes and insignificant precision differences.",
    "coordinateNote": "Default comparison tolerances are ±0.001 mm for X/Y and ±0.001° for rotation, including 0°/360° equivalence. These are file-comparison tolerances, not machine inspection tolerances.",
    "specialText": "Mark TP / FID / MH / NPTH separately. Keep original records by default; configure rules or review manually rather than automatically removing test points.",
    "downloadsTitle": "Choose your desktop version.",
    "downloadsText": "Complete single-file installers. Launch after installation and download future updates inside the app.",
    "winNote": "Windows 10/11 · x64 / ARM64",
    "linuxNote": "Ubuntu 22.04+ / compatible Debian environments",
    "macNote": "macOS 12+ · Intel / Apple Silicon",
    "setup": "Setup",
    "deb": "DEB installer",
    "pkg": "Universal PKG installer",
    "dmg": "Universal DMG image",
    "winSmall": "Application runtimes included. Chinese, English and Thai setup languages.",
    "linuxSmall": "Use the system software installer and install required system dependencies.",
    "macSmall": "PKG supports direct installation and in-app updates; DMG supports drag-and-drop installation.",
    "downloadNote": "Legacy SMT-CHECK filenames are retained for upgrade compatibility.",
    "checksums": "Release notes & SHA-256 checksums",
    "faqTitle": "Before you start.",
    "faq": [
      [
        "Do I need Excel or an AI service?",
        "No. Deterministic checks, merging and coordinate generation run locally. AI is optional."
      ],
      [
        "Are original files modified or uploaded?",
        "Source workbooks are read-only. Local workflows upload nothing. Only content explicitly confirmed for AI is sent to your configured provider."
      ],
      [
        "Does human confirmation turn NG into PASS?",
        "No. It controls inclusion of SMT records in the merge. Check statuses and evidence remain unchanged, and coordinate errors still block CAD export."
      ],
      [
        "Are TP test points automatically deleted?",
        "No. Special features are retained by default. Configurable decisions keep a reason and audit history; a missing TP10_1 is still reported."
      ],
      [
        "How do in-app updates work?",
        "Open Settings → About & updates. Download progress, cancellation, size and SHA-256 checks happen inside the app before launching the system installer."
      ]
    ],
    "footer": "Designed for traceable SMT verification and CAD file preparation.",
    "source": "Source",
    "versions": "Releases",
    "guideTitle": "From your first import to a verified export.",
    "guideIntro": "Follow the workflow in order. Each chapter explains what to prepare, which controls to use, how to read the result and how to resolve common problems.",
    "search": "Search the guide",
    "contents": "Contents",
    "noResults": "No matching section. Try another keyword.",
    "fieldHeaders": [
      "T100 BOM source field",
      "SMT source field"
    ],
    "sections": [
      {
        "id": "start",
        "title": "Quick start",
        "steps": [
          "Install the complete package matching your system and architecture, then launch SMT Fusion.",
          "Choose single-table or A+B mode in the workbench.",
          "Import the T100 BOM, SMT A and, for combined mode, SMT B using the file bar.",
          "Run the check and filter PASS, NG, excluded or candidate materials.",
          "Select a record to inspect original fields and reasons, then open Merge & export."
        ],
        "note": "A single placement table is still compared against the complete BOM. Parts from the other side may be reported missing; this does not prove the entire board passes.",
        "intro": "Begin with a local comparison of one BOM and its matching placement files. AI is optional and is not required for local checks.",
        "before": [
          "Prepare the original T100 BOM .xlsx.",
          "Use SMT A from the same project and revision; include SMT B for two-sided checking."
        ],
        "expected": "The workbench shows separate PASS, NG, excluded and candidate categories. Selecting NG reveals the actual field differences.",
        "example": "Install → import → local check → review → merged preview → export. Continue to CAD coordinates only when you need a coordinate file."
      },
      {
        "id": "install",
        "after": "start",
        "title": "Installation and platform choice",
        "intro": "Download a complete package for your operating system and processor. Install and launch without unpacking a collection of files.",
        "before": [
          "Check x64 or ARM64 in Windows Settings → About.",
          "Choose the Linux architecture for your distribution. The macOS universal package supports Intel and Apple Silicon."
        ],
        "steps": [
          "Windows: run Setup.exe, choose the installation folder and finish the wizard. Launch SMT Fusion from Start.",
          "Linux: open the matching AMD64 or ARM64 .deb in the system installer and install required dependencies.",
          "macOS: use the universal .pkg, or open the .dmg and drag the application to Applications.",
          "The workbench opens in light mode. Select 中文, English or ไทย in the upper-right corner."
        ],
        "expected": "A separate desktop window opens. Local checking does not require Excel, Python or AI configuration.",
        "note": "If macOS blocks first launch, use the normal system approval flow. Check release notes for the package’s signing status."
      },
      {
        "id": "files",
        "title": "Field mapping and import checks",
        "steps": [
          "BOM and SMT checks accept .xlsx. Convert legacy .xls to .xlsx first.",
          "Headers are detected automatically; inspect mappings in Settings → Import & rules.",
          "After importing, verify names and row counts and inspect the source audit in Settings."
        ],
        "note": "Exclusion is separate from PASS and must not hide real placement differences.",
        "fields": true,
        "intro": "BOM and placement tables use different headers. The four mappings below identify the fields. Input files remain read-only; Excel row numbers never identify a component.",
        "before": [
          "Use genuine .xlsx files, not .xls files with a renamed extension.",
          "Check all four headers and keep each material’s positions with its corresponding quantity."
        ],
        "expected": "The file bar shows names and imported row counts; hover to see full paths. Inspect sheets, headers and source audit in Settings → Import & rules.",
        "example": "BOM quantity 2 and positions R101,R102 correspond to SMT quantity 2 and positions R101,R102, regardless of row order."
      },
      {
        "id": "check",
        "after": "files",
        "title": "Running a check and reading results",
        "intro": "Compare part numbers, descriptions, quantities and positions for the same project. Read the category first, then inspect the difference.",
        "before": [
          "Choose single-table or A+B mode and import all required files."
        ],
        "steps": [
          "Import one SMT file for single-table mode, or import A and B separately in combined mode.",
          "Select Start check and wait for results. Total part count is a distinct union, not the number of result rows.",
          "Filter PASS, NG, excluded or candidate materials. Search by part, position or reason.",
          "Select a row or its difference action to compare fields, sheets and source row numbers.",
          "Identify the actual NG cause: quantity surplus/shortage, missing/extra positions, conflicting ownership or description mismatch."
        ],
        "expected": "Every NG has a traceable reason. Excluded and candidate items never count as PASS. A single table against a complete BOM may still report the other side missing.",
        "table": {
          "heads": [
            "Category",
            "Meaning",
            "Next action"
          ],
          "rows": [
            [
              "PASS",
              "Four fields satisfy current rules",
              "Review or continue to merging"
            ],
            [
              "NG",
              "A real difference or data quality problem",
              "Inspect the cause and sources"
            ],
            [
              "Excluded",
              "Description matched an exclusion keyword",
              "Review the keyword and confirm before merging"
            ],
            [
              "Candidate",
              "An alternative record listed separately",
              "Review manually; no automatic substitution"
            ]
          ]
        }
      },
      {
        "id": "rules",
        "after": "check",
        "title": "Non-SMT materials and exclusion rules",
        "intro": "Rules change check categories while keeping source evidence visible. Do not use them to conceal actual placement differences.",
        "before": [
          "Have the process owner identify consumables and non-placement materials."
        ],
        "steps": [
          "Open Settings → Import & rules → Non-SMT exclusion rules.",
          "Enter keywords on separate lines or separated by commas, for example labels, ribbon and solder paste.",
          "Keywords match BOM/SMT descriptions, ignoring whitespace and case; they do not guess material type from a part number.",
          "Apply the rules and rerun the check. Matching parts and corresponding records appear in Excluded.",
          "Inspect matched keywords, provenance and import issues. Review every required item before merging."
        ],
        "expected": "Excluded records stay searchable and exportable, separate from PASS and NG. Changed rules invalidate old checks and previews.",
        "note": "Missing positions do not prove that a material is non-SMT. Unmatched records still need investigation; test-point handling depends on your process."
      },
      {
        "id": "review",
        "title": "Review, merge & export",
        "steps": [
          "Open Merge & export and explicitly include or omit every required NG, excluded and candidate item.",
          "Once all required items are reviewed, choose detailed rows or same-part aggregation and generate the preview.",
          "Aggregate only equal part numbers and descriptions with valid quantities. Position lists are concatenated without automatic deduplication.",
          "Inspect the four columns: part number, description, quantity and positions.",
          "Name the .xlsx output; the filename ends in BOM. Revoking a decision invalidates the previous preview."
        ],
        "note": "Review does not rewrite source files, change classifications or invent missing SMT records.",
        "intro": "Human review decides how a record is used; it never changes NG into PASS. Review every required item before generating or exporting a merged file.",
        "before": [
          "Complete the current local check.",
          "Inspect each difference and make inclusion decisions according to the actual process."
        ],
        "expected": "The pending count reaches zero and preview generation is enabled. The preview contains only part number, description, quantity and positions.",
        "example": "A BOM-only material has no SMT row to include. Acknowledge the issue without inventing placement data. Excluding a reviewed record from a merge still leaves its source evidence in the report. Filename example: enter CY028 to export CY028-BOM.xlsx.",
        "table": {
          "heads": [
            "Decision",
            "When to use it",
            "Effect"
          ],
          "rows": [
            [
              "Include in merge",
              "Verified SMT records that belong in this output",
              "Keep the original row content"
            ],
            [
              "Do not include",
              "Records the process does not require in this output",
              "Omit from this merged file only"
            ],
            [
              "Revoke review",
              "A decision needs reconsideration",
              "Invalidate the old preview immediately"
            ]
          ]
        }
      },
      {
        "id": "cad",
        "title": "FAI-i450 coordinate generation",
        "steps": [
          "Complete checking, human review and the BOM preview before opening CAD coordinates.",
          "Import source XLSX, UTF-8 CSV or TXT and explicitly choose mm, mil or inch.",
          "Match by RefDes, never by Excel row order. Duplicate, missing or invalid coordinates block export.",
          "Generate the preview and inspect issues, original records and transformed values.",
          "Name and export the ten-column workbook: PartType, RefDes, PartDecal, Pins, Layer, Orient., X, Y, SMD, Glued."
        ],
        "note": "The established rule keeps Top positions. Bottom Y is mirrored using the full source minimum/maximum Y and rotation is shifted by 180°. Do not mirror a second time in the machine; verify positioning against your process.",
        "red": true,
        "intro": "CAD generation links reviewed positions to original coordinates and exports the ten-column machine file. Confirm units and Top/Bottom conventions first.",
        "before": [
          "Complete local checking, human review and the BOM preview.",
          "Prepare source .xlsx, UTF-8 CSV or TXT with RefDes, X, Y, rotation and layer.",
          "Identify the real units: mm, mil or inch. Decimal formatting does not identify the unit."
        ],
        "expected": "Resolve blocking issues and inspect component count, RefDes, layers and coordinates before export. Missing, duplicate or invalid coordinates must be corrected.",
        "example": "Coordinates for R101 belong to R101, not to row 10. Output order: PartType, RefDes, PartDecal, Pins, Layer, Orient., X, Y, SMD, Glued.",
        "table": {
          "heads": [
            "Setting",
            "Action"
          ],
          "rows": [
            [
              "mm / mil / inch",
              "Choose the actual source unit"
            ],
            [
              "Top",
              "Use the existing validated Top rule"
            ],
            [
              "Bottom",
              "Mirror using the full-source Y range and transform rotation; avoid a second machine-side transformation"
            ],
            [
              "Blocking issues",
              "Resolve the source problem before export"
            ]
          ]
        }
      },
      {
        "id": "compare",
        "title": "Coordinate difference detection",
        "steps": [
          "Import A and B. First confirm units, origins, axis directions and Top/Bottom mirror conventions.",
          "Confirm that coordinate frames can be compared before judging numeric differences.",
          "Match using RefDes, board and layer. Ambiguous duplicates are reported rather than overwritten.",
          "Defaults are ±0.001 mm and ±0.001°. Change them in Settings → Coordinate comparison settings.",
          "Filter by difference type, RefDes or anomalies only, and select a row to inspect raw values and deltas.",
          "Special features are kept by default. Exclusion and review decisions retain reasons and history."
        ],
        "note": "Order changes are informational. 107.675 and 107.67500000000001 can agree within tolerance; missing TP10_1 remains missing. Tolerances apply to file comparisons only.",
        "intro": "Compare component identity, numeric values and attributes. Confirm that the coordinate frames are comparable before judging position differences.",
        "before": [
          "Prepare A and B without assuming either file is absolutely correct.",
          "Confirm units, origins, axis directions and Top/Bottom mirroring.",
          "If conventions differ, have the process owner confirm them first."
        ],
        "expected": "Read the top-level counts, filter anomalies or search RefDes, then select a row to inspect original values, deltas and provenance.",
        "example": "107.675 and 107.67500000000001 agree within the default tolerance. 107.675 and 107.680 exceed 0.001 mm. 0° equals 360°. Missing TP10_1 is still reported.",
        "table": {
          "heads": [
            "Check",
            "Interpretation"
          ],
          "rows": [
            [
              "Different order",
              "Informational, not a component NG"
            ],
            [
              "X / Y",
              "Default ±0.001 mm; configurable"
            ],
            [
              "Rotation",
              "Default ±0.001° with periodic comparison"
            ],
            [
              "Repeated RefDes",
              "Use board and layer; report ambiguous identities"
            ],
            [
              "TP / FID / MH / NPTH",
              "Classify separately and retain by default; let the process determine exclusion"
            ]
          ]
        }
      },
      {
        "id": "ai",
        "title": "Optional AI analysis",
        "steps": [
          "Configure a compatible endpoint, model and session API key in Settings → Appearance & AI.",
          "Keys remain in session memory and are not saved in ordinary settings or reports.",
          "Open AI analysis and choose original-file checks or local anomaly explanations.",
          "Confirm the content scope before sending. Follow real stages and completed batches.",
          "Original-file analysis lists anomalies only. Cancelled or interrupted results are incomplete; reduce batch size and resume if needed."
        ],
        "note": "AI helps human review and never changes local PASS / NG results. Confirm your chosen provider and content scope.",
        "intro": "AI reviews source text or explains local anomalies. It never replaces deterministic checking or changes PASS / NG states.",
        "before": [
          "Configure endpoint, model and session API key in Settings → Appearance & AI.",
          "Use HTTPS for cloud endpoints or an allowed localhost service.",
          "Test the connection and confirm the provider and content scope."
        ],
        "expected": "Follow real stages, completed batches and the anomaly list. Cancelled, timed-out or partially completed results remain incomplete.",
        "example": "If a provider such as DeepSeek waits too long, check connectivity, reduce the batch character limit and retry unfinished batches. Zero completed batches does not mean zero anomalies."
      },
      {
        "id": "exports",
        "title": "Outputs & traceability",
        "steps": [
          "Choose CSV or JSON from Export results. Ctrl+E exports CSV directly.",
          "CSV supports spreadsheet review; JSON keeps structured evidence, rules and source references.",
          "Merged workbooks have four columns; CAD workbooks have ten, with in-app previews for both.",
          "Raw coordinate precision is retained. Comparison tolerance does not round exported coordinates.",
          "Generated files are read back for verification and cannot overwrite source inputs."
        ],
        "note": "Check reports, merged workbooks and CAD workbooks serve different purposes. Select the appropriate output.",
        "intro": "Choose the output that fits the job. A check report, merged BOM and coordinate workbook serve different purposes.",
        "before": [
          "Check the report language, statuses and review decisions.",
          "Choose a new filename and destination without overwriting the inputs."
        ],
        "expected": "Check output path, extension, columns, quantities and positions. Retain JSON when you need structured rules and provenance.",
        "table": {
          "heads": [
            "Output",
            "Where and why"
          ],
          "rows": [
            [
              "CSV report",
              "Workbench → Export results → CSV; spreadsheet review"
            ],
            [
              "JSON report",
              "Workbench → Export results → JSON; structured evidence and rules"
            ],
            [
              "Four-column workbook",
              "Merge & export; filename ends in BOM"
            ],
            [
              "Ten-column CAD workbook",
              "CAD workspace; machine coordinate preparation"
            ]
          ]
        }
      },
      {
        "id": "updates",
        "title": "Updating inside the app",
        "steps": [
          "Settings → About & updates matches the installed app platform and architecture.",
          "Download the update with real size/progress indicators; cancel and retry when needed.",
          "After size and SHA-256 verification, export any results you want to keep, then install.",
          "Windows restarts after setup. Linux/macOS require system authorization and an explicit restart."
        ],
        "note": "Export results you need before installing. Installation is unavailable while local checking, AI analysis or export is running.",
        "intro": "Check and install stable releases from Settings. The app selects a package matching the current operating system and application architecture.",
        "before": [
          "Export results that you need to keep.",
          "Wait until local checks, AI and exports finish; ensure connectivity."
        ],
        "expected": "Install only after download and verification succeed. Retry cancelled or failed downloads. Windows restarts after setup; Linux/macOS use system authorization and an explicit restart."
      },
      {
        "id": "shortcuts",
        "title": "Shortcuts and starting a new session",
        "steps": [
          "Scroll wide tables horizontally. Details open in a side panel on large windows or a dialog on smaller windows.",
          "Clearing invalidates late imports, AI and save operations while retaining saved language, theme and rules.",
          "For missing fields or invalid numbers, use the reported file, worksheet and one-based row to inspect the source.",
          "If many coordinates differ, verify units, origins and mirroring before ignoring any result."
        ],
        "note": "When reporting a problem, include version, error and a sanitized example. Never publish API keys or sensitive production data.",
        "intro": "Use keyboard shortcuts for frequent actions. Clear & restart removes current files, results and previews so you can import another set.",
        "before": [
          "Export any results you need before clearing."
        ],
        "expected": "Import a new set after clearing. Saved language, theme, rules and endpoint settings remain; API keys are not written to ordinary settings.",
        "table": {
          "heads": [
            "Shortcut",
            "Action"
          ],
          "rows": [
            [
              "Ctrl+O",
              "Import BOM"
            ],
            [
              "Ctrl+Enter",
              "Start local check"
            ],
            [
              "Ctrl+E",
              "Export CSV report"
            ],
            [
              "Ctrl+N",
              "Clear the current session"
            ]
          ]
        }
      },
      {
        "id": "troubleshooting",
        "after": "shortcuts",
        "title": "Troubleshooting by symptom",
        "intro": "Find the cause rather than deleting components, widening tolerances or hiding results just to obtain a pass.",
        "steps": [
          "Confirm project, revision and panel identity on both sides.",
          "Use the reported file, sheet and one-based row to inspect source data.",
          "Have the data owner approve source corrections, save a copy and import again."
        ],
        "expected": "Rerun checking and regenerate previews after a correction. Do not reuse review decisions from changed data.",
        "table": {
          "heads": [
            "Symptom",
            "Check first",
            "Action"
          ],
          "rows": [
            [
              "Required field missing",
              "Format, headers and worksheet",
              "Use .xlsx with all four mapped fields"
            ],
            [
              "Merge/export disabled",
              "Review count and preview",
              "Finish every review, then regenerate"
            ],
            [
              "Duplicate RefDes",
              "Board, layer and repeated records",
              "Provide unique identity; do not overwrite or guess"
            ],
            [
              "Many coordinate NGs",
              "Units, origin, mirroring and axes",
              "Confirm conventions before judging deltas"
            ],
            [
              "AI timeout/incomplete",
              "Endpoint, model and batch size",
              "Test connection, reduce batches, retry unfinished work"
            ],
            [
              "Preview disappeared",
              "Rules or inputs changed",
              "Rerun, review and generate a new preview"
            ]
          ]
        }
      }
    ],
    "heroTitle": "From BOM to CAD.\nTrace every part of the process.",
    "heroLead": "Compare source files, inspect field-level differences and complete human review before exporting merged placement data and FAI-i450 coordinates. A clear workflow for the SMT production floor.",
    "nativeLabel": "Native desktop for Windows, Linux and macOS",
    "productTitle": "See the difference before moving on.",
    "productText": "Compare parts, quantities and positions side by side. Select any result to inspect the source record and the precise reason.",
    "artAlt": "Panoramic concept artwork of a PCB, coordinate markers and optical inspection equipment",
    "artCaption": "Concept visualization of the path from materials to coordinate preparation",
    "guideLabels": {
      "before": "Before you begin",
      "steps": "What to do",
      "expected": "Check the result",
      "example": "Example",
      "important": "Keep in mind",
      "next": "Next chapter",
      "search": "Search features, controls or problems",
      "contents": "In this guide",
      "count": "matching chapters",
      "clear": "Clear search",
      "table": "Reference",
      "figure": "Interface with demonstration data"
    },
    "featureTitles": [
      "Position comparison",
      "Explicit differences",
      "Separate categories"
    ]
  },
  "th": {
    "lang": "th",
    "title": "SMT Fusion · ตรวจสอบ BOM และสร้างพิกัด CAD",
    "nav": [
      "คุณสมบัติ",
      "ดาวน์โหลด",
      "คู่มือ",
      "คำถามที่พบบ่อย"
    ],
    "eyebrow": "แอปเดสก์ท็อป · Windows / Linux / macOS",
    "hero": [
      "ตรวจสอบทุกชิ้นส่วน",
      "เชื่อมโยงทุกพิกัด"
    ],
    "lead": "ตรวจสอบ T100 BOM และตาราง SMT แบบสองทิศทาง ยืนยันด้วยผู้ใช้ รวมไฟล์ และสร้างพิกัด FAI-i450 พร้อมหลักฐานย้อนกลับของทุกชิ้นส่วนและตำแหน่ง",
    "download": "ดาวน์โหลดแอปเดสก์ท็อป",
    "guide": "อ่านคู่มือการใช้งาน",
    "release": "รุ่นเสถียรล่าสุด",
    "local": "ตรวจสอบภายในเครื่อง ไม่ต้องติดตั้ง Excel",
    "demo": "หน้าจอแอปจริง · ข้อมูลตัวอย่างสังเคราะห์",
    "enlarge": "ดูหน้าจอขนาดเต็ม ↗",
    "workflowTitle": "ขั้นตอนชัดเจนจากต้นฉบับถึงผลลัพธ์",
    "workflowLabel": "ขั้นตอนการทำงาน",
    "workflow": [
      [
        "นำเข้าไฟล์ต้นฉบับ",
        "อ่าน T100 BOM และตาราง SMT แบบเดี่ยวหรือ A+B พร้อมเก็บไฟล์ ชีตและแถวต้นฉบับ"
      ],
      [
        "ตรวจสอบและทบทวน",
        "เทียบรหัสวัสดุ คำอธิบาย จำนวนและตำแหน่ง แยก PASS, NG, วัสดุที่ยกเว้นและวัสดุทางเลือก"
      ],
      [
        "ยืนยันก่อนรวมไฟล์",
        "ยืนยันการรวมรายการ NG วัสดุที่ยกเว้นและวัสดุทางเลือก ก่อนสร้างตัวอย่างสี่คอลัมน์"
      ],
      [
        "สร้างและตรวจสอบพิกัด",
        "นำเข้าพิกัด ระบุหน่วยและจับคู่ด้วย RefDes เพื่อสร้างไฟล์ FAI-i450 สิบคอลัมน์"
      ]
    ],
    "evidenceLabel": "ความแตกต่างและหลักฐาน",
    "evidenceTitle": "ระบุความต่างพร้อมหลักฐานต้นฉบับ",
    "evidenceText": "ดูได้ว่าฟิลด์ใดต่างกัน พร้อมอ้างอิงไปยังข้อมูลต้นฉบับแต่ละรายการ",
    "evidencePoints": [
      "แสดงตำแหน่ง BOM และ SMT เคียงข้างกัน",
      "อธิบายความต่างของจำนวน คำอธิบาย ตำแหน่งที่ขาดหรือเกิน",
      "วัสดุที่ยกเว้นและวัสดุทางเลือกยังมองเห็นได้และไม่รวมเป็น PASS"
    ],
    "sampleHeaders": [
      "รหัสวัสดุ",
      "RefDes BOM / SMT",
      "ผล"
    ],
    "sampleNote": "ตัวอย่าง: SMT ไม่มี C104 และมีจำนวนน้อยกว่า BOM หนึ่งตัว",
    "coordinateLabel": "จัดการพิกัดอย่างน่าเชื่อถือ",
    "coordinateTitle": "จับคู่ด้วยตำแหน่งและคงความละเอียดพิกัด",
    "coordinateText": "จับคู่ด้วย RefDes หมายเลขบอร์ดและชั้น แยกความต่างจริง ปัญหาคุณภาพข้อมูล และความต่างของลำดับหรือความละเอียดเล็กน้อย",
    "coordinateNote": "ค่าคลาดเคลื่อนสำหรับเปรียบเทียบเริ่มต้นคือ ±0.001 mm และ ±0.001° รวมกรณี 0°/360° เทียบเท่ากัน ค่านี้ไม่ใช่ค่าคลาดเคลื่อนการตรวจของเครื่อง",
    "specialText": "แยก TP / FID / MH / NPTH โดยเก็บข้อมูลเดิมเป็นค่าเริ่มต้น ตั้งกฎหรือยืนยันเองได้ ไม่ลบจุดทดสอบอัตโนมัติ",
    "downloadsTitle": "เลือกรุ่นสำหรับเดสก์ท็อปของคุณ",
    "downloadsText": "ตัวติดตั้งไฟล์เดียวที่ครบถ้วน ติดตั้งแล้วเปิดใช้ได้ อัปเดตครั้งต่อไปภายในแอป",
    "winNote": "Windows 10/11 · x64 / ARM64",
    "linuxNote": "Ubuntu 22.04+ / สภาพแวดล้อม Debian ที่รองรับ",
    "macNote": "macOS 12+ · Intel / Apple Silicon",
    "setup": "ตัวติดตั้ง",
    "deb": "ตัวติดตั้ง DEB",
    "pkg": "ตัวติดตั้ง PKG แบบ Universal",
    "dmg": "ไฟล์ DMG แบบ Universal",
    "winSmall": "รวมรันไทม์ของแอป รองรับตัวติดตั้งภาษาจีน อังกฤษและไทย",
    "linuxSmall": "ใช้ตัวติดตั้งซอฟต์แวร์ของระบบและติดตั้งไลบรารีระบบตามที่แจ้ง",
    "macSmall": "PKG ใช้ติดตั้งและอัปเดตภายในแอป ส่วน DMG ใช้ลากแอปเพื่อติดตั้ง",
    "downloadNote": "คงชื่อไฟล์ SMT-CHECK เดิมไว้เพื่อรองรับการอัปเกรด",
    "checksums": "รายละเอียดรุ่นและค่า SHA-256",
    "faqTitle": "สิ่งที่ควรรู้ก่อนเริ่ม",
    "faq": [
      [
        "ต้องติดตั้ง Excel หรือใช้บริการ AI หรือไม่",
        "ไม่ต้อง การตรวจสอบหลัก การรวมและสร้างพิกัดทำงานภายในเครื่อง ส่วน AI เป็นตัวเลือก"
      ],
      [
        "แอปแก้ไขหรืออัปโหลดต้นฉบับหรือไม่",
        "อ่านต้นฉบับเท่านั้นและไม่อัปโหลดในขั้นตอนภายในเครื่อง เฉพาะเนื้อหาที่ผู้ใช้ยืนยันสำหรับ AI จะส่งไปยังบริการที่กำหนดเอง"
      ],
      [
        "การยืนยันด้วยผู้ใช้เปลี่ยน NG เป็น PASS หรือไม่",
        "ไม่เปลี่ยน การยืนยันกำหนดเพียงว่าจะรวมรายการ SMT หรือไม่ สถานะและหลักฐานยังคงอยู่ และข้อผิดพลาดพิกัดยังบล็อกการส่งออก CAD"
      ],
      [
        "จุดทดสอบ TP ถูกลบอัตโนมัติหรือไม่",
        "ไม่ถูกลบ เก็บคุณลักษณะพิเศษเป็นค่าเริ่มต้น การยกเว้นต้องมีเหตุผลและประวัติ หากไม่มี TP10_1 ยังรายงานว่าขาด"
      ],
      [
        "อัปเดตภายในแอปอย่างไร",
        "เปิดตั้งค่า → เกี่ยวกับและอัปเดต ดาวน์โหลด ดูความคืบหน้า ยกเลิก และตรวจขนาดกับ SHA-256 ในแอป ก่อนเริ่มตัวติดตั้งระบบ"
      ]
    ],
    "footer": "ออกแบบเพื่อการตรวจสอบ SMT และเตรียมไฟล์ CAD ที่ตรวจสอบย้อนกลับได้",
    "source": "ซอร์สโค้ด",
    "versions": "รุ่นที่เผยแพร่",
    "guideTitle": "จากการนำเข้าครั้งแรกจนส่งออกได้อย่างมั่นใจ",
    "guideIntro": "ทำตามลำดับ แต่ละบทบอกสิ่งที่ต้องเตรียม ปุ่มที่ต้องใช้ วิธีอ่านผล และวิธีแก้ปัญหาที่พบบ่อย",
    "search": "ค้นหาในคู่มือ",
    "contents": "สารบัญ",
    "noResults": "ไม่พบหัวข้อที่ตรงกัน โปรดลองคำอื่น",
    "fieldHeaders": [
      "ฟิลด์ต้นฉบับ T100 BOM",
      "ฟิลด์ต้นฉบับ SMT"
    ],
    "sections": [
      {
        "id": "start",
        "title": "เริ่มต้นใช้งาน",
        "steps": [
          "ติดตั้งแพ็กเกจให้ตรงกับระบบและสถาปัตยกรรม แล้วเปิด SMT Fusion",
          "เลือกตารางเดี่ยวหรือรวม A+B ในหน้าตรวจสอบ",
          "นำเข้า T100 BOM, SMT A และ SMT B สำหรับโหมดรวมผ่านแถบไฟล์",
          "เริ่มตรวจสอบและกรอง PASS, NG, วัสดุที่ยกเว้นหรือวัสดุทางเลือก",
          "เลือกรายการเพื่อดูฟิลด์ต้นฉบับและเหตุผล แล้วเปิดรวมและส่งออก"
        ],
        "note": "ตารางเดี่ยวยังเทียบกับ BOM ทั้งหมด วัสดุอีกด้านที่ไม่ครอบคลุมอาจเป็น NG จึงไม่ยืนยันว่าทั้งบอร์ดผ่าน",
        "intro": "เริ่มด้วยการตรวจ BOM กับตาราง SMT ภายในเครื่องก่อน AI เป็นตัวเลือก ไม่จำเป็นต่อการตรวจหลัก",
        "before": [
          "เตรียม T100 BOM ต้นฉบับ .xlsx",
          "ใช้ SMT A โครงการและรุ่นเดียวกัน หากตรวจสองด้านให้เตรียม SMT B ด้วย"
        ],
        "expected": "เห็นกลุ่ม PASS, NG, วัสดุที่ยกเว้นและวัสดุทางเลือกแยกกัน เลือก NG เพื่อดูฟิลด์ที่ต่าง",
        "example": "ติดตั้ง → นำเข้า → ตรวจภายในเครื่อง → ทบทวน → ตัวอย่างไฟล์รวม → ส่งออก จากนั้นเปิดพิกัด CAD เมื่อจำเป็น"
      },
      {
        "id": "install",
        "after": "start",
        "title": "ติดตั้งและเลือกระบบ",
        "intro": "ดาวน์โหลดแพ็กเกจให้ตรงกับระบบและตัวประมวลผล ติดตั้งแล้วเปิดได้ ไม่ต้องแตกไฟล์หลายรายการ",
        "before": [
          "ดู x64 หรือ ARM64 ในตั้งค่า Windows → เกี่ยวกับ",
          "เลือกสถาปัตยกรรม Linux ให้ถูก macOS แบบ Universal ใช้ได้ทั้ง Intel และ Apple Silicon"
        ],
        "steps": [
          "Windows เปิด Setup.exe เลือกที่ติดตั้ง ทำตามขั้นตอนแล้วเปิด SMT Fusion จาก Start",
          "Linux เปิด .deb แบบ AMD64 หรือ ARM64 ด้วยโปรแกรมติดตั้งระบบ และติดตั้งสิ่งที่จำเป็น",
          "macOS ใช้ .pkg แบบ Universal หรือเปิด .dmg แล้วลากแอปไป Applications",
          "หน้าตรวจเริ่มด้วยโหมดสว่าง เปลี่ยน 中文, English หรือ ไทย ได้ด้านขวาบน"
        ],
        "expected": "แอปเปิดเป็นหน้าต่างเดสก์ท็อป ไม่ต้องติดตั้ง Excel, Python หรือตั้งค่า AI สำหรับตรวจภายในเครื่อง",
        "note": "หาก macOS บล็อกการเปิดครั้งแรก ให้ใช้ขั้นตอนอนุญาตของระบบตามปกติ ดูสถานะการลงนามจากบันทึกรุ่น"
      },
      {
        "id": "files",
        "title": "จับคู่ฟิลด์และตรวจการนำเข้า",
        "steps": [
          "การตรวจ BOM และ SMT รองรับ .xlsx หากเป็น .xls ให้บันทึกใหม่เป็น .xlsx",
          "ระบบค้นหาหัวตารางอัตโนมัติ ดูการจับคู่ได้ในตั้งค่า → การนำเข้าและกฎ",
          "หลังนำเข้า ตรวจชื่อ จำนวนแถวและแหล่งข้อมูลในตั้งค่า"
        ],
        "note": "การยกเว้นแยกจาก PASS และต้องไม่ใช้ปิดบังความต่างจริง",
        "fields": true,
        "intro": "BOM และ SMT ใช้หัวตารางต่างกัน ระบบอ่านตามสี่คู่ด้านล่าง ต้นฉบับเป็นแบบอ่านอย่างเดียว และไม่ใช้หมายเลขแถวจับคู่ชิ้นส่วน",
        "before": [
          "ใช้ .xlsx จริง ไม่ใช่เปลี่ยนนามสกุลจาก .xls",
          "ตรวจหัวตารางครบสี่ฟิลด์และให้จำนวนกับตำแหน่งอยู่ในรายการวัสดุที่ตรงกัน"
        ],
        "expected": "แถบไฟล์แสดงชื่อและจำนวนแถว เลื่อนเมาส์ดูเส้นทางเต็ม ตรวจชีต ฟิลด์และแหล่งข้อมูลในตั้งค่า → การนำเข้าและกฎ",
        "example": "จำนวน BOM 2 ตำแหน่ง R101,R102 ตรงกับ SMT จำนวน 2 ตำแหน่ง R101,R102 แม้ลำดับแถวต่างกัน"
      },
      {
        "id": "check",
        "after": "files",
        "title": "เริ่มตรวจและอ่านผล",
        "intro": "เทียบรหัส คำอธิบาย จำนวนและตำแหน่งของโครงการเดียวกัน อ่านประเภทผลก่อนแล้วดูความต่าง",
        "before": [
          "เลือกตารางเดี่ยวหรือ A+B และนำเข้าไฟล์ให้ครบ"
        ],
        "steps": [
          "โหมดเดี่ยวนำเข้า SMT หนึ่งไฟล์ โหมดรวมให้นำเข้า A และ B แยกกัน",
          "กดเริ่มตรวจและรอผล จำนวนรหัสรวมเป็นยูเนียนที่ไม่ซ้ำ ไม่ใช่จำนวนแถวผลลัพธ์",
          "กรอง PASS, NG, วัสดุที่ยกเว้นหรือทางเลือก ค้นหาด้วยรหัส ตำแหน่งหรือเหตุผล",
          "เลือกแถวหรือดูความต่าง เพื่อเทียบฟิลด์ ชีตและแถวต้นฉบับ",
          "ระบุเหตุ NG จริง เช่น จำนวนเกิน/ขาด ตำแหน่งขาด/เกิน รหัสที่เป็นเจ้าของตำแหน่งขัดกัน หรือคำอธิบายต่าง"
        ],
        "expected": "NG ทุกแถวมีเหตุผลย้อนกลับได้ วัสดุยกเว้นและทางเลือกไม่รวม PASS การเทียบตารางเดี่ยวกับ BOM ทั้งหมดอาจรายงานวัสดุอีกด้านขาด",
        "table": {
          "heads": [
            "ประเภท",
            "ความหมาย",
            "ทำต่ออย่างไร"
          ],
          "rows": [
            [
              "PASS",
              "สี่ฟิลด์ตรงตามกฎปัจจุบัน",
              "ทบทวนหรือรวมไฟล์"
            ],
            [
              "NG",
              "ความต่างจริงหรือปัญหาคุณภาพข้อมูล",
              "อ่านเหตุผลและตรวจต้นฉบับ"
            ],
            [
              "ยกเว้น",
              "คำอธิบายตรงคำยกเว้น",
              "ตรวจคำที่ตรงและยืนยันก่อนรวม"
            ],
            [
              "ทางเลือก",
              "แถววัสดุทดแทนแยกไว้",
              "ยืนยันเอง ไม่แทนวัสดุหลักอัตโนมัติ"
            ]
          ]
        }
      },
      {
        "id": "rules",
        "after": "check",
        "title": "วัสดุไม่ใช่ SMT และกฎยกเว้น",
        "intro": "กฎเปลี่ยนประเภทผลแต่ยังเก็บหลักฐาน ห้ามใช้เพื่อปิดบังความต่างการติดตั้งจริง",
        "before": [
          "ให้ผู้รับผิดชอบกระบวนการระบุวัสดุสิ้นเปลืองและวัสดุที่ไม่ติดตั้ง"
        ],
        "steps": [
          "เปิดตั้งค่า → การนำเข้าและกฎ → กฎยกเว้นวัสดุไม่ใช่ SMT",
          "ใส่คำบรรทัดละคำหรือคั่นด้วยจุลภาค เช่น สติกเกอร์ ริบบอน ครีมบัดกรี",
          "ค้นหาในคำอธิบาย BOM/SMT ไม่สนช่องว่างและตัวพิมพ์ ไม่เดาจากรหัสวัสดุ",
          "ใช้กฎแล้วตรวจใหม่ รหัสที่ตรงและแถวเกี่ยวข้องจะเข้ากลุ่มยกเว้น",
          "เปิดรายการดูคำที่ตรง แหล่งข้อมูลและปัญหานำเข้า ยังคงต้องยืนยันก่อนรวม"
        ],
        "expected": "รายการยกเว้นค้นหา ดูต้นฉบับและส่งออกได้ แยกจาก PASS/NG กฎที่เปลี่ยนทำให้ผลและตัวอย่างเดิมใช้ไม่ได้",
        "note": "ตำแหน่งว่างไม่ได้พิสูจน์ว่าไม่ใช่ SMT รายการไม่ตรงกฎยังต้องตรวจ จุดทดสอบต้องจัดการตามกระบวนการจริง"
      },
      {
        "id": "review",
        "title": "ยืนยัน รวมและส่งออก",
        "steps": [
          "เปิดรวมและส่งออก แล้วยืนยันว่าจะรวมหรือไม่รวม NG วัสดุที่ยกเว้นและวัสดุทางเลือกแต่ละรายการ",
          "ยืนยันครบแล้วเลือกเก็บรายละเอียดหรือสรุปรหัสเดียวกัน แล้วสร้างตัวอย่าง",
          "สรุปเฉพาะรหัสและคำอธิบายตรงกันและจำนวนถูกต้อง ต่อรายการตำแหน่งโดยไม่ลบซ้ำเอง",
          "ตรวจสี่คอลัมน์ ได้แก่รหัสวัสดุ คำอธิบาย จำนวนและตำแหน่ง",
          "ตั้งชื่อและส่งออก .xlsx โดยชื่อไฟล์ลงท้าย BOM การยกเลิกยืนยันทำให้ตัวอย่างเก่าใช้ไม่ได้"
        ],
        "note": "การยืนยันไม่แก้ต้นฉบับ ไม่เปลี่ยนสถานะและไม่สร้างรายการ SMT ที่ขาดขึ้นเอง",
        "intro": "การยืนยันกำหนดว่าจะใช้รายการอย่างไร ไม่เปลี่ยน NG เป็น PASS ต้องยืนยันรายการที่จำเป็นทั้งหมดก่อนสร้างหรือส่งออกไฟล์รวม",
        "before": [
          "ตรวจไฟล์ชุดปัจจุบันให้เสร็จ",
          "อ่านเหตุผลแต่ละรายการ แล้วตัดสินตามกระบวนการจริง"
        ],
        "expected": "รายการค้างยืนยันเป็นศูนย์และสร้างตัวอย่างได้ ตัวอย่างมีเพียงรหัสวัสดุ คำอธิบาย จำนวนและตำแหน่ง",
        "example": "วัสดุที่มีเฉพาะ BOM ไม่มีแถว SMT ให้รวม ต้องรับทราบปัญหาโดยไม่สร้างข้อมูลขึ้นเอง รายการที่ไม่รวมยังมีหลักฐานในผลตรวจ ตัวอย่างชื่อไฟล์: ใส่ CY028 จะส่งออก CY028-BOM.xlsx",
        "table": {
          "heads": [
            "การตัดสินใจ",
            "ใช้เมื่อ",
            "ผลต่อไฟล์"
          ],
          "rows": [
            [
              "ยืนยันให้รวม",
              "แถว SMT ที่ตรวจแล้วว่าต้องใช้",
              "คงเนื้อหาต้นฉบับ"
            ],
            [
              "ยืนยันไม่รวม",
              "กระบวนการไม่ต้องใช้ในไฟล์นี้",
              "ไม่รวมเฉพาะไฟล์รอบนี้"
            ],
            [
              "ยกเลิกการยืนยัน",
              "ต้องทบทวนใหม่",
              "ตัวอย่างเดิมใช้ไม่ได้ทันที"
            ]
          ]
        }
      },
      {
        "id": "cad",
        "title": "สร้างพิกัด FAI-i450",
        "steps": [
          "ตรวจสอบ ยืนยันด้วยผู้ใช้และสร้างตัวอย่าง BOM ให้เสร็จ ก่อนเปิดพิกัด CAD",
          "นำเข้าพิกัด XLSX, UTF-8 CSV หรือ TXT และเลือกหน่วย mm, mil หรือ inch ให้ชัดเจน",
          "จับคู่ด้วย RefDes ไม่ใช้ลำดับแถว Excel หากซ้ำ ขาดหรือพิกัดไม่ถูกต้องจะส่งออกไม่ได้",
          "สร้างตัวอย่างแล้วตรวจปัญหา ข้อมูลต้นฉบับและค่าหลังแปลง",
          "ส่งออกสิบคอลัมน์: PartType, RefDes, PartDecal, Pins, Layer, Orient., X, Y, SMD, Glued"
        ],
        "note": "ใช้กฎเดิมที่ตรวจสอบแล้ว Top คงตำแหน่ง Bottom สะท้อน Y จากค่าต่ำสุด/สูงสุดของต้นฉบับทั้งหมดและบวกมุม 180° อย่าสะท้อนซ้ำบนเครื่อง และต้องทบทวนตำแหน่งตามกระบวนการจริง",
        "red": true,
        "intro": "สร้าง CAD โดยเชื่อมตำแหน่งที่ยืนยันแล้วกับพิกัดต้นฉบับ และส่งออกสิบคอลัมน์ ต้องตรวจหน่วยและกฎ Top/Bottom ก่อน",
        "before": [
          "ตรวจ ยืนยันและสร้างตัวอย่าง BOM ให้เสร็จ",
          "เตรียม .xlsx, UTF-8 CSV หรือ TXT ที่มี RefDes, X, Y, มุมและชั้น",
          "ระบุหน่วยจริง mm, mil หรือ inch อย่าเดาจากจำนวนทศนิยม"
        ],
        "expected": "แก้ปัญหาที่ขวางการส่งออก ตรวจจำนวน ตำแหน่ง ชั้นและพิกัดก่อนส่งออก พิกัดขาด ซ้ำหรือไม่ถูกต้องต้องแก้ก่อน",
        "example": "พิกัด R101 ต้องจับคู่ R101 ไม่ใช่แถว 10 ลำดับส่งออก: PartType, RefDes, PartDecal, Pins, Layer, Orient., X, Y, SMD, Glued",
        "table": {
          "heads": [
            "พารามิเตอร์",
            "วิธีใช้"
          ],
          "rows": [
            [
              "mm / mil / inch",
              "เลือกหน่วยจริงของต้นฉบับ"
            ],
            [
              "Top",
              "ใช้กฎ Top เดิมที่ตรวจสอบแล้ว"
            ],
            [
              "Bottom",
              "สะท้อนจากช่วง Y ทั้งต้นฉบับและแปลงมุม อย่าแปลงซ้ำในเครื่อง"
            ],
            [
              "ปัญหาที่ขวาง",
              "แก้ที่แหล่งข้อมูลก่อนส่งออก"
            ]
          ]
        }
      },
      {
        "id": "compare",
        "title": "ตรวจความต่างของพิกัด",
        "steps": [
          "นำเข้า A และ B แล้วตรวจหน่วย จุดกำเนิด ทิศแกนและกฎสะท้อน Top/Bottom ก่อน",
          "ยืนยันว่ากรอบพิกัดเปรียบเทียบกันได้ก่อนตัดสินค่าตัวเลข",
          "จับคู่ด้วย RefDes หมายเลขบอร์ดและชั้น หากกำกวมหรือซ้ำจะรายงาน ไม่เขียนทับ",
          "ค่าเริ่มต้น ±0.001 mm และ ±0.001° เปลี่ยนได้ในตั้งค่าการเปรียบเทียบพิกัด",
          "กรองประเภทความต่าง RefDes หรือเฉพาะผิดปกติ แล้วเลือกแถวเพื่อดูค่าต้นฉบับและผลต่าง",
          "เก็บคุณลักษณะพิเศษเป็นค่าเริ่มต้น การยกเว้นและยืนยันจะเก็บเหตุผลกับประวัติ"
        ],
        "note": "ลำดับต่างกันเป็นข้อมูลประกอบ 107.675 และ 107.67500000000001 อาจถือว่าตรงกัน แต่ TP10_1 ที่ขาดยังรายงาน ค่าคลาดเคลื่อนใช้เทียบไฟล์เท่านั้น",
        "intro": "เทียบชิ้นส่วน ตัวเลขและคุณสมบัติ ต้องยืนยันว่ากรอบพิกัดเทียบกันได้ก่อนตัดสินความต่าง",
        "before": [
          "เตรียม A และ B โดยไม่ถือว่าไฟล์ใดถูกเสมอ",
          "ตรวจหน่วย จุดกำเนิด ทิศแกนและกฎสะท้อน Top/Bottom",
          "หากกฎต่างกันให้ผู้รับผิดชอบกระบวนการยืนยันก่อน"
        ],
        "expected": "อ่านสถิติด้านบน กรองผิดปกติหรือค้นหา RefDes แล้วเลือกแถวเพื่อดูค่าต้นฉบับ ผลต่างและแหล่งที่มา",
        "example": "107.675 กับ 107.67500000000001 ตรงกันในค่าคลาดเคลื่อนเริ่มต้น แต่ 107.675 กับ 107.680 ต่างเกิน 0.001 mm; 0° เท่ากับ 360°; TP10_1 ที่ขาดยังต้องรายงาน",
        "table": {
          "heads": [
            "รายการตรวจ",
            "วิธีอ่าน"
          ],
          "rows": [
            [
              "ลำดับต่างกัน",
              "แจ้งข้อมูล ไม่ถือเป็น NG ของชิ้นส่วน"
            ],
            [
              "X / Y",
              "เริ่มต้น ±0.001 mm เปลี่ยนได้ในตั้งค่า"
            ],
            [
              "มุม",
              "เริ่มต้น ±0.001° เทียบตามรอบมุม"
            ],
            [
              "RefDes ซ้ำ",
              "ใช้หมายเลขบอร์ดและชั้น รายงานเมื่อกำกวม"
            ],
            [
              "TP / FID / MH / NPTH",
              "แยกประเภทและเก็บไว้เป็นค่าเริ่มต้น ให้กระบวนการกำหนดการยกเว้น"
            ]
          ]
        }
      },
      {
        "id": "ai",
        "title": "การวิเคราะห์ AI แบบเลือกใช้",
        "steps": [
          "ตั้งค่าอินเทอร์เฟซที่เข้ากันได้ โมเดลและ API Key ในตั้งค่า → รูปแบบและการเชื่อมต่อ AI",
          "เก็บ Key ในหน่วยความจำของเซสชัน ไม่บันทึกในการตั้งค่าทั่วไปหรือรายงาน",
          "เปิดวิเคราะห์ AI แล้วเลือกไฟล์ต้นฉบับหรืออธิบายความผิดปกติภายในเครื่อง",
          "ยืนยันขอบเขตก่อนส่ง ดูขั้นตอนจริงและจำนวนชุดที่เสร็จ",
          "การวิเคราะห์ต้นฉบับแสดงเฉพาะผิดปกติ หากยกเลิกหรือสะดุด ผลยังไม่ครบ ลดขนาดชุดและดำเนินต่อได้"
        ],
        "note": "AI ช่วยทบทวนและไม่เปลี่ยน PASS / NG หลัก โปรดยืนยันผู้ให้บริการและขอบเขตข้อมูล",
        "intro": "AI ช่วยทบทวนต้นฉบับหรืออธิบายผิดปกติ ไม่แทนการตรวจหลักและไม่เปลี่ยน PASS / NG",
        "before": [
          "ตั้งค่าอินเทอร์เฟซ โมเดลและ API Key ในตั้งค่า → รูปแบบและการเชื่อมต่อ AI",
          "ใช้ HTTPS สำหรับบริการคลาวด์ หรือ localhost ที่แอปรองรับ",
          "ทดสอบการเชื่อมต่อและยืนยันผู้ให้บริการกับขอบเขตข้อมูล"
        ],
        "expected": "ดูขั้นตอนจริง ชุดที่เสร็จและรายการผิดปกติ หากยกเลิก หมดเวลาหรือเสร็จบางส่วน ผลยังไม่ครบ",
        "example": "หาก DeepSeek หรือบริการอื่นรอนาน ให้ตรวจการเชื่อมต่อ ลดจำนวนอักขระต่อชุดแล้วลองชุดที่ยังไม่เสร็จ ศูนย์ชุดที่เสร็จไม่ได้แปลว่าไม่มีข้อผิดปกติ"
      },
      {
        "id": "exports",
        "title": "ผลลัพธ์และการย้อนกลับ",
        "steps": [
          "เลือก CSV หรือ JSON จากส่งออกผลลัพธ์ หรือใช้ Ctrl+E สำหรับ CSV",
          "CSV เหมาะกับตรวจในสเปรดชีต ส่วน JSON เก็บกฎและหลักฐานแบบมีโครงสร้าง",
          "ไฟล์รวมมีสี่คอลัมน์ CAD มีสิบคอลัมน์ และดูตัวอย่างภายในแอปได้",
          "คงความละเอียดพิกัดเดิม ค่าคลาดเคลื่อนสำหรับเทียบไม่ทำให้พิกัดส่งออกถูกปัดเศษ",
          "อ่านไฟล์ที่สร้างกลับมาตรวจสอบและไม่อนุญาตให้ทับไฟล์นำเข้าต้นฉบับ"
        ],
        "note": "รายงานตรวจสอบ ไฟล์รวมและไฟล์ CAD มีวัตถุประสงค์ต่างกัน โปรดเลือกให้เหมาะสม",
        "intro": "เลือกไฟล์ตามวัตถุประสงค์ รายงานตรวจ ไฟล์ BOM รวมและพิกัด CAD ไม่ใช่ไฟล์ชนิดเดียวกัน",
        "before": [
          "ตรวจภาษา สถานะและการยืนยัน",
          "เลือกชื่อกับที่บันทึกใหม่ ไม่ทับต้นฉบับ"
        ],
        "expected": "ตรวจเส้นทาง นามสกุล คอลัมน์ จำนวนและตำแหน่ง เก็บ JSON เมื่อต้องการกฎและหลักฐานแบบมีโครงสร้าง",
        "table": {
          "heads": [
            "ผลลัพธ์",
            "ตำแหน่งและการใช้งาน"
          ],
          "rows": [
            [
              "รายงาน CSV",
              "หน้าตรวจ → ส่งออกผลลัพธ์ → CSV สำหรับเปิดในสเปรดชีต"
            ],
            [
              "รายงาน JSON",
              "หน้าตรวจ → ส่งออกผลลัพธ์ → JSON เก็บกฎและหลักฐาน"
            ],
            [
              "Excel สี่คอลัมน์",
              "รวมและส่งออก ชื่อลงท้าย BOM"
            ],
            [
              "Excel CAD สิบคอลัมน์",
              "พิกัด CAD สำหรับเตรียมข้อมูลเครื่อง"
            ]
          ]
        }
      },
      {
        "id": "updates",
        "title": "อัปเดตภายในแอป",
        "steps": [
          "ตั้งค่า → เกี่ยวกับและอัปเดต จะเลือกแพ็กเกจตามระบบและสถาปัตยกรรมแอป",
          "ดาวน์โหลดพร้อมดูขนาดและความคืบหน้าจริง ยกเลิกและลองใหม่ได้",
          "ผ่านขนาดและ SHA-256 แล้วส่งออกผลที่ต้องการเก็บก่อนติดตั้ง",
          "Windows เริ่มใหม่หลังติดตั้ง Linux/macOS ต้องอนุญาตผ่านระบบและกดเริ่มแอปใหม่"
        ],
        "note": "ส่งออกผลที่ต้องการก่อนติดตั้ง ระหว่างตรวจภายในเครื่อง วิเคราะห์ AI หรือส่งออกจะยังติดตั้งไม่ได้",
        "intro": "ตรวจและติดตั้งรุ่นทางการจากตั้งค่า ระบบเลือกแพ็กเกจให้ตรงกับระบบและสถาปัตยกรรมแอป",
        "before": [
          "ส่งออกผลที่ต้องการเก็บก่อน",
          "รอการตรวจ AI และส่งออกจบ แล้วตรวจการเชื่อมต่อ"
        ],
        "expected": "ติดตั้งได้เมื่อดาวน์โหลดและตรวจสอบผ่าน หากล้มเหลวหรือยกเลิกให้ลองใหม่ Windows เริ่มใหม่หลังติดตั้ง Linux/macOS อนุญาตผ่านระบบและเริ่มแอปใหม่"
      },
      {
        "id": "shortcuts",
        "title": "คีย์ลัดและเริ่มเซสชันใหม่",
        "steps": [
          "เลื่อนตารางแนวนอน ดูรายละเอียดด้านข้างในหน้าต่างใหญ่ หรือกล่องโต้ตอบในหน้าต่างเล็ก",
          "การล้างทำให้ผลนำเข้า AI และบันทึกที่มาช้าใช้ไม่ได้ แต่คงภาษา ธีมและกฎที่บันทึกไว้",
          "หากฟิลด์ขาดหรือตัวเลขไม่ถูกต้อง ตรวจตามไฟล์ ชีตและหมายเลขแถวที่รายงาน",
          "หากพิกัดต่างจำนวนมาก ให้ตรวจหน่วย จุดกำเนิดและการสะท้อนก่อนข้ามผล"
        ],
        "note": "เมื่อแจ้งปัญหา ระบุรุ่น ข้อผิดพลาดและตัวอย่างที่ลบข้อมูลลับแล้ว ห้ามเผยแพร่ API Key หรือข้อมูลการผลิตที่อ่อนไหว",
        "intro": "ใช้คีย์ลัดสำหรับงานที่ทำบ่อย การล้างเซสชันลบไฟล์ ผลและตัวอย่างปัจจุบันเพื่อให้นำเข้าชุดใหม่ได้",
        "before": [
          "ส่งออกผลที่ต้องการก่อนล้าง"
        ],
        "expected": "นำเข้าชุดใหม่ได้ ภาษา ธีม กฎและที่อยู่บริการที่บันทึกไว้ยังอยู่ API Key ไม่ถูกเขียนลงการตั้งค่าทั่วไป",
        "table": {
          "heads": [
            "คีย์ลัด",
            "การทำงาน"
          ],
          "rows": [
            [
              "Ctrl+O",
              "นำเข้า BOM"
            ],
            [
              "Ctrl+Enter",
              "เริ่มตรวจภายในเครื่อง"
            ],
            [
              "Ctrl+E",
              "ส่งออกรายงาน CSV"
            ],
            [
              "Ctrl+N",
              "ล้างเซสชันปัจจุบัน"
            ]
          ]
        }
      },
      {
        "id": "troubleshooting",
        "after": "shortcuts",
        "title": "แก้ปัญหาตามอาการ",
        "intro": "หาสาเหตุก่อน อย่าลบชิ้นส่วน เพิ่มค่าคลาดเคลื่อนหรือซ่อนผลเพียงเพื่อให้ผ่าน",
        "steps": [
          "ยืนยันโครงการ รุ่นและบอร์ดทั้งสองไฟล์",
          "ตรวจต้นฉบับตามไฟล์ ชีตและแถวที่เริ่มนับจากหนึ่งตามรายงาน",
          "ให้เจ้าของข้อมูลอนุมัติการแก้ แล้วบันทึกสำเนาและนำเข้าใหม่"
        ],
        "expected": "ตรวจและสร้างตัวอย่างใหม่หลังแก้ ไม่ใช้การยืนยันเก่ากับข้อมูลที่เปลี่ยน",
        "table": {
          "heads": [
            "อาการ",
            "ตรวจอะไร",
            "วิธีทำ"
          ],
          "rows": [
            [
              "ฟิลด์จำเป็นขาด",
              "รูปแบบ หัวตารางและชีต",
              "ใช้ .xlsx และฟิลด์ครบสี่คู่"
            ],
            [
              "รวม/ส่งออกไม่ได้",
              "การยืนยันและตัวอย่าง",
              "ยืนยันให้ครบแล้วสร้างใหม่"
            ],
            [
              "RefDes ซ้ำ",
              "บอร์ด ชั้นและแถวซ้ำ",
              "ระบุตัวตนให้ชัด ไม่เดาหรือเขียนทับ"
            ],
            [
              "พิกัด NG มาก",
              "หน่วย จุดกำเนิด การสะท้อนและแกน",
              "ยืนยันกฎก่อนตัดสินผลต่าง"
            ],
            [
              "AI หมดเวลา/ไม่ครบ",
              "บริการ โมเดลและขนาดชุด",
              "ทดสอบ ลดชุดและลองส่วนที่ไม่เสร็จ"
            ],
            [
              "ตัวอย่างหาย",
              "กฎหรือไฟล์เปลี่ยน",
              "ตรวจ ยืนยันและสร้างตัวอย่างใหม่"
            ]
          ]
        }
      }
    ],
    "heroTitle": "จาก BOM สู่ CAD\nตรวจสอบย้อนกลับได้ทุกขั้นตอน",
    "heroLead": "เทียบไฟล์ต้นฉบับ ดูความต่างรายฟิลด์ และยืนยันด้วยผู้ใช้ก่อนส่งออกข้อมูลรวมและพิกัด FAI-i450 ขั้นตอนที่ชัดเจนสำหรับงานผลิต SMT",
    "nativeLabel": "แอปเดสก์ท็อปสำหรับ Windows, Linux และ macOS",
    "productTitle": "เห็นความต่างก่อนทำขั้นตอนต่อไป",
    "productText": "เทียบรหัส จำนวนและตำแหน่งแบบเคียงกัน เลือกผลลัพธ์เพื่อดูข้อมูลต้นฉบับและเหตุผลที่ชัดเจน",
    "artAlt": "ภาพแนวกว้างของ PCB จุดพิกัดและเครื่องตรวจสอบด้วยแสง",
    "artCaption": "ภาพแนวคิดจากรายการวัสดุสู่การเตรียมพิกัด",
    "guideLabels": {
      "before": "ก่อนเริ่ม",
      "steps": "ขั้นตอน",
      "expected": "ตรวจผลลัพธ์",
      "example": "ตัวอย่าง",
      "important": "ข้อควรทราบ",
      "next": "บทถัดไป",
      "search": "ค้นหาฟังก์ชัน ปุ่มหรือปัญหา",
      "contents": "เนื้อหาในคู่มือ",
      "count": "บทที่เกี่ยวข้อง",
      "clear": "ล้างการค้นหา",
      "table": "ตารางอ้างอิง",
      "figure": "หน้าจอพร้อมข้อมูลสาธิต"
    },
    "featureTitles": [
      "เทียบตำแหน่ง",
      "เหตุผลชัดเจน",
      "แยกประเภทผล"
    ]
  }
};
