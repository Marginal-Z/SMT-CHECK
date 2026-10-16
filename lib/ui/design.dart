import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'localized_text.dart';
import '../core/models.dart';

const good = Color(0xFF0A713B), bad = Color(0xFFB21E2B);

enum ThemeAccent { black, blue, green }

extension ThemeAccentLabel on ThemeAccent {
  String get label => switch (this) {
    ThemeAccent.black => '黑色',
    ThemeAccent.blue => '蓝色',
    ThemeAccent.green => '绿色',
  };
}

class AccentTheme extends ThemeExtension<AccentTheme> {
  final ThemeAccent accent;
  const AccentTheme(this.accent);
  @override
  AccentTheme copyWith({ThemeAccent? accent}) =>
      AccentTheme(accent ?? this.accent);
  @override
  AccentTheme lerp(covariant AccentTheme? other, double t) =>
      t < .5 ? this : other ?? this;
}

class ResultColors {
  final Color fill, ink, edge, badge, onBadge;
  const ResultColors(this.fill, this.ink, this.edge, this.badge, this.onBadge);
}

class Palette {
  final bool dark;
  final ThemeAccent themeAccent;
  const Palette(this.dark, [this.themeAccent = ThemeAccent.black]);
  Color get accent => switch (themeAccent) {
    ThemeAccent.black => text,
    ThemeAccent.blue =>
      dark ? const Color(0xFF8FBBFF) : const Color(0xFF1559BD),
    ThemeAccent.green =>
      dark ? const Color(0xFF83DBAE) : const Color(0xFF087343),
  };
  Color get onAccent => dark ? const Color(0xFF141414) : Colors.white;
  Color get accentSoft =>
      Color.alphaBlend(accent.withValues(alpha: dark ? .14 : .09), panel);
  Color get bg => dark ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
  Color get panel => dark ? const Color(0xFF1C1C1C) : Colors.white;
  Color get text => dark ? const Color(0xFFF4F4F4) : const Color(0xFF191919);
  Color get muted => dark ? const Color(0xFFAAAAAA) : const Color(0xFF6D6D6D);
  Color get line => dark ? const Color(0xFF363636) : const Color(0xFFE1E1E1);
  Color get hover => dark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);
  ResultColors result(CheckStatus status, {bool selected = false}) =>
      switch (status) {
        CheckStatus.pass => ResultColors(
          dark
              ? (selected ? const Color(0xFF1A603F) : const Color(0xFF12462E))
              : (selected ? const Color(0xFF94D5AF) : const Color(0xFFBCE8CD)),
          dark ? const Color(0xFFB3FFD0) : const Color(0xFF07582B),
          dark ? const Color(0xFF60D493) : good,
          const Color(0xFF086637),
          Colors.white,
        ),
        CheckStatus.error => ResultColors(
          dark
              ? (selected ? const Color(0xFF77313B) : const Color(0xFF5A242B))
              : (selected ? const Color(0xFFF1A9B2) : const Color(0xFFF8CBCF)),
          dark ? const Color(0xFFFFCBD0) : const Color(0xFF86121D),
          dark ? const Color(0xFFFF8493) : bad,
          const Color(0xFFB21E2B),
          Colors.white,
        ),
        _ => ResultColors(
          selected ? accentSoft : hover,
          muted,
          line,
          hover,
          text,
        ),
      };
  static Palette of(BuildContext context) {
    final theme = Theme.of(context);
    return Palette(
      theme.brightness == Brightness.dark,
      theme.extension<AccentTheme>()?.accent ?? ThemeAccent.black,
    );
  }
}

ThemeData desktopTheme(bool dark, [ThemeAccent accent = ThemeAccent.black]) {
  final p = Palette(dark, accent);
  return ThemeData(
    useMaterial3: false,
    brightness: dark ? Brightness.dark : Brightness.light,
    primaryColor: p.accent,
    extensions: [AccentTheme(accent)],
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.panel,
    fontFamily: 'Microsoft YaHei',
    fontFamilyFallback: const [
      'Noto Sans Thai',
      'PingFang SC',
      'Noto Sans CJK SC',
      'Arial',
    ],
    colorScheme:
        ColorScheme.fromSwatch(
          brightness: dark ? Brightness.dark : Brightness.light,
          primarySwatch: Colors.grey,
        ).copyWith(
          primary: p.accent,
          secondary: p.accent,
          onPrimary: p.onAccent,
          onSecondary: p.onAccent,
          surface: p.panel,
          error: bad,
        ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: .20),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 450),
      decoration: BoxDecoration(
        color: dark ? Colors.white : const Color(0xFF242424),
        borderRadius: BorderRadius.circular(3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: p.panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: p.accent),
      ),
    ),
    dividerColor: p.line,
    visualDensity: VisualDensity.compact,
  );
}

class DeskButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary, selected;
  final Color? color;
  const DeskButton(
    this.label, {
    super.key,
    this.icon,
    this.onPressed,
    this.primary = false,
    this.selected = false,
    this.color,
  });
  @override
  State<DeskButton> createState() => _DeskButtonState();
}

class _DeskButtonState extends State<DeskButton> {
  bool hover = false, focused = false;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context), w = widget;
    final enabled = w.onPressed != null;
    final label = localText(context, w.label);
    final fg = !enabled
        ? p.muted
        : w.primary
        ? p.onAccent
        : w.color ?? (w.selected ? p.accent : p.text);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (v) => setState(() => focused = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              w.onPressed?.call();
              return null;
            },
          ),
        },
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: MouseRegion(
          onEnter: (_) => setState(() => hover = true),
          onExit: (_) => setState(() => hover = false),
          child: GestureDetector(
            onTap: w.onPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: w.primary && enabled
                    ? p.accent
                    : (hover || w.selected ? p.accentSoft : p.panel),
                border: Border.all(
                  color: focused
                      ? p.accent
                      : w.selected
                      ? p.accent
                      : p.line,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (w.icon != null) ...[
                    Icon(w.icon, size: 16, color: fg),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: fg,
                      fontWeight: w.primary || w.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Pane extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const Pane({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.panel,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(5),
      ),
      child: child,
    );
  }
}

class FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  const FilterTab(
    this.label, {
    super.key,
    required this.selected,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? p.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: selected ? p.accent : p.muted,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            shape: const RoundedRectangleBorder(),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class ResultBadge extends StatelessWidget {
  final CheckStatus status;
  final String label;
  const ResultBadge({super.key, required this.status, required this.label});
  @override
  Widget build(BuildContext context) {
    final colors = Palette.of(context).result(status);
    final isResult = status == CheckStatus.pass || status == CheckStatus.error;
    return Tooltip(
      message: localText(context, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isResult ? colors.badge : colors.fill,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isResult) ...[
              Icon(
                status == CheckStatus.pass
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                size: 14,
                color: colors.onBadge,
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: LText(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isResult ? colors.onBadge : colors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget caption(BuildContext context, String text) => Text(
  localText(context, text),
  style: TextStyle(fontSize: 12, color: Palette.of(context).muted, height: 1.6),
);
