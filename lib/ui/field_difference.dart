import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/text_difference.dart';
import 'design.dart';
import 'localized_text.dart';

class FieldDifferenceCard extends StatelessWidget {
  final FieldDifference difference;
  const FieldDifferenceCard({super.key, required this.difference});
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context), d = difference;
    final bomLabel = switch (d.field) {
      DifferenceField.quantity => 'BOM 汇总数量',
      DifferenceField.positions => 'BOM 位号集合',
      _ => 'BOM 原值',
    };
    final smtLabel = switch (d.field) {
      DifferenceField.quantity => 'SMT 汇总数量',
      DifferenceField.positions => 'SMT 位号集合',
      _ => 'SMT 原值',
    };
    return Container(
      key: ValueKey('field-difference-${d.field.name}-${d.title}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.panel,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LText(
            d.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.alertText,
            ),
          ),
          const SizedBox(height: 12),
          for (final (label, value, missing, highlights, sources) in [
            (bomLabel, d.bomValue, d.bomMissing, d.bomHighlights, d.bomSources),
            (smtLabel, d.smtValue, d.smtMissing, d.smtHighlights, d.smtSources),
          ]) ...[
            LText(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: p.muted,
              ),
            ),
            const SizedBox(height: 5),
            if (missing || value.trim().isEmpty)
              LText(
                missing ? '无对应记录' : '空值',
                style: TextStyle(
                  fontSize: 13,
                  color: p.alertText,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              DifferenceValue(
                value: value,
                highlights: highlights,
                highlightText: d.highlightText,
              ),
            for (final source in sources)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(
                  source,
                  style: TextStyle(fontSize: 10, color: p.muted, height: 1.5),
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (d.field == DifferenceField.description)
            caption(
              context,
              d.highlightText
                  ? '红色标出描述差异片段；仅忽略大小写和空白。'
                  : '同一料号存在多种描述，请逐行核对下方原始记录。',
            )
          else
            for (final reason in d.reasons)
              LText(
                reason,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: p.alertText,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}

class DifferenceValue extends StatelessWidget {
  final String value;
  final List<TextChangeRange> highlights;
  final bool highlightText;
  const DifferenceValue({
    super.key,
    required this.value,
    required this.highlights,
    required this.highlightText,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context), spans = <TextSpan>[];
    var start = 0;
    for (final range in highlights) {
      if (start < range.start) {
        spans.add(TextSpan(text: value.substring(start, range.start)));
      }
      spans.add(
        TextSpan(
          text: value.substring(range.start, range.end),
          style: TextStyle(
            color: p.alertText,
            fontWeight: FontWeight.w700,
            backgroundColor: p.alertText.withValues(alpha: p.dark ? .08 : .035),
          ),
        ),
      );
      start = range.end;
    }
    if (start < value.length) spans.add(TextSpan(text: value.substring(start)));
    return SelectableText.rich(
      TextSpan(
        children: spans,
        style: TextStyle(
          fontSize: 13,
          height: 1.6,
          color: highlightText ? p.text : p.alertText,
          fontWeight: highlightText ? FontWeight.w400 : FontWeight.w600,
        ),
      ),
    );
  }
}
