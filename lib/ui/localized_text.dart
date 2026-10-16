import 'package:flutter/material.dart';

import '../l10n/localization.dart';

String localText(BuildContext context, String value) =>
    translate(value, Localizations.localeOf(context).languageCode);

class LText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  const LText(this.data, {super.key, this.style, this.maxLines, this.overflow});
  @override
  Widget build(BuildContext context) => Text(
    localText(context, data),
    style: style,
    maxLines: maxLines,
    overflow: overflow,
  );
}
