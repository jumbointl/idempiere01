import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_printer/riverpod_printer.dart';

class ProductLabelTsplExamplePage extends ConsumerWidget {
  const ProductLabelTsplExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TSPL Bluetooth Label Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final PrintJob<ProductLabelItem> job = PrintJob<ProductLabelItem>(
              document: ProductLabelPrintable(
                documentTitle: 'Product Labels',
                items: const <ProductLabelItem>[
                  ProductLabelItem(
                    title: 'Producto A',
                    subtitle: 'Caja grande',
                    barcode: '123456789',
                    quantity: 2,
                    location: 'A-01', kind: ProductLabelKind.complete,
                  ),
                ],
              ),
              labelProfile: const LabelProfile(
                widthMm: 60,
                heightMm: 40,
                gapMm: 3,
                dpi: 203,
                copies: 1,
                rowsPerPage: 1,
                id: '', name: '',
              ),
              printer: const PrinterDevice(
                id: 'tspl_1',
                name: 'TSPL Printer',
                transport: PrinterTransport.tcp,
                type: PrinterType.label,
                language: PrinterLanguage.tspl,
                host: '192.168.188.100',
                port: 9100,
              ),
              printerType: PrinterType.label,
              printerLanguage: PrinterLanguage.tspl,
            );

            final executor = ref.read(printExecutorProvider);
            final result = await executor.execute(job);

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.success ? 'Print sent successfully' : result.message,
                ),
              ),
            );
          },
          child: const Text('Print TSPL via Bluetooth'),
        ),
      ),
    );
  }
}