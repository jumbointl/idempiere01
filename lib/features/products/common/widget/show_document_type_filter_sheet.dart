import 'package:flutter/material.dart' ;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../config/theme/app_theme.dart';
import '../../../shared/data/messages.dart';
import '../../presentation/providers/common_provider.dart';
import '../../presentation/screens/movement/provider/new_movement_provider.dart';
import '../time_utils.dart';

void showDocumentTypeFilterSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Future<void> Function(DateTime date, {required String inOut}) onDataChange,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  var documentTypeOptions = documentTypeOptionsAll;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, // permite ver el borde redondeado
    builder: (context) {
      return Container(
        height: screenHeight * 0.7,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,               // fondo del modal
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final String selected = ref.watch(documentTypeFilterProvider);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    Messages.DOCUMENT_TYPE,
                    style: TextStyle(
                      fontSize: themeFontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: ListView(
                    children: documentTypeOptions.map((type) {
                      final color = _colorForDocType(type);

                      return Card(
                        elevation: 3,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          tileColor: color,
                          title: Text(
                            type,
                            style: TextStyle(
                              fontWeight: type == selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          trailing: type == selected
                              ? Icon(Icons.check_circle,
                              color: Colors.purple, size: 26)
                              : null,
                          onTap: () {
                            // actualizar provider
                            ref.read(documentTypeFilterProvider.notifier).state = type;

                            // recargar búsqueda
                            final date = ref.read(selectedDateProvider);
                            final inOut = ref.read(inOutFilterProvider);
                            onDataChange(date, inOut: inOut);

                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}



/// ✅ BottomSheet reusable: título + opciones + provider configurable
void showDocumentTypeFilterMultipleDatesSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required List<String> documentTypeOptions,
  required StateProvider<String> selectedProvider,
  required StateProvider<DateTimeRange> datesRangeProvider,
  required Future<void> Function({required WidgetRef ref,required DateTimeRange dates, required String inOut})
  onDataChange,
}) {
  final screenHeight = MediaQuery.of(context).size.height;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) {
      return Container(
        height: screenHeight * 0.7,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final String selected = ref.watch(selectedProvider);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// ✅ Título configurable
                Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: themeFontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: ListView(
                    children: documentTypeOptions.map((type) {
                      final color = _colorForDocType(type);

                      return Card(
                        elevation: 3,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          tileColor: color,
                          title: Text(
                            type,
                            style: TextStyle(
                              fontWeight: type == selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          trailing: type == selected
                              ? const Icon(
                            Icons.check_circle,
                            color: Colors.purple,
                            size: 26,
                          )
                              : null,
                          onTap: () {
                            // ✅ Actualizar provider que te pasaron
                            ref.read(selectedProvider.notifier).state = type;

                            // ✅ Recargar búsqueda
                            final dates = ref.read(datesRangeProvider);
                            final inOut = ref.read(inOutFilterProvider);
                            onDataChange(ref: ref, dates: dates, inOut: inOut);

                            Navigator.of(modalCtx).pop();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

/// Colores para cada tipo de documento
Color _colorForDocType(String code) {
  switch (code) {
    case 'DR': // Draft / Borrador
      return Colors.grey.shade200;
    case 'CO': // Completed
      return Colors.green.shade200;
    case 'IP': // In Progress
      return Colors.cyan.shade200;
    default:
      return Colors.grey.shade200;
  }
}