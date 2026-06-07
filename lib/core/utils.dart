String formatTokenCount(int tokens) {  if (tokens >= 1000000) {
  double value = tokens / 1000000;
  // 1.2M veya tam sayıysa 1M
  return '${value.toStringAsFixed(value == value.toInt() ? 0 : 1)}M';
} else if (tokens >= 1000) {
  double value = tokens / 1000;
  // 100K ve üzeri için küsurat gösterme (120K gibi)
  if (tokens >= 100000) {
    return '${(tokens / 1000).toStringAsFixed(0)}K';
  }
  // 100K altı için küsurat göster (12.5K gibi)
  return '${value.toStringAsFixed(value == value.toInt() ? 0 : 1)}K';
}
return tokens.toString(); // 999 altı olduğu gibi
}