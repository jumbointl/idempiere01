import 'package:flutter/material.dart';
import 'template_zpl_models.dart';

class ZplPreviewDialog extends StatelessWidget {
  final ZplTemplate template;

  final String filledPreviewFirstPage;
  final String filledPreviewAllPages;

  final List<String> missingTokens;

  final Future<void> Function()? onSendDf;
  final Future<void> Function()? onPrintReference;

  const ZplPreviewDialog({
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

    return DefaultTabController(
      length: 4,
      child: AlertDialog(
        title: Text('Preview: ${template.templateFileName}'),
        content: SizedBox(
          width: 980,
          height: 600,
          child: Column(
            children: [
              if (hasMissing)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
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

              const TabBar(
                tabs: [
                  Tab(text: 'DF'),
                  Tab(text: 'Reference'),
                  Tab(text: 'Filled 1ra pág'),
                  Tab(text: 'Filled All pages'),
                ],
              ),
              const SizedBox(height: 10),

              Expanded(
                child: TabBarView(
                  children: [
                    _ZplTextBox(text: template.zplTemplateDf),
                    _ZplTextBox(text: template.zplReferenceTxt),
                    _ZplTextBox(text: filledPreviewFirstPage),
                    _ZplTextBox(text: filledPreviewAllPages),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (onSendDf != null)
            ElevatedButton.icon(
              onPressed: () async => await onSendDf!(),
              icon: const Icon(Icons.upload),
              label: const Text('Enviar DF'),
            ),
          if (onPrintReference != null)
            ElevatedButton.icon(
              onPressed: hasMissing
                  ? null // bloquea imprimir si faltan tokens
                  : () async => await onPrintReference!(),
              icon: const Icon(Icons.print),
              label: const Text('Imprimir'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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
