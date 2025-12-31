class PrinterConfig {
  final String ip;
  final int port;

  const PrinterConfig({
    required this.ip,
    required this.port,
  });

  bool get isConfigured => ip.trim().isNotEmpty && port>0;
}
