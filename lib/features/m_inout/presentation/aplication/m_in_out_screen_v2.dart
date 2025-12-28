import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/m_in_out_confirm.dart';

import '../providers/m_in_ot_utils.dart';
import '../providers/m_in_out_providers.dart'; // showCreatePickConfirmModalBottomSheet, showCreateShipmentConfirmModalBottomSheet
import '../../../products/common/messages_dialog.dart';
import 'm_inout_notifier_v2.dart';

class MInOutScreenV2 extends ConsumerStatefulWidget {
  final String type;
  final String documentNo;

  const MInOutScreenV2({
    super.key,
    required this.type,
    required this.documentNo,
  });

  @override
  ConsumerState<MInOutScreenV2> createState() => _MInOutScreenV2State();
}

class _MInOutScreenV2State extends ConsumerState<MInOutScreenV2> {
  late String documentNo;

  @override
  void initState() {
    super.initState();
    documentNo = widget.documentNo;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(mInOutProviderV2.notifier);
      notifier.setParameters(widget.type);

      // 如果外部帶了單號，你可以選擇自動 load
      if (documentNo.isNotEmpty && documentNo != '-1') {
        notifier.onDocChange(documentNo);
        await loadMInOutAndLine(context, ref);
      } else {
        await notifier.cargarLista(ref);
      }
    });
  }

  void _showScreenLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> loadMInOutAndLine(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(mInOutProviderV2.notifier);

    _showScreenLoading(context);

    final action = await notifier.loadDocFlow(ref);

    if (context.mounted) Navigator.of(context).pop(); // 關 loading

    switch (action) {
      case LoadSuccess():
      // 不用做事，畫面會因 viewMInOut=true 自動切換
        break;

      case NeedSelectConfirm(:final confirms):
        _showSelectMInOutConfirm(
          confirms,
          context,
          notifier,
          ref.read(mInOutProviderV2),
          ref,
        );
        break;

      case NeedCreatePickConfirm(:final documentNo, :final mInOutId):
        await showCreatePickOrQaConfirmModalBottomSheet(
          isQaConfirm: false,
          ref: ref,
          documentNo: documentNo,
          mInOutId: mInOutId.toString(),
          type: MInOutType.pickConfirm, // ✅ QAConfirm 也會走這條（規則已在 Policy）
          onResultSuccess: () async {
            if (!context.mounted) return;
            await loadMInOutAndLine(context, ref);
          },
        );
        break;

      case NeedCreateShipmentConfirm(:final documentNo, :final mInOutId):
        await showCreateShipmentConfirmModalBottomSheet(
          ref: ref,
          documentNo: documentNo,
          mInOutId: mInOutId.toString(),
          type: MInOutType.shipmentConfirm,
          onResultSuccess: () async {
            if (!context.mounted) return;
            await loadMInOutAndLine(context, ref);
          },
        );
        break;

      case LoadError(:final message):
        if (context.mounted) showErrorMessage(context, ref, message);
        break;
    }
  }

  Future<void> _showSelectMInOutConfirm(
      List<MInOutConfirm> confirms,
      BuildContext context,
      MInOutNotifierV2 notifier,
      dynamic mInOutState,
      WidgetRef ref,
      ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Confirm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: ListView.builder(
                  itemCount: confirms.length,
                  itemBuilder: (context, index) {
                    final item = confirms[index];
                    return ListTile(
                      title: Text(item.documentNo ?? '---'),
                      subtitle: Text('Status: ${item.docStatus.identifier ?? ''}'),
                      onTap: () async {
                        Navigator.of(context).pop();

                        _showScreenLoading(context);
                        try {
                          await notifier.loadConfirmAndLines(ref, item);
                        } catch (e) {
                          // notifier already sets errorMessage
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateNow = ref.watch(mInOutProviderV2);
    final notifier = ref.read(mInOutProviderV2.notifier);

    // 下面你原本的 UI 很長（TabBar + _MInOutView + _ScanView...）
    // 我這裡保留一個最小可跑骨架；你把原本那段 body 換回去即可（不需要改邏輯）
    return Scaffold(
      appBar: AppBar(
        title: Text(stateNow.title),
        actions: [
          IconButton(
            onPressed: () async => loadMInOutAndLine(context, ref),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => notifier.clearMInOutData(),
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      body: Center(
        child: Text(
          stateNow.viewMInOut
              ? 'Loaded: ${stateNow.mInOut?.documentNo ?? stateNow.doc}'
              : '請輸入單號後查詢',
        ),
      ),
    );
  }
}
