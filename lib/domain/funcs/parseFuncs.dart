String toStr(dynamic v) => (v ?? '').toString();

int toInt(dynamic v, [int def = 0]) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? def;
}

bool toBool(dynamic v, [bool def = false]) {
  if (v == null) return def;
  if (v is int) return v == 1;
  if (v is num) return v == 1;
  return bool.tryParse(v.toString()) ?? def;
}

DateTime parseDt(dynamic v) {
  final s = toStr(v).trim();
  if (s.isEmpty) return DateTime.now();
  final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
  return DateTime.tryParse(iso) ?? DateTime.now();
}

Map<String, dynamic> stringKeyedMap(Map raw) {
  final out = <String, dynamic>{};
  raw.forEach((k, v) => out[k.toString()] = v);
  return out;
}