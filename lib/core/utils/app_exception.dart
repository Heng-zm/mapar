class MappException implements Exception {
  const MappException(this.message);
  final String message;

  @override
  String toString() => message;
}
