/// Bounded base-10 arithmetic for comparison only. Export keeps original doubles.
/// Decimal literals and unit factors are exact; no rounding at tolerance edges.
class CadDecimal implements Comparable<CadDecimal> {
  final BigInt value;
  final int scale;
  const CadDecimal._(this.value, this.scale);

  static CadDecimal parse(String text) {
    final s = text.trim();
    final m = RegExp(r'^([+-]?)(\d+(?:\.\d*)?|\.\d+)(?:[eE]([+-]?\d{1,3}))?$')
        .firstMatch(s);
    if (m == null || s.length > 256) throw const FormatException('CAD 数值格式无效');
    final exponent = int.parse(m[3] ?? '0');
    if (exponent.abs() > 400) throw const FormatException('CAD 数值超出比较范围');
    final digits = m[2]!, dot = digits.indexOf('.');
    final scale = (dot < 0 ? 0 : digits.length - dot - 1) - exponent;
    final integer = BigInt.parse(
      '${m[1] == '-' ? '-' : ''}${digits.replaceAll('.', '')}',
    );
    return scale < 0
        ? CadDecimal._(integer * BigInt.from(10).pow(-scale), 0)
        : CadDecimal._(integer, scale);
  }

  BigInt _at(int target) => value * BigInt.from(10).pow(target - scale);
  CadDecimal operator -(CadDecimal other) {
    final s = scale > other.scale ? scale : other.scale;
    return CadDecimal._(_at(s) - other._at(s), s);
  }

  CadDecimal operator *(CadDecimal other) =>
      CadDecimal._(value * other.value, scale + other.scale);
  CadDecimal get abs => CadDecimal._(value.abs(), scale);
  CadDecimal mod(CadDecimal other) {
    final s = scale > other.scale ? scale : other.scale;
    return CadDecimal._(_at(s) % other._at(s), s);
  }

  @override
  int compareTo(CadDecimal other) {
    final s = scale > other.scale ? scale : other.scale;
    return _at(s).compareTo(other._at(s));
  }

  @override
  String toString() {
    final sign = value.isNegative ? '-' : '';
    if (scale == 0) return '$value';
    final digits = value.abs().toString().padLeft(scale + 1, '0');
    final s =
        '$sign${digits.substring(0, digits.length - scale)}.${digits.substring(digits.length - scale)}';
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}
