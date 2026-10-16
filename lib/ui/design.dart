import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const good = Color(0xFF16804A), bad = Color(0xFFC53535);

class Palette {
  final bool dark;
  const Palette(this.dark);
  Color get bg => dark ? const Color(0xFF141414) : const Color(0xFFF5F5F5);
  Color get panel => dark ? const Color(0xFF1C1C1C) : Colors.white;
  Color get text => dark ? const Color(0xFFF4F4F4) : const Color(0xFF191919);
  Color get muted => dark ? const Color(0xFFAAAAAA) : const Color(0xFF6D6D6D);
  Color get line => dark ? const Color(0xFF363636) : const Color(0xFFE1E1E1);
  Color get hover => dark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);
  static Palette of(BuildContext context) =>
      Palette(Theme.of(context).brightness == Brightness.dark);
}

ThemeData desktopTheme(bool dark) {
  final p = Palette(dark);
  return ThemeData(
    useMaterial3: false,
    brightness: dark ? Brightness.dark : Brightness.light,
    primaryColor: p.text,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.panel,
    fontFamily: 'Microsoft YaHei',
    fontFamilyFallback: const ['PingFang SC', 'Noto Sans CJK SC', 'Arial'],
    colorScheme:
        ColorScheme.fromSwatch(
          brightness: dark ? Brightness.dark : Brightness.light,
          primarySwatch: Colors.grey,
        ).copyWith(
          primary: p.text,
          secondary: p.text,
          surface: p.panel,
          error: bad,
        ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.text,
      selectionColor: p.text.withValues(alpha: .16),
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
        borderSide: BorderSide(color: p.text),
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
    final fg = !enabled
        ? p.muted
        : w.primary
        ? p.panel
        : w.color ?? p.text;
    return Semantics(
      button: true,
      enabled: enabled,
      label: w.label,
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
                    ? p.text
                    : (hover || w.selected ? p.hover : p.panel),
                border: Border.all(
                  color: focused
                      ? p.text
                      : w.selected
                      ? p.text
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
                    w.label,
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

Widget caption(BuildContext context, String text) => Text(
  text,
  style: TextStyle(fontSize: 12, color: Palette.of(context).muted, height: 1.6),
);
