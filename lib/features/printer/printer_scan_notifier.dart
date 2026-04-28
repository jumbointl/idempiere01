// The printer-scan notifier (and its companion `PrinterState` class +
// `printerScanNotifierProvider`) now lives in `monalisapy_features`.
// Re-exported here so legacy app_001 imports keep working.
export 'package:monalisapy_features/printer/printer_scan_notifier.dart'
    show PrinterState, PrinterScanNotifier, printerScanNotifierProvider;
