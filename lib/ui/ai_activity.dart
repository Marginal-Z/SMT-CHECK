import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ai_findings.dart';
import 'design.dart';
import 'localized_text.dart';

class AiActivity extends StatefulWidget {
  final bool busy;
  final AiStage stage;
  final int completed, total, characters;
  final String notice;
  final DateTime? startedAt;
  const AiActivity({
    super.key,
    required this.busy,
    required this.stage,
    required this.completed,
    required this.total,
    required this.characters,
    this.notice = '',
    this.startedAt,
  });
  @override
  State<AiActivity> createState() => _AiActivityState();
}

class _AiActivityState extends State<AiActivity> {
  Timer? timer;
  int seconds = 0;
  @override
  void initState() {
    super.initState();
    if (widget.startedAt != null) {
      seconds = DateTime.now().difference(widget.startedAt!).inSeconds;
    }
    syncTimer();
  }

  @override
  void didUpdateWidget(covariant AiActivity oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startedAt != oldWidget.startedAt) {
      seconds = widget.startedAt == null
          ? 0
          : DateTime.now().difference(widget.startedAt!).inSeconds;
    }
    syncTimer();
  }

  void syncTimer() {
    final active = widget.busy && widget.stage != AiStage.confirming;
    if (!active) {
      timer?.cancel();
      timer = null;
    } else if (timer == null) {
      final previous = seconds;
      timer = Timer.periodic(const Duration(seconds: 1), (tick) {
        if (mounted) {
          setState(
            () => seconds = widget.startedAt == null
                ? previous + tick.tick
                : DateTime.now().difference(widget.startedAt!).inSeconds,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final label = switch (widget.stage) {
      AiStage.preparing => '正在整理原文件',
      AiStage.confirming => '等待确认发送',
      AiStage.connecting => '已发起请求，等待模型响应',
      AiStage.thinking => '模型正在分析原文件',
      AiStage.receiving => '正在接收异常清单',
      AiStage.complete => '核对完成',
      AiStage.failed => '核对中断',
      AiStage.cancelled => '分析已取消',
      AiStage.idle => '等待开始核对',
    };
    final animate =
        widget.busy &&
        widget.stage != AiStage.confirming &&
        !MediaQuery.disableAnimationsOf(context);
    return Container(
      key: const Key('ai-activity'),
      decoration: BoxDecoration(
        color: p.panel,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: animate
                      ? CircularProgressIndicator(
                          key: const Key('ai-busy-animation'),
                          strokeWidth: 2.5,
                          color: p.accent,
                        )
                      : Icon(
                          widget.stage == AiStage.failed
                              ? Icons.error_outline
                              : widget.stage == AiStage.complete
                              ? Icons.check_circle_outline
                              : Icons.hourglass_empty,
                          size: 22,
                          color: p.text,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LText(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          LText(
                            '已完成 ${widget.completed} / ${widget.total} 批',
                            style: TextStyle(color: p.muted, fontSize: 11),
                          ),
                          if (widget.busy)
                            Text(
                              '${localText(context, '已用时')} ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                              key: const Key('ai-elapsed'),
                              style: TextStyle(color: p.muted, fontSize: 11),
                            ),
                          if (widget.characters > 0 && widget.busy)
                            LText(
                              '本批已接收 ${widget.characters} 字符',
                              style: TextStyle(color: p.muted, fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.notice.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: SelectableText(
                widget.notice,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: widget.stage == AiStage.failed ? p.alertText : p.muted,
                ),
              ),
            ),
          if (widget.busy)
            LinearProgressIndicator(
              value: animate
                  ? null
                  : (widget.total > 0 ? widget.completed / widget.total : 0),
              minHeight: 3,
              color: p.accent,
              backgroundColor: p.line,
            ),
        ],
      ),
    );
  }
}
