import 'package:flutter/material.dart';
import 'pos_test_print.dart';
import 'pos_adjustment_values.dart';

Future<PosWidthCandidate?> showWidthPickSheet(BuildContext context) {
  return showModalBottomSheet<PosWidthCandidate>(
    context: context,
    builder: (_) => ListView(
      shrinkWrap: true,
      children: [
        const ListTile(
          title: Text('Selecciona el ancho correcto'),
          subtitle: Text('Elige la opción que NO se corta y llega al borde.'),
        ),
        ...candidates80mm.asMap().entries.map((e) {
          final idx = e.key;
          final c = e.value;
          return ListTile(
            leading: CircleAvatar(child: Text('${idx + 1}')),
            title: Text(c.label),
            subtitle: Text('Sugiere charsAdj=${c.suggestedCharsAdj}'),
            onTap: () => Navigator.pop(context, c),
          );
        }),
      ],
    ),
  );
}

Future<PosPrintWidthAdjCandidate?> showImageWidthPickSheet(BuildContext context) {
  return showModalBottomSheet<PosPrintWidthAdjCandidate>(
    context: context,
    builder: (_) => ListView(
      shrinkWrap: true,
      children: [
        const ListTile(
          title: Text('Selecciona el header que NO se corta'),
          subtitle: Text('Elige la opción donde el borde derecho (línea + esquina) sale completo.'),
        ),
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
      ],
    ),
  );
}


Future<PosCharSet?> showCharsetPickSheet(BuildContext context) {
  return showModalBottomSheet<PosCharSet>(
    context: context,
    builder: (_) => ListView(
      shrinkWrap: true,
      children: const [
        ListTile(
          title: Text('Selecciona el charset correcto'),
          subtitle: Text('Elige el bloque que imprimió bien los acentos.'),
        ),
        _CharsetTile(set: PosCharSet.cp850, title: 'CP850 (recomendado Bematech)'),
        _CharsetTile(set: PosCharSet.cp1252, title: 'CP1252'),
      ],
    ),
  );
}

class _CharsetTile extends StatelessWidget {
  final PosCharSet set;
  final String title;
  const _CharsetTile({required this.set, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      onTap: () => Navigator.pop(context, set),
    );
  }
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
