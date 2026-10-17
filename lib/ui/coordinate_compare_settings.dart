import 'package:flutter/material.dart';

import '../core/coordinate_comparison.dart';
import 'coordinate_comparison_workspace.dart' show specialActionLabel;
import 'design.dart';
import 'localized_text.dart';

class CoordinateCompareSettingsPanel extends StatefulWidget {
  final CoordinateCompareSettings settings;
  final ValueChanged<CoordinateCompareSettings> onApply;
  const CoordinateCompareSettingsPanel({
    super.key,
    required this.settings,
    required this.onApply,
  });
  @override
  State<CoordinateCompareSettingsPanel> createState() =>
      _CoordinateCompareSettingsPanelState();
}

class _CoordinateCompareSettingsPanelState
    extends State<CoordinateCompareSettingsPanel> {
  late final TextEditingController xy, angle;
  late List<SpecialRule> rules;
  String error = '', message = '';
  @override
  void initState() {
    super.initState();
    xy = TextEditingController(text: widget.settings.xyTolerance);
    angle = TextEditingController(text: widget.settings.angleTolerance);
    rules = [...widget.settings.specialRules];
  }

  @override
  void dispose() {
    xy.dispose();
    angle.dispose();
    super.dispose();
  }

  void save() {
    try {
      final s = CoordinateCompareSettings(
        xyTolerance: xy.text.trim(),
        angleTolerance: angle.text.trim(),
        specialRules: List.unmodifiable(rules),
      );
      s.validate();
      widget.onApply(s);
      setState(() {
        error = '';
        message = '坐标比较设置已保存，旧比较结果已失效。';
      });
    } on FormatException catch (e) {
      setState(() {
        error = e.message;
        message = '';
      });
    }
  }

  Future<void> edit([int? index]) async {
    final rule = await showDialog<SpecialRule>(
      context: context,
      builder: (_) => _RuleDialog(rule: index == null ? null : rules[index]),
    );
    if (!mounted || rule == null) return;
    setState(() {
      if (index == null) {
        rules.add(rule);
      } else {
        rules[index] = rule;
      }
      message = '';
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Pane(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LText(
            '坐标比较设置',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 240,
                child: TextField(
                  key: const Key('coordinate-xy-tolerance'),
                  controller: xy,
                  decoration: InputDecoration(
                    labelText: localText(context, 'X/Y 比较容差（mm）'),
                  ),
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  key: const Key('coordinate-angle-tolerance'),
                  controller: angle,
                  decoration: InputDecoration(
                    labelText: localText(context, '角度比较容差（°）'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const LText('容差仅用于文件比较，不代表 FAI450 设备检测公差，不修改原始坐标或导出精度。'),
          const SizedBox(height: 20),
          const LText(
            '特殊 PCB 特征规则',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const LText('按完整字段匹配；同一规则中填写的条件必须全部满足。默认保留所有元件，排除建议需要逐项人工确认。'),
          const SizedBox(height: 10),
          for (var i = 0; i < rules.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Palette.of(context).line),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rules[i].category,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          [
                            if (rules[i].reference.isNotEmpty)
                              'RefDes: ${rules[i].reference}',
                            if (rules[i].partType.isNotEmpty)
                              'PartType: ${rules[i].partType}',
                            if (rules[i].decal.isNotEmpty)
                              'PartDecal: ${rules[i].decal}',
                          ].join('\n'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        LText(specialActionLabel(rules[i].action)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: localText(context, '编辑'),
                    onPressed: () => edit(i),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: localText(context, '删除规则'),
                    onPressed: () => setState(() => rules.removeAt(i)),
                    icon: const Icon(Icons.delete_outline, size: 18),
                  ),
                ],
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DeskButton(
                '增加特殊元件规则',
                key: const Key('coordinate-rule-add'),
                onPressed: () => edit(),
                icon: Icons.add,
              ),
              DeskButton(
                '恢复默认规则',
                onPressed: () =>
                    setState(() => rules = [...defaultSpecialRules]),
              ),
              DeskButton(
                '保存坐标比较设置',
                key: const Key('coordinate-settings-save'),
                primary: true,
                onPressed: save,
              ),
            ],
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: LText(
                error,
                style: TextStyle(color: Palette.of(context).alertText),
              ),
            ),
          if (message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: LText(message),
            ),
        ],
      ),
    ),
  );
}

class _RuleDialog extends StatefulWidget {
  final SpecialRule? rule;
  const _RuleDialog({this.rule});
  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final TextEditingController category, reference, type, decal;
  late SpecialAction action;
  String error = '';
  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    category = TextEditingController(text: r?.category ?? '');
    reference = TextEditingController(text: r?.reference ?? '');
    type = TextEditingController(text: r?.partType ?? '');
    decal = TextEditingController(text: r?.decal ?? '');
    action = r?.action ?? SpecialAction.retain;
  }

  @override
  void dispose() {
    for (final c in [category, reference, type, decal]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const LText('特殊元件规则'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: category,
              decoration: InputDecoration(
                labelText: localText(context, '类别名称'),
              ),
            ),
            TextField(
              controller: reference,
              decoration: const InputDecoration(
                labelText: 'RefDes',
                hintText: 'TP[0-9]+[_0-9A-Z]*',
              ),
            ),
            TextField(
              controller: type,
              decoration: const InputDecoration(labelText: 'PartType'),
            ),
            TextField(
              controller: decal,
              decoration: const InputDecoration(labelText: 'PartDecal'),
            ),
            const SizedBox(height: 10),
            const LText('规则仅支持安全的正则子集：字符、字符组、点、星号、加号、问号及锚点'),
            DropdownButton<SpecialAction>(
              value: action,
              isExpanded: true,
              items: [
                for (final a in SpecialAction.values)
                  DropdownMenuItem(
                    value: a,
                    child: LText(specialActionLabel(a)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => action = v);
              },
            ),
            if (error.isNotEmpty)
              LText(
                error,
                style: TextStyle(color: Palette.of(context).alertText),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const LText('取消'),
      ),
      TextButton(
        onPressed: () {
          try {
            final r = SpecialRule(
              category.text.trim(),
              reference: reference.text.trim(),
              partType: type.text.trim(),
              decal: decal.text.trim(),
              action: action,
            );
            r.validate();
            Navigator.pop(context, r);
          } on FormatException catch (e) {
            setState(() => error = e.message);
          }
        },
        child: const LText('保存'),
      ),
    ],
  );
}
