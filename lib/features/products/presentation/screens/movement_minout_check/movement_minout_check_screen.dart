import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/data/memory.dart';
import '../../../../shared/data/messages.dart';
import '../../../common/async_value_consumer_simple_state.dart';
import '../../../domain/idempiere/movement_minout_check.dart';
import '../../../domain/idempiere/response_async_value.dart';
import '../../providers/movement_minout_check/find_movement_minout_by_doc_no_providers.dart';
import '../../providers/movement_minout_check/movement_minout_check_input_providers.dart';
import '../../providers/product_provider_common.dart';
import 'locator_check_card.dart';

class MovementMInOutCheckScreen extends ConsumerStatefulWidget {
  const MovementMInOutCheckScreen({super.key});

  @override
  ConsumerState<MovementMInOutCheckScreen> createState() =>
      _MovementMInOutCheckScreenState();
}

class _MovementMInOutCheckScreenState
    extends AsyncValueConsumerSimpleState<MovementMInOutCheckScreen> {
  @override
  int get actionScanTypeInt =>
      Memory.ACTION_FIND_BY_DOC_NO_FOR_MOV_MINOUT_CHECK;

  @override
  bool get showLeading => true;

  @override
  Color? getAppBarBackgroundColor(BuildContext context, WidgetRef ref) =>
      Colors.amber[50];

  @override
  double getWidth() => MediaQuery.of(context).size.width - 30;

  @override
  AsyncValue<ResponseAsyncValue> get mainDataAsync =>
      ref.watch(findMovMInOutByDocNoProvider);

  @override
  Future<void> setDefaultValuesOnInitState(
    BuildContext context,
    WidgetRef ref,
  ) async {
    isScanning = false;
    isDialogShowed = false;
    inputString = '';
    actionScan = actionScanTypeInt;
  }

  @override
  void executeAfterShown() {
    ref.read(actionScanProvider.notifier).state =
        Memory.ACTION_FIND_BY_DOC_NO_FOR_MOV_MINOUT_CHECK;
  }

  @override
  void initialSettingOnBuild(BuildContext context, WidgetRef ref) {}

  @override
  Future<void> handleInputString({
    required WidgetRef ref,
    required String inputData,
    required int actionScan,
  }) async {
    // Mirror the input into the read-only TextField shown in the screen
    // header so a scan, manual dialog or URL launcher all converge on the
    // same provider before firing the search.
    ref.read(docNoInputProvider.notifier).state =
        inputData.trim().toUpperCase();

    final action = ref.read(findMovMInOutByDocNoActionProvider);
    await action.handleInputString(
      ref: ref,
      inputData: inputData,
      actionScan: actionScan,
    );
  }

  /// Re-fires the search with whatever is currently in
  /// [docNoInputProvider]. Bound to the search button next to the
  /// DocumentNo TextField.
  Future<void> _runSearchFromInput() async {
    final docNo = ref.read(docNoInputProvider).trim();
    if (docNo.isEmpty) return;
    final action = ref.read(findMovMInOutByDocNoActionProvider);
    await action.handleInputString(
      ref: ref,
      inputData: docNo,
      actionScan: actionScanTypeInt,
    );
  }

  Future<void> _openDocNoInputDialog() async {
    final current = ref.read(docNoInputProvider);
    final controller = TextEditingController(text: current);
    // Suppress scan dispatch while the dialog is open so a stray scan
    // doesn't re-fire the screen's search handler. Restored on dialog
    // close via finally (covers OK, Cancel, dismiss, and exceptions).
    final oldAction = ref.read(actionScanProvider);
    ref.read(actionScanProvider.notifier).state = 0;
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Document No'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Scan or type'),
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(Messages.CANCEL),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(Messages.OK),
            ),
          ],
        ),
      );
    } finally {
      ref.read(actionScanProvider.notifier).state = oldAction;
    }
    if (result == null) return;
    final code = result.trim();
    if (code.isEmpty) return;
    await handleInputString(
      ref: ref,
      inputData: code,
      actionScan: actionScanTypeInt,
    );
  }

  @override
  Widget? getAppBarTitle(BuildContext context, WidgetRef ref) {
    return const Text(
      'Mov / MInOut Check',
      style: TextStyle(fontSize: themeFontSizeLarge),
    );
  }

  @override
  Widget getMainDataCard(BuildContext context, WidgetRef ref) {
    final docNo = ref.watch(docNoInputProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // DocumentNo input row — read-only TextField mirroring the
        // provider; tap opens manual dialog; search button re-fires.
        Row(
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: _openDocNoInputDialog,
                child: AbsorbPointer(
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: docNo),
                    decoration: const InputDecoration(
                      labelText: 'Document No',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.purple),
              tooltip: 'BUSCAR',
              onPressed: _runSearchFromInput,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _SourceSegmentedButton(),
        const SizedBox(height: 8),
        mainDataAsync.when(
          data: (response) {
            if (!response.isInitiated) {
              return _hint('Scan a document number to start.');
            }
            if (response.success != true || response.data == null) {
              return _msgCard(response.message);
            }

            final raw = response.data;
            if (raw is! MovementMInOutCheckPayload) {
              return _msgCard(response.message);
            }

            return _CheckBody(payload: raw);
          },
          error: (e, _) => _msgCard('Error: $e'),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          ),
        ),
      ],
    );
  }

  Widget _hint(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _msgCard(String? msg) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(msg ?? ''),
        ),
      ),
    );
  }
}

class _SourceSegmentedButton extends ConsumerWidget {
  const _SourceSegmentedButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(movMInOutCheckSourceProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SegmentedButton<MovementMInOutCheckSource>(
        segments: const <ButtonSegment<MovementMInOutCheckSource>>[
          ButtonSegment(
            value: MovementMInOutCheckSource.movement,
            label: Text('Movement'),
            icon: Icon(Icons.swap_horiz),
          ),
          ButtonSegment(
            value: MovementMInOutCheckSource.minout,
            label: Text('MInOut'),
            icon: Icon(Icons.local_shipping),
          ),
        ],
        selected: <MovementMInOutCheckSource>{selected},
        onSelectionChanged: (s) {
          ref.read(movMInOutCheckSourceProvider.notifier).state = s.first;
        },
      ),
    );
  }
}

class _CheckBody extends StatelessWidget {
  const _CheckBody({required this.payload});

  final MovementMInOutCheckPayload payload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Header(payload: payload),
        const SizedBox(height: 8),
        if (payload.locatorGroups.isEmpty &&
            payload.linesWithoutLocator.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No lines found in this document.'),
              ),
            ),
          )
        else ...<Widget>[
          ...payload.locatorGroups.map(
            (g) => LocatorCheckCard(
              key: ValueKey('lcc-${g.locator.id}'),
              group: g,
              source: payload.source,
              documentNo: payload.documentNo,
            ),
          ),
          if (payload.linesWithoutLocator.isNotEmpty)
            _LinesWithoutLocatorCard(
              count: payload.linesWithoutLocator.length,
            ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.payload});

  final MovementMInOutCheckPayload payload;

  @override
  Widget build(BuildContext context) {
    final totalLocators = payload.locatorGroups.length;
    final allOk = payload.locatorGroups.every((g) => g.allOk);
    final color = totalLocators == 0
        ? Colors.grey.shade100
        : (allOk ? Colors.green.shade100 : Colors.pink.shade100);

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${payload.source.label}: ${payload.documentNo}',
              style: const TextStyle(
                fontSize: themeFontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Locators: $totalLocators'
              '${payload.linesWithoutLocator.isNotEmpty ? "  •  ${payload.linesWithoutLocator.length} sin locator" : ""}',
              style: const TextStyle(fontSize: themeFontSizeSmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinesWithoutLocatorCard extends StatelessWidget {
  const _LinesWithoutLocatorCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade100,
      child: ListTile(
        leading: const Icon(Icons.help_outline),
        title: Text('$count líneas sin locator'),
        subtitle: const Text(
          'No tienen M_Locator_ID — no se chequea stock.',
        ),
      ),
    );
  }
}
