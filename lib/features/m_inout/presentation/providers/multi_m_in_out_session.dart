import '../../domain/entities/m_in_out.dart';
import '../../domain/entities/line.dart';

/// One MInOut being processed inside a Multiple Receipt session.
class MultiMInOutSession {
  /// Stable id used by the UI (also used as tab/key identifier).
  final String sessionId;

  /// Position in the session list — drives the rotating color (0..4 rotating).
  final int colorIndex;

  /// Snapshot of the loaded MInOut. Lines inside contain confirmedQty mutations.
  final MInOut mInOut;

  /// Barcodes scanned that hit a line of *this* session, in arrival order.
  final List<String> scannedBarcodes;

  /// 'active' | 'completed'
  final String status;

  const MultiMInOutSession({
    required this.sessionId,
    required this.colorIndex,
    required this.mInOut,
    this.scannedBarcodes = const <String>[],
    this.status = 'active',
  });

  String get documentNo => mInOut.documentNo ?? '';

  bool get isCompleted => status == 'completed';

  /// Lines pending confirmation (confirmedQty < movementQty).
  List<Line> get pendingLines => mInOut.lines
      .where((l) => (l.confirmedQty ?? 0) < (l.movementQty ?? 0))
      .toList(growable: false);

  /// All lines that match a UPC on this session.
  List<Line> linesMatchingUpc(String code) =>
      mInOut.lines.where((l) => l.upc == code).toList(growable: false);

  MultiMInOutSession copyWith({
    String? sessionId,
    int? colorIndex,
    MInOut? mInOut,
    List<String>? scannedBarcodes,
    String? status,
  }) =>
      MultiMInOutSession(
        sessionId: sessionId ?? this.sessionId,
        colorIndex: colorIndex ?? this.colorIndex,
        mInOut: mInOut ?? this.mInOut,
        scannedBarcodes: scannedBarcodes ?? this.scannedBarcodes,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'colorIndex': colorIndex,
        'status': status,
        'scannedBarcodes': scannedBarcodes,
        'mInOut': mInOut.toJson(),
      };

  factory MultiMInOutSession.fromJson(Map<String, dynamic> json) =>
      MultiMInOutSession(
        sessionId: json['sessionId']?.toString() ?? '',
        colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
        status: json['status']?.toString() ?? 'active',
        scannedBarcodes: (json['scannedBarcodes'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const <String>[],
        mInOut: MInOut.fromJson(
          (json['mInOut'] as Map).cast<String, dynamic>(),
        ),
      );
}

/// One scanned barcode with cross-session metadata for the global Scan tab.
class MultiScannedBarcode {
  final String code;
  final String? sessionId;
  final int? sessionColorIndex;
  final DateTime scannedAt;
  final String resolution; // 'matched' | 'unmatched' | 'pending_choice'

  const MultiScannedBarcode({
    required this.code,
    required this.scannedAt,
    this.sessionId,
    this.sessionColorIndex,
    this.resolution = 'matched',
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'sessionId': sessionId,
        'sessionColorIndex': sessionColorIndex,
        'scannedAt': scannedAt.toIso8601String(),
        'resolution': resolution,
      };

  factory MultiScannedBarcode.fromJson(Map<String, dynamic> json) =>
      MultiScannedBarcode(
        code: json['code']?.toString() ?? '',
        sessionId: json['sessionId']?.toString(),
        sessionColorIndex: (json['sessionColorIndex'] as num?)?.toInt(),
        scannedAt: json['scannedAt'] != null
            ? DateTime.tryParse(json['scannedAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        resolution: json['resolution']?.toString() ?? 'matched',
      );
}
