import 'package:flutter/material.dart';
import '../../../../../../../shared/data/memory.dart';
import 'template_zpl_models.dart';

Future<void> showZplPreviewSheet({
  required BuildContext context,
  required ZplTemplate template,
  required String filledPreviewFirstPage,
  required String filledPreviewAllPages,
  required List<String> missingTokens,
  Future<void> Function()? onSendDf,
  Future<void> Function()? onPrintReference,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.90;
      return SizedBox(
        height: height,
        width: double.infinity,
        child: ZplPreviewSheet(
          template: template,
          filledPreviewFirstPage: filledPreviewFirstPage,
          filledPreviewAllPages: filledPreviewAllPages,
          missingTokens: missingTokens,
          onSendDf: onSendDf,
          onPrintReference: onPrintReference,
        ),
      );
    },
  );
}

class ZplPreviewSheet extends StatelessWidget {
  final ZplTemplate template;
  final String filledPreviewFirstPage;
  final String filledPreviewAllPages;
  final List<String> missingTokens;
  final Future<void> Function()? onSendDf;
  final Future<void> Function()? onPrintReference;

  const ZplPreviewSheet({
    super.key,
    required this.template,
    required this.filledPreviewFirstPage,
    required this.filledPreviewAllPages,
    required this.missingTokens,
    this.onSendDf,
    this.onPrintReference,
  });

  @override
  Widget build(BuildContext context) {
    final hasMissing = missingTokens.isNotEmpty;
    final canSendDf = template.zplTemplateDf.trim().isNotEmpty;
    final isAdmin = Memory.isAdmin == true;

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Preview: ${template.templateFileName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          if (hasMissing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.18),
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '⚠ Tokens no soportados (no se generan):\n${missingTokens.join(', ')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),

          if (!canSendDf)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'DF vacío: se asume que el template ya existe en la impresora. '
                      'Se imprimirá usando Reference (^XFE).',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: TabBar(
              tabs: [
                const Tab(text: 'DF'),
                const Tab(text: 'Reference'),
                const Tab(text: 'Filled 1ra pág'),
                const Tab(text: 'Filled All pages'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TabBarView(
                children: [
                  isAdmin ? _ZplTextBox(text: template.zplTemplateDf):
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade200,
                        border: Border.all(color: Colors.blue.shade500),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Modo usuario: este sistema usa templates ya cargados en la impresora.\n'
                            'La impresión se realiza únicamente por Reference (^XFE).',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  _ZplTextBox(text: template.zplReferenceTxt),
                  _ZplTextBox(text: filledPreviewFirstPage),
                  _ZplTextBox(text: filledPreviewAllPages),
                ],
              ),
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                if (onSendDf != null)
                  if(isAdmin)ElevatedButton.icon(
                    onPressed: canSendDf ? () async => await onSendDf!() : null,
                    icon: const Icon(Icons.upload),
                    label: const Text('Enviar DF'),
                  ),
                if (onSendDf != null) const SizedBox(width: 8),
                if (onPrintReference != null)
                  ElevatedButton.icon(
                    onPressed: hasMissing ? null : () async => await onPrintReference!(),
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimir'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZplTextBox extends StatelessWidget {
  final String text;
  const _ZplTextBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}
