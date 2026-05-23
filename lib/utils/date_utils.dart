String toLocalIso(DateTime dt) {
  final local = dt.toLocal();
  final y  = local.year.toString().padLeft(4, '0');
  final mo = local.month.toString().padLeft(2, '0');
  final d  = local.day.toString().padLeft(2, '0');
  final h  = local.hour.toString().padLeft(2, '0');
  final mi = local.minute.toString().padLeft(2, '0');
  final s  = local.second.toString().padLeft(2, '0');
  return '$y-$mo-${d}T$h:$mi:$s';
}