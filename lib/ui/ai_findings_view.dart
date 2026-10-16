import 'package:flutter/material.dart';

import '../core/models.dart';
import '../services/ai_findings.dart';
import 'design.dart';
import 'localized_text.dart';

class AiFindingsView extends StatelessWidget {
  final List<AiFinding> findings;
  final bool complete, busy;
  const AiFindingsView({
    super.key,
    required this.findings,
    required this.complete,
    required this.busy,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final language = Localizations.localeOf(context).languageCode;
    if (findings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                complete
                    ? Icons.check_circle_outline
                    : Icons.fact_check_outlined,
                size: 32,
                color: p.muted,
              ),
              const SizedBox(height: 12),
              LText(
                complete
                    ? '本次 AI 核对未发现异常'
                    : busy
                    ? '核对进行中，发现的异常将在这里显示'
                    : '开始核对后，这里只显示异常记录',
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: findings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = findings[index];
        return Container(
          key: ValueKey('ai-finding-$index'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(
              left: BorderSide(
                color: p.result(CheckStatus.error).badge,
                width: 4,
              ),
              top: BorderSide(color: p.line),
              bottom: BorderSide(color: p.line),
              right: BorderSide(color: p.line),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SelectableText(
                    item.part,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                  Text(
                    item.categoryFor(language),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.alertText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SelectableText(
                item.reasonFor(language),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: p.alertText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.bom.isNotEmpty || item.smt.isNotEmpty) ...[
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, c) {
                    Widget evidence(String label, String value) => Container(
                      padding: const EdgeInsets.all(10),
                      color: p.hover,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: p.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SelectableText(
                            value.isEmpty ? '—' : value,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: p.text,
                            ),
                          ),
                        ],
                      ),
                    );
                    return c.maxWidth >= 700
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: evidence('BOM', item.bom)),
                              const SizedBox(width: 10),
                              Expanded(child: evidence('SMT', item.smt)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              evidence('BOM', item.bom),
                              const SizedBox(height: 6),
                              evidence('SMT', item.smt),
                            ],
                          );
                  },
                ),
              ],
              if (item.source.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(
                  item.source,
                  style: TextStyle(fontSize: 11, color: p.muted, height: 1.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
