import 'package:flutter/material.dart';

import 'pos_adjustment_values.dart';
import 'pos_test_print.dart';

/// Result for charset pick (includes textMode + escT code table).
class PosCharsetPickResult {
  final PosCharSet charSet;
  final int escTCodeTable;
  final PosTextMode textMode;

  const PosCharsetPickResult({
    required this.charSet,
    required this.escTCodeTable,
    required this.textMode,
  });
}

Future<PosCharsetPickResult?> showCharsetPickSheet(BuildContext context) {
  return showModalBottomSheet<PosCharsetPickResult>(
    context: context,
    builder: (_) => ListView(
      shrinkWrap: true,
      children: const [
        ListTile(
          title: Text('Selecciona el charset correcto'),
          subtitle: Text('Elige el bloque que imprimió bien acentos y € (sin cuadritos).'),
        ),
        Divider(height: 1),

        _CharsetModeTile(
          title: 'CP1252 (ESC t 16) · Seguro',
          subtitle: 'Recomendado si la mayoría de tus impresoras lo soportan.',
          result: PosCharsetPickResult(
            charSet: PosCharSet.cp1252,
            escTCodeTable: 16,
            textMode: PosTextMode.rawLatin1,
          ),
        ),
        _CharsetModeTile(
          title: 'CP858 (ESC t 5) · Seguro',
          subtitle: 'CP850 + € (útil para firmwares tipo Bematech).',
          result: PosCharsetPickResult(
            charSet: PosCharSet.cp858,
            escTCodeTable: 5,
            textMode: PosTextMode.rawLatin1,
          ),
        ),
        _CharsetModeTile(
          title: 'CP850 (ESC t 2) · Seguro',
          subtitle: 'Sin € (lo reemplaza por EUR).',
          result: PosCharsetPickResult(
            charSet: PosCharSet.cp850,
            escTCodeTable: 2,
            textMode: PosTextMode.rawLatin1,
          ),
        ),
        _CharsetModeTile(
          title: 'UTF8 (ESC t 8) · RAW',
          subtitle: 'Unicode real. Útil si todo lo demás da cuadritos.',
          result: PosCharsetPickResult(
            charSet: PosCharSet.utf8,
            escTCodeTable: 8,
            textMode: PosTextMode.rawUtf8,
          ),
        ),
      ],
    ),
  );
}

class _CharsetModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final PosCharsetPickResult result;

  const _CharsetModeTile({
    required this.title,
    required this.subtitle,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, result),
    );
  }
}

Future<PosWidthCandidate?> showWidthPickSheet(BuildContext context) {
  return showModalBottomSheet<PosWidthCandidate>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Selecciona el ajuste de ancho'),
            subtitle: Text(
              'Elige la opción donde el texto NO se corta y llega al borde.',
            ),
          ),
          const Divider(height: 1),

          ...widthCandidates.asMap().entries.map((e) {
            final idx = e.key;
            final c = e.value;

            return ListTile(
              leading: CircleAvatar(
                child: Text('${idx + 1}'),
              ),
              title: Text('Ajuste ${c.label}'),
              subtitle: Text('charsAdj = ${c.colsBaseDelta}'),
              onTap: () => Navigator.pop(context, c),
            );
          }),

          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}



Future<PosPrintWidthAdjCandidate?> showImageWidthPickSheet(BuildContext context) {
  return showModalBottomSheet<PosPrintWidthAdjCandidate>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text('Selecciona el header que NO se corta'),
            subtitle: Text(
              'Elige la opción donde el borde derecho (línea + esquina) sale completo.',
            ),
          ),
          const Divider(height: 1),
          ...imageWidthAdjCandidates.asMap().entries.map((e) {
            final idx = e.key;
            final c = e.value;
            return ListTile(
              leading: CircleAvatar(child: Text('${idx + 1}')),
              title: Text(c.label),
              subtitle: Text('Guardará printWidthAdjustment=${c.printWidthAdjustment}'),
              onTap: () => Navigator.pop(context, c),
            );
          }),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}


Future<int?> showCharsAdjPickSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    builder: (_) => ListView(
      shrinkWrap: true,
      children: [
        const ListTile(
          title: Text('Selecciona el ajuste de columnas'),
          subtitle: Text('Elige la opción que NO se corta y llega al borde.'),
        ),
        ...widthCandidates.asMap().entries.map((e) {
          final idx = e.key;
          final c = e.value;
          return ListTile(
            leading: CircleAvatar(child: Text('${idx + 1}')),
            title: Text(c.label),
            subtitle: Text('charsAdj=${c.colsBaseDelta}'),
            onTap: () => Navigator.pop(context, c.colsBaseDelta),
          );
        }),
      ],
    ),
  );
}





class PosPrintWidthAdjCandidate {
  final int printWidthAdjustment; // 0 / -8 / -16
  final String label;
  const PosPrintWidthAdjCandidate(this.printWidthAdjustment, this.label);
}

const imageWidthAdjCandidates = <PosPrintWidthAdjCandidate>[
  PosPrintWidthAdjCandidate(0, 'Opción 1 (wAdj=0) - baseline'),
  PosPrintWidthAdjCandidate(-8, 'Opción 2 (wAdj=-8) - reduce ancho útil'),
  PosPrintWidthAdjCandidate(-16, 'Opción 3 (wAdj=-16) - reduce más'),
];
