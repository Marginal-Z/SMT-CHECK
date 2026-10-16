import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/positions.dart';
import 'design.dart';
import 'localized_text.dart';

/// Parse each original row separately: T100 hard wraps must never join two rows.
/// Repeated and unrecognized tokens stay visible; raw evidence is never replaced.
class PositionChips extends StatelessWidget {
  final List<MaterialRow> rows;
  final bool bom;
  final CheckStatus status;
  const PositionChips({
    super.key,
    required this.rows,
    required this.bom,
    required this.status,
  });

  static const textStyle = TextStyle(
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    final tokens = <(String, bool)>[];
    for (final row in rows) {
      final parsed = parsePositions(row.positionsText, bom: bom);
      tokens.addAll(parsed.values.map((v) => (v, false)));
      tokens.addAll(parsed.invalidTokens.map((v) => (v, true)));
    }
    final raw = rows.map((r) => r.positionsText).join('\n');
    if (tokens.isEmpty) {
      return Text('—', style: TextStyle(color: Palette.of(context).muted));
    }
    return Tooltip(
      message: raw,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final sample = TextPainter(
            text: TextSpan(
              text: 'M',
              style: DefaultTextStyle.of(context).style.merge(textStyle),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final maxLines = constraints.maxHeight >= 2 * (sample.height + 8) + 4
              ? 2
              : 1;
          sample.dispose();
          double tokenWidth(String label, bool invalid) {
            final painter = TextPainter(
              text: TextSpan(
                text: label,
                style: DefaultTextStyle.of(context).style.merge(textStyle),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final width = painter.width + (invalid ? 39 : 27);
            painter.dispose();
            return width.clamp(0.0, maxWidth);
          }

          // Fit up to two lines, reserving a real button for remaining references.
          var visible = 0, line = 0;
          var x = 0.0;
          final overflowWidth = tokenWidth('+${tokens.length}', false);
          for (var i = 0; i < tokens.length; i++) {
            final (label, invalid) = tokens[i];
            final width = tokenWidth(label, invalid);
            if (x > 0 && x + 4 + width > maxWidth) {
              line++;
              x = 0;
            }
            if (line >= maxLines) {
              break;
            }
            final nextX = x + (x > 0 ? 4 : 0) + width;
            if (line == maxLines - 1 &&
                i < tokens.length - 1 &&
                nextX + 4 + overflowWidth > maxWidth) {
              break;
            }
            x = nextX;
            visible++;
          }
          final hidden = tokens.length - visible;
          return Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final (label, invalid) in tokens.take(visible))
                PositionTag(
                  label: label,
                  invalid: invalid,
                  status: status,
                  maxWidth: maxWidth,
                ),
              if (hidden > 0)
                Tooltip(
                  message: localText(context, '查看全部位号'),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 640,
                            maxHeight: 650,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: LText(
                                        bom ? 'BOM插件位置' : 'SMT站位表位号',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: localText(context, '关闭'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(Icons.close, size: 18),
                                    ),
                                  ],
                                ),
                                caption(
                                  context,
                                  '共 ${tokens.length} 个位号 · 保留重复项',
                                ),
                                const SizedBox(height: 14),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            for (final (label, invalid)
                                                in tokens)
                                              PositionTag(
                                                label: label,
                                                invalid: invalid,
                                                status: status,
                                              ),
                                          ],
                                        ),
                                        const Divider(height: 28),
                                        caption(context, '原始位号文本'),
                                        const SizedBox(height: 6),
                                        SelectableText(
                                          raw,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            height: 1.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: PositionTag(
                      label: '+$hidden',
                      status: status,
                      maxWidth: maxWidth,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class PositionTag extends StatelessWidget {
  final String label;
  final bool invalid;
  final CheckStatus status;
  final double maxWidth;
  const PositionTag({
    super.key,
    required this.label,
    required this.status,
    this.invalid = false,
    this.maxWidth = double.infinity,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context), colors = p.result(status);
    final ink = status == CheckStatus.pass ? colors.ink : p.alertText;
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(colors.badge.withValues(alpha: .05), p.panel),
        border: Border.all(color: colors.edge),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (invalid)
            Icon(Icons.warning_amber_rounded, size: 13, color: ink)
          else
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: colors.edge,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PositionChips.textStyle.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
