
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:monalisa_app_001/features/auth/presentation/providers/auth_provider.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/line.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out_confirm.dart';
import 'package:monalisa_app_001/features/m_inout/domain/repositories/m_in_out_repositiry.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/common/number_input_panel.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_document_type.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_locator.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_warehouse.dart';
import 'package:monalisa_app_001/features/products/domain/idempiere/put_away_movement.dart';
import '../../../../config/constants/roles_app.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../products/common/number_sum_panel.dart';
import '../../../products/common/selections_dialog.dart';
import '../../../products/common/utils/action_progress_dialog.dart';
import '../../../products/common/utils/action_progress_state.dart';
import '../../../products/domain/idempiere/idempiere_organization.dart';
import '../../../products/domain/idempiere/idempiere_product.dart';
import '../../../products/presentation/screens/movement/create/movement_create_validation_result.dart';
import '../../../shared/data/memory.dart';
import '../../../shared/data/messages.dart';
import '../../../shared/presentation/widgets/custom_filled_button.dart';
import '../../domain/entities/barcode.dart';
import '../../domain/entities/line_confirm.dart';
import '../../infrastructure/repositories/m_in_out_repository_impl.dart';
import 'line_provider.dart';
import 'm_in_ot_utils.dart';

const String KEY_SAVED_MINOUT_V1 = 'saved_m_inout_v1';
const String KEY_SAVED_MINOUT_V1_TYPE = 'saved_m_inout_v1_type'; // opcional

// Storage key base for saved list
const String KEY_SAVED_MINOUT_LIST_V1_ = 'saved_m_inout_list_v1_';
// Returns a storage key per type (e.g. saved_m_inout_list_v1_moveConfirm)
String keySaveMInOutList(String typeName) {
  return '$KEY_SAVED_MINOUT_LIST_V1_$typeName';
}


int quantityOfMovementAndScannedToAllowInputScannedQuantity = 3;
const String KEY_QTY_ALLOW_INPUT =
    'qtyOfMovementAndScannedToAllowInputScannedQuantity';
final adjustScannedQtyProvider = StateProvider<bool>((ref) => true);

final mInOutProvider = StateNotifierProvider<MInOutNotifier, MInOutStatus>((
    ref,
    ) {
  return MInOutNotifier(mInOutRepository: MInOutRepositoryImpl());
});

final savedConfirmIdProvider = StateProvider<int>((ref) {
  return 0;
});

final loadedMInOutListProvider =
StateProvider.family<List<MInOut>, MInOutType>((ref, type) {
  return <MInOut>[];
});

final usingQuickCompleteProvider = StateProvider.autoDispose<bool>((ref) => false);
class MInOutNotifier extends StateNotifier<MInOutStatus> {
  final MInOutRepository mInOutRepository;
  final ScrollController scanBarcodeListScrollController = ScrollController();

  MInOutNotifier({required this.mInOutRepository})
      : super(
    MInOutStatus(
      mInOutList: [],
      doc: '',
      scanBarcodeListTotal: [],
      scanBarcodeListUnique: [],
      linesOver: [],
      uniqueView: false,
      viewMInOut: false,
      isComplete: false,
    ),
  );
  void setParameters(String type) {
    MInOutType? parsed;

    // Parse enum safely (avoids stringly-typed switch)
    try {
      parsed = MInOutType.values.byName(type);
    } catch (_) {
      parsed = null;
    }

    if (parsed == null) {
      debugPrint('[setParameters] Unknown type="$type"');
      return;
    }
    switch (parsed) {
      case MInOutType.shipment:
        state = state.copyWith(
          isSOTrx: true,
          mInOutType: MInOutType.shipment,
          title: 'Shipment',
          rolShowQty: state.mInOut?.docStatus.id.toString() == 'IP'
              ? true
              : RolesApp.appShipmentQty,
          rolManualQty: RolesApp.appShipmentManual,
          rolShowScrap: false,
          rolManualScrap: false,
          rolCompleteLow: RolesApp.appShipmentLowQty,
          rolCompleteOver: RolesApp.appShipmentLowQty,
          rolPrepare: RolesApp.appShipmentPrepare,
          rolComplete: RolesApp.appShipmentComplete,
          rolQuickComplete: RolesApp.appShipmentQuickComplete,
        );
        break;

      case MInOutType.shipmentPrepare:
      // Same as shipment, but mInOutType is shipmentPrepare
        state = state.copyWith(
          isSOTrx: true,
          mInOutType: MInOutType.shipmentPrepare,
          title: 'Shipment Prepare',
          rolShowQty: state.mInOut?.docStatus.id.toString() == 'IP'
              ? true
              : RolesApp.appShipmentQty,
          rolManualQty: RolesApp.appShipmentManual,
          rolShowScrap: false,
          rolManualScrap: false,
          rolCompleteLow: RolesApp.appShipmentLowQty,
          rolCompleteOver: RolesApp.appShipmentLowQty,
          rolPrepare: RolesApp.appShipmentPrepare,
          rolComplete: RolesApp.appShipmentComplete,
          rolQuickComplete: RolesApp.appShipmentQuickComplete,
        );
        break;

      case MInOutType.shipmentConfirm:
        state = state.copyWith(
          isSOTrx: true,
          mInOutType: MInOutType.shipmentConfirm,
          title: 'Shipment Confirm',
          rolShowQty: RolesApp.appShipmentconfirmQty,
          rolManualQty: RolesApp.appShipmentconfirmManual,
          rolShowScrap: false,
          rolManualScrap: false,
          rolCompleteLow: RolesApp.appShipmentLowQty,
          rolCompleteOver: RolesApp.appShipmentLowQty,
          rolComplete: RolesApp.appShipmentconfirmComplete,
          rolQuickComplete: RolesApp.appShipmentconfirmQuickComplete,
        );
        break;

      case MInOutType.pickConfirm:
        state = state.copyWith(
          isSOTrx: true,
          mInOutType: MInOutType.pickConfirm,
          title: 'Pick Confirm',
          rolShowQty: RolesApp.appPickconfirmQty,
          rolManualQty: RolesApp.appPickconfirmManual,
          rolShowScrap: RolesApp.appPickconfirmQty,
          rolManualScrap: RolesApp.appPickconfirmManual,
          rolCompleteLow: RolesApp.appShipmentLowQty,
          rolCompleteOver: RolesApp.appShipmentLowQty,
          rolComplete: RolesApp.appPickconfirmComplete,
          rolQuickComplete: RolesApp.appPickconfirmQuickComplete,
        );
        break;

      case MInOutType.receipt:
        state = state.copyWith(
          isSOTrx: false,
          mInOutType: MInOutType.receipt,
          title: 'Receipt',
          rolShowQty: state.mInOut?.docStatus.id.toString() == 'IP'
              ? true
              : RolesApp.appReceiptQty,
          rolManualQty: RolesApp.appReceiptManual,
          rolShowScrap: false,
          rolManualScrap: false,
          rolCompleteLow: RolesApp.appShipmentLowQty,
          rolCompleteOver: RolesApp.appShipmentLowQty,
          rolPrepare: RolesApp.appReceiptPrepare,
          rolComplete: RolesApp.appReceiptComplete,
          rolQuickComplete: RolesApp.appReceiptQuickComplete,
        );
        break;

      case MInOutType.receiptConfirm:
        state = state.copyWith(
          isSOTrx: false,
          mInOutType: MInOutType.receiptConfirm,
          title: 'Receipt Confirm',
          rolShowQty: RolesApp.appReceiptconfirmQty,
          rolManualQty: RolesApp.appReceiptconfirmManual,
          rolShowScrap: RolesApp.appReceiptconfirmQty,
          rolManualScrap: RolesApp.appReceiptconfirmManual,
          rolCompleteLow: RolesApp.appShipmentLowQty,
          rolCompleteOver: RolesApp.appShipmentLowQty,
          rolComplete: RolesApp.appReceiptconfirmComplete,
          rolQuickComplete: RolesApp.appReceiptconfirmQuickComplete,
        );
        break;

      case MInOutType.qaConfirm:
        state = state.copyWith(
          isSOTrx: false,
          mInOutType: MInOutType.qaConfirm,
          title: 'QA Confirm',
          rolShowQty: RolesApp.appQaconfirmQty,
          rolManualQty: RolesApp.appQaconfirmManual,
          rolShowScrap: RolesApp.appQaconfirmQty,
          rolManualScrap: RolesApp.appQaconfirmManual,
          rolCompleteLow: RolesApp.appShipmentLowQty,
          rolCompleteOver: RolesApp.appShipmentLowQty,
          rolComplete: RolesApp.appQaconfirmComplete,
          rolQuickComplete: RolesApp.appQaconfirmQuickComplete,
        );
        break;

      case MInOutType.move:
        state = state.copyWith(
          isSOTrx: null,
          mInOutType: MInOutType.move,
          title: 'Move',
          rolShowQty: true,
          rolManualQty: RolesApp.appShipmentManual,
          rolShowScrap: false,
          rolManualScrap: false,
          rolCompleteLow: true,
          rolCompleteOver: true,
          rolComplete: RolesApp.appMovementComplete,
          rolQuickComplete: RolesApp.appMovementQuickComplete,
        );
        break;

      case MInOutType.moveConfirm:
        state = state.copyWith(
          isSOTrx: null,
          mInOutType: MInOutType.moveConfirm,
          title: 'Move Confirm',
          rolShowQty: true,
          rolManualQty: true,
          rolShowScrap: false,
          rolManualScrap: false,
          rolCompleteLow: true,
          rolCompleteOver: true,
          rolComplete: RolesApp.appMovementconfirmComplete,
          rolQuickComplete: RolesApp.appMovementconfirmQuickComplete,
        );
        break;
    }
  }

  /*void setParameters(String type) {
    if (type == MInOutType.shipment.name) {
      state = state.copyWith(
        isSOTrx: true,
        mInOutType: MInOutType.shipment,
        title: 'Shipment',
        rolShowQty: state.mInOut?.docStatus.id.toString() == 'IP'
            ? true
            : RolesApp.appShipmentQty,
        rolManualQty: RolesApp.appShipmentManual,
        rolShowScrap: false,
        rolManualScrap: false,
        rolCompleteLow: RolesApp.appShipmentLowQty,
        rolCompleteOver: false,
        rolPrepare: RolesApp.appShipmentPrepare,
        rolComplete: RolesApp.appShipmentComplete,
        rolQuickComplete: RolesApp.appShipmentQuickComplete,
      );
    } else if (type == MInOutType.shipmentConfirm.name) {
      state = state.copyWith(
        isSOTrx: true,
        mInOutType: MInOutType.shipmentConfirm,
        title: 'Shipment Confirm',
        rolShowQty: RolesApp.appShipmentconfirmQty,
        rolManualQty: RolesApp.appShipmentconfirmManual,
        rolShowScrap: false,
        rolManualScrap: false,
        rolCompleteLow: RolesApp.appShipmentLowQty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appShipmentconfirmComplete,
        rolQuickComplete: RolesApp.appShipmentconfirmQuickComplete,
      );
    } else if (type == MInOutType.pickConfirm.name) {
      state = state.copyWith(
        isSOTrx: true,
        mInOutType: MInOutType.pickConfirm,
        title: 'Pick Confirm',
        rolShowQty: RolesApp.appPickconfirmQty,
        rolManualQty: RolesApp.appPickconfirmManual,
        rolShowScrap: RolesApp.appPickconfirmQty,
        rolManualScrap: RolesApp.appPickconfirmManual,
        rolCompleteLow: RolesApp.appShipmentLowQty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appPickconfirmComplete,
        rolQuickComplete: RolesApp.appPickconfirmQuickComplete,
      );
    } else if (type == MInOutType.receipt.name) {
      state = state.copyWith(
        isSOTrx: false,
        mInOutType: MInOutType.receipt,
        title: 'Receipt',
        rolShowQty: state.mInOut?.docStatus.id.toString() == 'IP'
            ? true
            : RolesApp.appReceiptQty,
        rolManualQty: RolesApp.appReceiptManual,
        rolShowScrap: false,
        rolManualScrap: false,
        rolCompleteLow: RolesApp.appShipmentLowQty,
        rolCompleteOver: false,
        rolPrepare: RolesApp.appReceiptPrepare,
        rolComplete: RolesApp.appReceiptComplete,
        rolQuickComplete: RolesApp.appReceiptQuickComplete,
      );
    } else if (type == MInOutType.receiptConfirm.name) {
      state = state.copyWith(
        isSOTrx: false,
        mInOutType: MInOutType.receiptConfirm,
        title: 'Receipt Confirm',
        rolShowQty: RolesApp.appReceiptconfirmQty,
        rolManualQty: RolesApp.appReceiptconfirmManual,
        rolShowScrap: RolesApp.appReceiptconfirmQty,
        rolManualScrap: RolesApp.appReceiptconfirmManual,
        rolCompleteLow: RolesApp.appShipmentLowQty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appReceiptconfirmComplete,
        rolQuickComplete: RolesApp.appReceiptconfirmQuickComplete,
      );
    } else if (type == MInOutType.qaConfirm.name) {
      state = state.copyWith(
        isSOTrx: false,
        mInOutType: MInOutType.qaConfirm,
        title: 'QA Confirm',
        rolShowQty: RolesApp.appQaconfirmQty,
        rolManualQty: RolesApp.appQaconfirmManual,
        rolShowScrap: RolesApp.appQaconfirmQty,
        rolManualScrap: RolesApp.appQaconfirmManual,
        rolCompleteLow: RolesApp.appShipmentLowQty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appQaconfirmComplete,
        rolQuickComplete: RolesApp.appQaconfirmQuickComplete,
      );
    } else if (type == MInOutType.move.name) {
      state = state.copyWith(
        isSOTrx: null,
        mInOutType: MInOutType.move,
        title: 'Move',
        rolShowQty: true,
        rolManualQty: RolesApp.appShipmentManual,
        rolShowScrap: false,
        rolManualScrap: false,
        rolCompleteLow: true,
        rolCompleteOver: false,
        rolComplete: RolesApp.appMovementComplete,
        rolQuickComplete: RolesApp.appMovementQuickComplete,
      );
    } else if (type == MInOutType.moveConfirm.name) {
      state = state.copyWith(
        isSOTrx: null,
        mInOutType: MInOutType.moveConfirm,
        title: 'Move Confirm',
        rolShowQty: true,
        rolManualQty: true,
        rolShowScrap: false,
        rolManualScrap: false,
        rolCompleteLow: true,
        rolCompleteOver: false,
        rolComplete: RolesApp.appMovementconfirmComplete,
        rolQuickComplete: RolesApp.appMovementconfirmQuickComplete,
      );
    }
  }*/
  Future<bool> restoreFromPayload(
      WidgetRef ref,
      Map<String, dynamic> map, {
        BuildContext? context,
      }) async {
    try {
      if ((map['version'] ?? 0) != 1) return false;

      final mInOutJson = map['mInOut'];
      final mInOutConfirmJson = map['mInOutConfirm'];

      final MInOut? restoredMInOut =
      (mInOutJson is Map<String, dynamic>) ? MInOut.fromJson(mInOutJson) : null;
      if(restoredMInOut != null){
        final stateLines = restoredMInOut.lines ;
        for(final line in stateLines){
          debugPrint('restoredMInOut ${line.line ?? ''}, ${line.confirmId ?? 'confirmId null'}');
        }
      }
      final MInOutConfirm? restoredConfirm =
      (mInOutConfirmJson is Map<String, dynamic>) ? MInOutConfirm.fromJson(mInOutConfirmJson) : null;

      List<Barcode> parseBarcodeList(dynamic v) {
        if (v is! List) return <Barcode>[];
        return v.whereType<Map<String, dynamic>>().map((e) => Barcode.fromJson(e)).toList();
      }

      List<MInOutConfirm> parseMInOutConfirmList(dynamic v) {
        if (v is! List) return <MInOutConfirm>[];
        return v.whereType<Map<String, dynamic>>().map((e) => MInOutConfirm.fromJson(e)).toList();
      }

      final total = parseBarcodeList(map['scanBarcodeListTotal']);
      final unique = parseBarcodeList(map['scanBarcodeListUnique']);
      final over = parseBarcodeList(map['linesOver']);

      final savedTypeName = (map['mInOutType'] ?? '').toString();
      final savedType = MInOutType.values.firstWhere(
            (e) => e.name == savedTypeName,
        orElse: () => state.mInOutType,
      );

      state = state.copyWith(
        doc: (map['doc'] ?? '').toString(),
        mInOutType: savedType,
        title: (map['title'] ?? state.title).toString(),
        isSOTrx: map['isSOTrx'] as bool? ?? state.isSOTrx,
        viewMInOut: map['viewMInOut'] as bool? ?? true,
        uniqueView: map['uniqueView'] as bool? ?? state.uniqueView,
        orderBy: (map['orderBy'] ?? state.orderBy).toString(),
        manualQty: (map['manualQty'] as num?)?.toDouble() ?? state.manualQty,
        scrappedQty: (map['scrappedQty'] as num?)?.toDouble() ?? state.scrappedQty,
        editLocator: (map['editLocator'] ?? '').toString(),
        isComplete: map['isComplete'] as bool? ?? false,
        usingRolQuickComplete: map['usingRolQuickComplete'] as bool? ?? false,


        // roles (SECURITY): do NOT restore from payload
        rolShowQty: state.rolShowQty,
        rolShowScrap: state.rolShowScrap,
        rolManualQty: state.rolManualQty,
        rolManualScrap: state.rolManualScrap,
        rolCompleteLow: state.rolCompleteLow,
        rolCompleteOver: state.rolCompleteOver,
        rolPrepare: state.rolPrepare,
        rolComplete: state.rolComplete,
        rolQuickComplete: state.rolQuickComplete,
        /*
        // roles old
        rolShowQty: map['rolShowQty'] as bool? ?? state.rolShowQty,
        rolShowScrap: map['rolShowScrap'] as bool? ?? state.rolShowScrap,
        rolManualQty: map['rolManualQty'] as bool? ?? state.rolManualQty,
        rolManualScrap: map['rolManualScrap'] as bool? ?? state.rolManualScrap,
        rolCompleteLow: map['rolCompleteLow'] as bool? ?? state.rolCompleteLow,
        rolCompleteOver: map['rolCompleteOver'] as bool? ?? state.rolCompleteOver,
        rolPrepare: map['rolPrepare'] as bool? ?? state.rolPrepare,
        rolComplete: map['rolComplete'] as bool? ?? state.rolComplete,
        rolQuickComplete: map['rolQuickComplete'] as bool? ?? state.rolQuickComplete,*/

        // data
        mInOut: restoredMInOut,
        mInOutConfirm: restoredConfirm,
        scanBarcodeListTotal: total,
        scanBarcodeListUnique: unique,
        linesOver: over,
        mInOutConfirmList: parseMInOutConfirmList(map['mInOutConfirmList']),


        errorMessage: '',
        isLoading: false,
        isLoadingMInOutList: false,
      );
      if(state.mInOut != null){
        final stateLines = state.mInOut!.lines ;
        for(final line in stateLines){
          debugPrint('restoredMInOut state ${line.line ?? ''}, M ${line.movementQty ?? ''}, C ${line.confirmedQty ?? ''}');
        }
      }

      debugPrint('RESTORED mInOutConfirmList: ${state.mInOutConfirmList.length}');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al restaurar: $e');
      return false;
    }
  }


  /*Future<bool> restoreFromStorage(WidgetRef ref, {BuildContext? context}) async {
    final box = GetStorage();
    final raw = box.read(KEY_SAVED_MINOUT_V1);
    if (raw == null || raw.toString().trim().isEmpty) return false;

    try {
      final Map<String, dynamic> map =
      jsonDecode(raw is String ? raw : raw.toString()) as Map<String, dynamic>;

      if ((map['version'] ?? 0) != 1) {
        // versión desconocida
        return false;
      }

      // Reconstrucción de entities
      final mInOutJson = map['mInOut'];
      final mInOutConfirmJson = map['mInOutConfirm'];

      final MInOut? restoredMInOut =
      (mInOutJson is Map<String, dynamic>) ? MInOut.fromJson(mInOutJson) : null;

      final MInOutConfirm? restoredConfirm = (mInOutConfirmJson is Map<String, dynamic>)
          ? MInOutConfirm.fromJson(mInOutConfirmJson)
          : null;

      List<Barcode> parseBarcodeList(dynamic v) {
        if (v is! List) return <Barcode>[];
        return v
            .whereType<Map<String, dynamic>>()
            .map((e) => Barcode.fromJson(e))
            .toList();
      }

      final total = parseBarcodeList(map['scanBarcodeListTotal']);
      final unique = parseBarcodeList(map['scanBarcodeListUnique']);
      final over = parseBarcodeList(map['linesOver']);

      // Tipo (por si querés setearlo también)
      final savedTypeName = (map['mInOutType'] ?? '').toString();
      final savedType = MInOutType.values.firstWhere(
            (e) => e.name == savedTypeName,
        orElse: () => state.mInOutType,
      );

      state = state.copyWith(
        doc: (map['doc'] ?? '').toString(),
        mInOutType: savedType,
        title: (map['title'] ?? state.title).toString(),
        isSOTrx: map['isSOTrx'] as bool? ?? state.isSOTrx,
        viewMInOut: map['viewMInOut'] as bool? ?? true,
        uniqueView: map['uniqueView'] as bool? ?? state.uniqueView,
        orderBy: (map['orderBy'] ?? state.orderBy).toString(),
        manualQty: (map['manualQty'] as num?)?.toDouble() ?? state.manualQty,
        scrappedQty: (map['scrappedQty'] as num?)?.toDouble() ?? state.scrappedQty,
        editLocator: (map['editLocator'] ?? '').toString(),
        isComplete: map['isComplete'] as bool? ?? false,

        // roles
        rolShowQty: map['rolShowQty'] as bool? ?? state.rolShowQty,
        rolShowScrap: map['rolShowScrap'] as bool? ?? state.rolShowScrap,
        rolManualQty: map['rolManualQty'] as bool? ?? state.rolManualQty,
        rolManualScrap: map['rolManualScrap'] as bool? ?? state.rolManualScrap,
        rolCompleteLow: map['rolCompleteLow'] as bool? ?? state.rolCompleteLow,
        rolCompleteOver: map['rolCompleteOver'] as bool? ?? state.rolCompleteOver,
        rolPrepare: map['rolPrepare'] as bool? ?? state.rolPrepare,
        rolComplete: map['rolComplete'] as bool? ?? state.rolComplete,

        // data
        mInOut: restoredMInOut,
        mInOutConfirm: restoredConfirm,

        scanBarcodeListTotal: total,
        scanBarcodeListUnique: unique,
        linesOver: over,

        errorMessage: '',
        isLoading: false,
        isLoadingMInOutList: false,
      );

      // Opcional: recomputar estados de líneas basados en barcodes guardados
      // (para que el status/colores queden consistentes).
      // Esto usa tu lógica existente.
      if (context != null && context.mounted) {
        updatedMInOutLineSilence(''); // recalcula con scanBarcodeListUnique
      }

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al restaurar: $e');
      return false;
    }
  }*/

  Future<void> loadMInOutAndLine(BuildContext context, WidgetRef ref) async {
    final mInOutNotifier = ref.read(mInOutProvider.notifier);

    debugPrint('[loadMInOutAndLine] START');

    final String doc = state.doc;

    debugPrint('[loadMInOutAndLine] type=${state.mInOutType} doc=$doc');

    // ---------------- CONFIRM FLOWS ----------------
    if (isMInOutConfirmType(state.mInOutType)) {
      debugPrint('[loadMInOutAndLine] route=CONFIRM');
      int savedConfirmId = ref.read(savedConfirmIdProvider) ;
      try {

        final mInOut = await mInOutNotifier.getMInOutAndLine(ref);
        if (mInOut.id == null) {
          debugPrint('[loadMInOutAndLine] route=CONFIRM ${mInOut.id ?? 'id null'}');
          state = state.copyWith(
              isLoading: false
          );
          if (!context.mounted) return;
          showErrorMessage(
            durationSeconds: 0,
            context,
            ref,
            '${Messages.NOT_M_IN_OUT_RECORD_FOUND} : $doc',
          );
          return;
        }


        if(savedConfirmId>0){
          MInOutConfirm m = await mInOutNotifier.getMInOutConfirmAndLine(savedConfirmId, ref);
          state = state.copyWith(mInOutConfirm: m,mInOut: mInOut,isLoading: false,viewMInOut: true);
        } else {
            final confirmList = await mInOutNotifier.getMInOutConfirmList(mInOut.id!, ref);
            state = state.copyWith(mInOutConfirmList: confirmList,isLoading: false);
            if (!context.mounted) return;
            await _handleConfirmFlow(
            context: context,
            ref: ref,
            notifier: mInOutNotifier,
            stateNow: state,
            doc: doc,
            mInOut: mInOut,
            confirmList: confirmList,
          );
        }


      } catch (e) {
        // Error already logged by _withLoading
      }

      return;
    }

    // ---------------- MOVE CONFIRM ----------------
    if (isMoveConfirmType(state.mInOutType)) {
      debugPrint('[loadMInOutAndLine] route=MOVE_CONFIRM');
      int savedConfirmId = ref.read(savedConfirmIdProvider) ;
      if(savedConfirmId>0){

        final mInOut = await mInOutNotifier.getMovementAndLine(ref) ;
        final mInOutConfirm = await mInOutNotifier.getMovementConfirmAndLine(savedConfirmId, ref);
        state = state.copyWith(mInOut:mInOut,mInOutConfirm: mInOutConfirm, isLoading: false);

      } else {
        debugPrint('[loadMInOutAndLine] route=MOVE_CONFIRM no savedConfirmId');
        await _handleMoveConfirmFlow(
          context: context,
          ref: ref,
          notifier: mInOutNotifier,
          stateNow: state,
        );
      }




      return;
    }

    // ---------------- MOVE ----------------
    if (isMoveType(state.mInOutType)) {
      debugPrint('[loadMInOutAndLine] route=MOVE');
      await mInOutNotifier.getMovementAndLine(ref);
      return;
    }

    // ---------------- NORMAL IN/OUT ----------------
    debugPrint('[loadMInOutAndLine] route=ONLY_MInOut');
    await _handleNormalFlow(ref: ref, notifier: mInOutNotifier);
  }


  bool isMInOutConfirmType(MInOutType t) {
    return t == MInOutType.shipmentConfirm ||
        t == MInOutType.receiptConfirm ||
        t == MInOutType.pickConfirm ||
        t == MInOutType.qaConfirm;
  }
  bool isShipmentPrepareType(MInOutType t) {
    return t == MInOutType.shipmentPrepare;
  }

  bool isMoveConfirmType(MInOutType t) {
    return t == MInOutType.moveConfirm;
  }

  bool isMoveType(MInOutType t) {
    return t == MInOutType.move;
  }


  bool isMInOutConfirmCreateFlow(MInOutType type, List<MInOutConfirm> mInOutConfirmList) {
    if(mInOutConfirmList.isNotEmpty) return false;
    if(!canCreateDocument(type)) return false;
    return type == MInOutType.shipmentConfirm ||
        type == MInOutType.receiptConfirm ||
        type == MInOutType.pickConfirm ||
        type == MInOutType.qaConfirm ||
        type == MInOutType.shipment
    ;
  }
  Future<void> _handleConfirmFlow({
    required BuildContext context,
    required WidgetRef ref,
    required MInOutNotifier notifier,
    required MInOutStatus stateNow,
    required String doc,
    required MInOut mInOut,
    required List<MInOutConfirm> confirmList,
  }) async {
    debugPrint('_handleConfirmFlow');

    // Decide whether to auto-create a confirm or let user pick one
    if (isMInOutConfirmCreateFlow(stateNow.mInOutType, confirmList)) {
      final isPickConfirm = stateNow.mInOutType == MInOutType.pickConfirm;
      final isQaConfirm = stateNow.mInOutType == MInOutType.qaConfirm;
      final isShipmentConfirm = stateNow.mInOutType == MInOutType.shipmentConfirm;
      final isReceiptConfirm = stateNow.mInOutType == MInOutType.receiptConfirm;

      // Capability flags from backend
      final canCreatePickConfirm = mInOut.canCreatePickConfirm;
      final canCreateShipmentConfirm = mInOut.canCreateShipmentConfirm;
      final canCreateQaConfirm = mInOut.canCreateQaConfirm;
      final canCreateReceiptConfirm = mInOut.canCreateReceiptConfirm;

      debugPrint('[loadMInOutAndLine] auto-create confirm flow');

      if (!context.mounted) return;

      if (isPickConfirm && canCreatePickConfirm) {
        await showCreatePickOrQaConfirmModalBottomSheet(
          ref: ref,
          isQaConfirm: false,
          documentNo: doc,
          mInOutId: mInOut.id?.toString() ?? '',
          type: MInOutType.pickConfirm,
          onResultSuccess: () async {
            if (!context.mounted) return;
            await loadMInOutAndLine(context, ref);
          },
        );
        return;
      }

      if (isShipmentConfirm && canCreateShipmentConfirm) {
        await showCreateShipmentConfirmModalBottomSheet(
          ref: ref,
          documentNo: doc,
          mInOutId: mInOut.id?.toString() ?? '',
          type: MInOutType.shipmentConfirm,
          onResultSuccess: () async {
            if (!context.mounted) return;
            await loadMInOutAndLine(context, ref);
          },
        );
        return;
      }

      if (isReceiptConfirm && canCreateReceiptConfirm) {
        await showCreateReceiptConfirmModalBottomSheet(
          ref: ref,
          documentNo: doc,
          mInOutId: mInOut.id?.toString() ?? '',
          type: MInOutType.receiptConfirm,
          onResultSuccess: () async {
            if (!context.mounted) return;
            await loadMInOutAndLine(context, ref);
          },
        );
        return;
      }

      if (isQaConfirm && canCreateQaConfirm) {
        await showCreatePickOrQaConfirmModalBottomSheet(
          ref: ref,
          isQaConfirm: true,
          documentNo: doc,
          mInOutId: mInOut.id?.toString() ?? '',
          type: MInOutType.qaConfirm,
          onResultSuccess: () async {
            if (!context.mounted) return;
            await loadMInOutAndLine(context, ref);
          },
        );
        return;
      }

      // If none matched, fall back to selection

    }
    // Show selection modal
    _showSelectMInOutConfirm(context, notifier, stateNow,confirmList, ref);

  }
  Future<void> _handleMoveConfirmFlow({
    required BuildContext context, // lo dejamos pero no lo usamos para UI
    required WidgetRef ref,
    required MInOutNotifier notifier,
    required MInOutStatus stateNow,
  }) async {
    debugPrint('_handleMoveConfirmFlow');
    state = state.copyWith(isLoading: true, errorMessage: '',viewMInOut: true);

    try {
      final mInOut = await notifier.getMovementAndLine(ref);
      if (mInOut.id == null) return;

      // ✅ usa un context estable
      final stableCtx = ref.context;
      if (!stableCtx.mounted) {
        debugPrint('_handleMoveConfirmFlow ABORT (ref.context unmounted) after getMovementAndLine');
        return;
      }

      final confirmList = await notifier.getMovementConfirmList(mInOut.id!, ref);


      if (!stableCtx.mounted) {
        debugPrint('_handleMoveConfirmFlow ABORT (ref.context unmounted) after getMovementConfirmList');
        return;
      }


      if(confirmList.isEmpty){
        state = state.copyWith(
            isLoading: false, errorMessage: '', isComplete: false,
            viewMInOut: true);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!stableCtx.mounted) return;

          await showWarningMessage(
            durationSeconds: 0,
            stableCtx,
            ref,
            'No hay confirmaciones disponibles para este movimiento.\n${mInOut.documentNo}',
          );

          if (!stableCtx.mounted) return;

          clearMInOutData();
        });

        return;
      }
      state = state.copyWith(
          mInOut: mInOut,
          isLoading: false, errorMessage: '', isComplete: false,
          viewMInOut: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!stableCtx.mounted) return;


        _showSelectMInOutConfirm(
          stableCtx,
          notifier,
          stateNow,
          confirmList,
          ref,
        );
      });
    } catch (e) {
      state = state.copyWith(mInOut:null,isLoading: false, errorMessage: e.toString());
      debugPrint('_handleMoveConfirmFlow error $e');
    }
  }



  Future<void> _handleNormalFlow({
    required WidgetRef ref,
    required MInOutNotifier notifier,
  }) async {
    // Normal flow: just fetch MInOut + lines and let the state drive the UI

    MInOut mInOut = await notifier.getMInOutAndLine(ref);


  }


  Future<void> _showSelectMInOutConfirm(
      BuildContext context,
      MInOutNotifier mInOutNotifier,
      MInOutStatus mInOutState,
      List<MInOutConfirm> mInOutConfirmList,
      WidgetRef ref,
      ) {
    debugPrint('_showSelectMInOutConfirm ${mInOutConfirmList.length}');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7, // ocupa el 70% de la pantalla
          child: Column(
            children: [
              // ---------- HEADER ----------
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Seleccione el ${mInOutState.title}',
                  style: const TextStyle(
                    fontSize: themeFontSizeLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 0),

              // ---------- LISTA O MENSAJE ----------
              Expanded(
                child: mInOutConfirmList.isNotEmpty
                    ? ListView.builder(
                  itemCount: mInOutConfirmList.length,
                  itemBuilder: (context, index) {
                    final item = mInOutConfirmList[index];
                    debugPrint('item ${item.docStatus.toJson()}');
                    final bool canComplete = item.isDraft || item.isInProgress;

                    late final Color backgroundColor ;
                    if(canComplete){
                      backgroundColor =  Colors.green.shade200;
                    } else {
                      backgroundColor =  Colors.white;
                    }
                    return InkWell(
                      onTap: () {
                        if(!canComplete){
                          String message = '${Messages.DOCUMENT_STATUS} = ${item.docStatus.id}';
                          showErrorMessage(durationSeconds: 0,context,ref,message);
                          return ;
                        }
                        if (mInOutState.mInOutType == MInOutType.moveConfirm) {
                          mInOutNotifier.getMovementConfirmAndLine(item.id!, ref);
                        } else {
                          mInOutNotifier.getMInOutConfirmAndLine(item.id!, ref);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Container(
                          color: backgroundColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.documentNo.toString(),
                                    style: const TextStyle(
                                      fontSize: themeFontSizeLarge,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10,),
                                  Text(
                                    item.docStatus.id.toString(),
                                    style: TextStyle(color: Colors.purple),)
                                ],
                              ),
                              Text(
                                item.mInOutId.identifier ?? '',
                                style: TextStyle(
                                  fontSize: themeFontSizeSmall,
                                  color: themeColorGray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(height: 0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                )
                    : const Center(
                  child: Text(
                    'No hay confirmaciones pendientes.',
                    style: TextStyle(fontSize: themeFontSizeNormal),
                  ),
                ),
              ),

              // ---------- BOTONES ----------
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomFilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  label: 'Cerrar',
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> loadDataList(WidgetRef ref) async {
    if (state.mInOutType == MInOutType.move ||
        state.mInOutType == MInOutType.moveConfirm) {
      await getMovementList(ref);
    } else {
      await getMInOutList(ref);
    }
  }
  Future<void> loadSavedDataList(WidgetRef ref) async {
    state = state.copyWith(isLoadingMInOutList: true, errorMessage: '');
    final mInOutType = ref.read(mInOutProvider).mInOutType;
    state = state.copyWith(mInOutList: ref.read(loadedMInOutListProvider(mInOutType)));
    state = state.copyWith(
      isLoadingMInOutList: false,
    );

  }

  Future<void> getMInOutList(WidgetRef ref) async {
    debugPrint('getMInOutList');
    state = state.copyWith(isLoadingMInOutList: true, errorMessage: '');
    final mInOutType = ref.read(mInOutProvider).mInOutType;
    try {
      final mInOutResponse = await mInOutRepository.getMInOutList(ref);
      ref.read(loadedMInOutListProvider(mInOutType).notifier).state = mInOutResponse;
      if (mInOutResponse.isEmpty) {
        state = state.copyWith(mInOutList: [], isLoadingMInOutList: false);
        return;
      }
      state = state.copyWith(
        mInOutList: mInOutResponse,
        isLoadingMInOutList: false,
      );
    } catch (e) {
      state = state.copyWith(
        mInOutList: [],
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoadingMInOutList: false,
      );
    }
  }
  Future<void> getMInOutListByDateRange({required WidgetRef ref,required String inOut, required DateTimeRange dates, }) async {
    state = state.copyWith(isLoadingMInOutList: true, errorMessage: '');
    try {
      final mInOutResponse = await mInOutRepository.getMInOutListByDateRange(
          ref:ref,dates:dates, inOut: inOut);
      if (mInOutResponse.isEmpty) {
        state = state.copyWith(mInOutList: [], isLoadingMInOutList: false);
        return;
      }
      state = state.copyWith(
        mInOutList: mInOutResponse,
        isLoadingMInOutList: false,
      );
    } catch (e) {
      state = state.copyWith(
        mInOutList: [],
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoadingMInOutList: false,
      );
    }
  }

  Future<List<MInOutConfirm>> getMInOutConfirmList(
      int mInOutId,
      WidgetRef ref,
      ) async {
    try {
      final mInOutConfirmResponse = await mInOutRepository.getMInOutConfirmList(
        mInOutId,
        ref,
      );
      if (mInOutConfirmResponse.isEmpty) {
        return [];
      }
      return mInOutConfirmResponse;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }
  Future<void> getMovementListByDateRange(
      {required DateTimeRange dates,required String inOut, required WidgetRef ref}) async {
    state = state.copyWith(isLoadingMInOutList: true, errorMessage: '');
    try {
      final mInOutResponse = await mInOutRepository.getMovementListByDateRange(
          ref,dates:dates, inOut: inOut);
      if (mInOutResponse.isEmpty) {
        state = state.copyWith(mInOutList: [], isLoadingMInOutList: false);
        return;
      }
      state = state.copyWith(
        mInOutList: mInOutResponse,
        isLoadingMInOutList: false,
      );
    } catch (e) {
      state = state.copyWith(
        mInOutList: [],
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoadingMInOutList: false,
      );
    }
  }

  Future<void> getMovementList(WidgetRef ref) async {
    debugPrint('getMovementList');
    state = state.copyWith(isLoadingMInOutList: true, errorMessage: '');
    final mInOutType = ref.read(mInOutProvider).mInOutType;
    try {
      final mInOutResponse = await mInOutRepository.getMovementList(ref);
      ref.read(loadedMInOutListProvider(mInOutType).notifier).state = mInOutResponse;
      if (mInOutResponse.isEmpty) {
        state = state.copyWith(mInOutList: [], isLoadingMInOutList: false);
        return;
      }
      state = state.copyWith(
        mInOutList: mInOutResponse,
        isLoadingMInOutList: false,
      );
    } catch (e) {
      state = state.copyWith(
        mInOutList: [],
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoadingMInOutList: false,
      );
    }
  }

  Future<List<MInOutConfirm>> getMovementConfirmList(

      int movementId,
      WidgetRef ref,
      ) async {
    debugPrint('getMovementConfirmList');
    try {
      final mInOutConfirmResponse = await mInOutRepository
          .getMovementConfirmList(movementId, ref);
      if (mInOutConfirmResponse.isEmpty) {
        return [];
      }
      return mInOutConfirmResponse;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return [];
    }
  }

  void onDocChange(String value) {
    if (value.trim().isNotEmpty) {
      state = state.copyWith(doc: value, errorMessage: '');
    }
  }

  Future<MInOut> getMInOutAndLine(WidgetRef ref) async {
    print('------------mInOutTypegetMInOutAndLine ${state.mInOutType}');
    if (state.doc.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Por favor ingrese un número de documento válido',
      );
      throw Exception('Por favor ingrese un número de documento válido');
    }
    final bool isConfirm = isMInOutConfirmType(state.mInOutType);
    state = state.copyWith(
      isLoading: true,
      viewMInOut: true,
      errorMessage: '',
    );

    try {
      final mInOutResponse = await mInOutRepository.getMInOut(state.doc, ref);
      final filteredLines = mInOutResponse.lines
          .where((line) => line.mProductId?.id != null)
          .toList();
      if (state.mInOutType == MInOutType.shipment ||
           state.mInOutType == MInOutType.receipt) {
        for (int i = 0; i < filteredLines.length; i++) {
          filteredLines[i] = filteredLines[i].copyWith(
            targetQty: filteredLines[i].movementQty,
            verifiedStatus: 'pending',
          );
        }
      }
      final newMInOut = mInOutResponse.copyWith(lines: filteredLines,allLines: mInOutResponse.lines);
      if(isConfirm){
        state = state.copyWith(
          viewMInOut: false,
          mInOut: newMInOut,

        );
      } else {
        state = state.copyWith(
          viewMInOut: true ,
          mInOut: newMInOut,
          isLoading: false,
          errorMessage: '',
        );
      }

      return mInOutResponse;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
        viewMInOut: false,
      );
      print('mInOutResponse Exception: ${e.toString()} ${state.doc}');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<MInOutConfirm> getMInOutConfirmAndLine(
      int mInOutConfirmId,
      WidgetRef ref,
      ) async {
    state = state.copyWith(isLoading: true, viewMInOut: true, errorMessage: '');
    try {
      final mInOutConfirmResponse = await mInOutRepository.getMInOutConfirm(
        mInOutConfirmId,
        ref,
      );

      final updatedLines = state.mInOut!.lines.map((line) {
        final matchingConfirmLine = mInOutConfirmResponse.linesConfirm
            .firstWhere(
              (confirmLine) =>
          confirmLine.mInOutLineId!.id.toString() == line.id.toString(),
          orElse: () => LineConfirm(id: -1),
        );
        return line.copyWith(
          confirmId: matchingConfirmLine.id! > 0
              ? matchingConfirmLine.id
              : null,
          targetQty: matchingConfirmLine.targetQty,
          confirmedQty: matchingConfirmLine.confirmedQty,
          scrappedQty: matchingConfirmLine.scrappedQty,
        );
      }).toList();

      final filteredLines = updatedLines
          .where((line) => line.confirmId != null)
          .toList();

      state = state.copyWith(
        mInOutConfirm: mInOutConfirmResponse,
        mInOut: state.mInOut!.copyWith(lines: filteredLines),
        isLoading: false,
      );
      return mInOutConfirmResponse;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
        viewMInOut: false,
      );
      throw Exception(e.toString());
    }
  }

  Future<MInOut> getMovementAndLine(WidgetRef ref) async {
    final req = DateTime.now().microsecondsSinceEpoch;
    debugPrint('[$req] START getMovementAndLine doc=${state.doc} type=${state.mInOutType}');
    debugPrint('getMovementAndLine');
    if (state.doc.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Por favor ingrese un número de documento válido',
      );
      throw Exception('Por favor ingrese un número de documento válido');
    }
    state = state.copyWith(
      isLoading: true,
      viewMInOut: false,
      errorMessage: '',
    );

    try {
      final mInOutResponse = await mInOutRepository.getMovement(state.doc, ref);
      debugPrint('[$req] AFTER await getMovement lines=${mInOutResponse.lines.length}');
      final total = mInOutResponse.lines.length;
      final nullProd = mInOutResponse.lines.where((l) => l.mProductId?.id == null).length;
      final withProd = total - nullProd;

      debugPrint('[getMovementAndLine] doc=${state.doc} total=$total withProd=$withProd nullProd=$nullProd');

      // (Opcional) imprime cuáles son las líneas “sin productId”
      final bad = mInOutResponse.lines
          .where((l) => l.mProductId?.id == null)
          .map((l) => 'id=${l.id} line=${l.line} upc=${(l.upc ?? '').trim()}')
          .toList();

      debugPrint('[getMovementAndLine] null productId lines: ${bad.length}');
      for (final s in bad.take(20)) {
        debugPrint('  - $s');
      }


      var filteredLines = mInOutResponse.lines
          .where((line) => line.mProductId?.id != null)
          .toList();
      debugPrint('[$req] FILTER total=$total nullProd=$nullProd filtered=${filteredLines.length}');

      if (state.mInOutType == MInOutType.move) {
        for (int i = 0; i < filteredLines.length; i++) {
          filteredLines[i] = filteredLines[i].copyWith(
            targetQty: filteredLines[i].movementQty,
            verifiedStatus: 'pending',
          );
        }
      }

      final newMInOut = mInOutResponse.copyWith(
        lines: filteredLines,
        allLines: mInOutResponse.lines,
      );
      debugPrint('[$req] BEFORE setState filtered=${filteredLines.length} all=${mInOutResponse.lines.length}');

      if (state.mInOutType == MInOutType.move) {
        state = state.copyWith(
          viewMInOut: true,
          mInOut: newMInOut,
          isLoading: false,
          errorMessage: '',
        );
      }

      debugPrint('[$req] END OK state.lines=${state.mInOut?.lines.length} state.allLines=${state.mInOut?.allLines.length}');
      return newMInOut;


    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
        viewMInOut: false,
      );
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
  Future<MInOutConfirm> getMovementConfirmAndLine(
      int movementConfirmId,
      WidgetRef ref,
      ) async {
    debugPrint('getMovementConfirmAndLine $movementConfirmId');

    state = state.copyWith(isLoading: true, viewMInOut: true, errorMessage: '');

    try {
      final mInOutConfirmResponse = await mInOutRepository.getMovementConfirm(
        movementConfirmId,
        ref,
      );

      final current = state.mInOut;
      if (current == null) {
        throw Exception('mInOut is null');
      }

      // Fuente de verdad: SIEMPRE allLines
      final baseAllLines = current.allLines;

      // Index para evitar O(n^2)
      final confirmByMovementLineId = <String, LineConfirm>{};
      for (final c in mInOutConfirmResponse.linesConfirm) {
        final key = c.mMovementLineId?.id?.toString();
        if (key != null) confirmByMovementLineId[key] = c;
      }

      // Actualiza TODAS las líneas (allLines)
      final updatedAll = baseAllLines.map((line) {
        final key = line.id?.toString();
        final matching = (key == null) ? null : confirmByMovementLineId[key];

        return line.copyWith(
          confirmId: (matching?.id != null && (matching!.id! > 0)) ? matching.id : null,
          targetQty: matching?.targetQty,
          confirmedQty: matching?.confirmedQty,
          scrappedQty: matching?.scrappedQty,
        );
      }).toList();

      // Lista operativa para pantalla confirm: solo las que tienen confirmId
      final confirmLines = updatedAll.where((l) => l.confirmId != null).toList();

      state = state.copyWith(
        mInOutConfirm: mInOutConfirmResponse,
        mInOut: current.copyWith(
          allLines: updatedAll,      // ✅ siempre completa y actualizada
          lines: confirmLines,       // ✅ subset para UI de confirm
        ),
        isLoading: false,
      );

      debugPrint(
        'mInOutConfirmResponse line confirm ${mInOutConfirmResponse.id} '
            'linesConfirm=${mInOutConfirmResponse.linesConfirm.length} '
            'state.lines=${state.mInOut?.lines.length} state.allLines=${state.mInOut?.allLines.length}',
      );
// Actualiza provider de "sin confirmId"
      updateLinesWithoutConfirmId(ref, updatedAll);

      return mInOutConfirmResponse;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
        viewMInOut: false,
      );
      throw Exception(e.toString());
    }
  }


  /* Future<MInOutConfirm> getMovementConfirmAndLine(

    int movementConfirmId,
    WidgetRef ref,
  ) async {
    print('getMovementConfirmAndLine $movementConfirmId');
    state = state.copyWith(isLoading: true, viewMInOut: true, errorMessage: '');
    try {
      final mInOutConfirmResponse = await mInOutRepository.getMovementConfirm(
        movementConfirmId,
        ref,
      );

      final updatedLines = state.mInOut!.lines.map((line) {
        final matchingConfirmLine = mInOutConfirmResponse.linesConfirm
            .firstWhere(
              (confirmLine) =>
                  confirmLine.mMovementLineId!.id.toString() ==
                  line.id.toString(),
              orElse: () => LineConfirm(id: -1),
            );
        return line.copyWith(
          confirmId: matchingConfirmLine.id! > 0
              ? matchingConfirmLine.id
              : null,
          targetQty: matchingConfirmLine.targetQty,
          confirmedQty: matchingConfirmLine.confirmedQty,
          scrappedQty: matchingConfirmLine.scrappedQty,
        );
      }).toList();

      final filteredLines = updatedLines
          .where((line) => line.confirmId != null)
          .toList();

      state = state.copyWith(
        mInOutConfirm: mInOutConfirmResponse,
        mInOut: state.mInOut!.copyWith(lines: filteredLines,allLines: state.mInOut!.lines),
        isLoading: false,
      );
      print('mInOutConfirmResponse ${mInOutConfirmResponse.id} ${mInOutConfirmResponse.linesConfirm.length}');
      return mInOutConfirmResponse;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
        viewMInOut: false,
      );
      throw Exception(e.toString());
    }
  }*/

  void clearMInOutData() {
    print('>>>clearMInOutData');
    state = state.copyWith(
      doc: '',
      mInOut: state.mInOut?.copyWith(id: null, lines: null),
      mInOutList: [],
      mInOutConfirm: state.mInOutConfirm?.copyWith(
        id: null,
        linesConfirm: null,
      ),
      //isSOTrx: false,
      scanBarcodeListTotal: [],
      scanBarcodeListUnique: [],
      linesOver: [],
      viewMInOut: false,
      uniqueView: false,
      orderBy: 'line',
      errorMessage: '',
      isLoading: false,
      isComplete: false,
    );
  }

  void onManualQuantityChange(String value) {
    final double parsedValue = double.tryParse(value) ?? 0;
    state = state.copyWith(manualQty: parsedValue);
  }

  void onManualScrappedChange(String value) {
    final double parsedValue = double.tryParse(value) ?? 0;
    state = state.copyWith(scrappedQty: parsedValue.toDouble());
  }

  void confirmManualLine(BuildContext context, WidgetRef ref,Line line) {
    debugPrint('confirmManualLine');


    line = line.copyWith(verifiedStatus: 'manually');
    final List<Line> updatedLines = state.mInOut!.lines;
    final int index = updatedLines.indexWhere((l) => l.id == line.id);
    if (index != -1) {

      final Line verifyLine = _verifyLineStatusQty(
        line,
        line.scanningQty?.toDouble() ?? 0.0,
        state.manualQty,
        state.scrappedQty,
      );
      updatedLines[index] = verifyLine;
      state = state.copyWith(
        mInOut: state.mInOut!.copyWith(lines: updatedLines),
      );
      saveMInOutSilence();
      updatedMInOutLine('');
    } else {
      showWarningMessage(
        context,
        ref,
        'Error al confirmar la línea ${line.line}\nManulQty:${state.manualQty} \nScrappedQty:${state.scrappedQty}',
      );
    }

  }

  void resetManualLine(Line line) {
    final List<Line> updatedLines = state.mInOut!.lines;
    final int index = updatedLines.indexWhere((l) => l.id == line.id);
    if (index != -1) {
      updatedLines[index] = line.copyWith(
        manualQty: 0,
        confirmedQty: 0,
        scrappedQty: 0,
        verifiedStatus: 'pending',
      );
      state = state.copyWith(
        mInOut: state.mInOut!.copyWith(lines: updatedLines),
      );
      saveMInOutSilence();
      updatedMInOutLine('');
    }
  }

  void onEditLocatorChange(String value) {
    state = state.copyWith(editLocator: value, errorMessage: '');
  }

  Future<void> confirmEditLocator(Line line, WidgetRef ref) async {
    String locator = line.mLocatorId!.identifier!.split(' => ').first.trim();

    try {


      final updatedLocator = line.mLocatorId?.copyWith(
        identifier: '$locator => ${state.editLocator}',
      );
      final updatedLine = line.copyWith(
        mLocatorId: updatedLocator,
      );
      final updatedLines = state.mInOut!.lines
          .map((l) => l.id == line.id ? updatedLine : l)
          .toList();
      state = state.copyWith(
        mInOut: state.mInOut!.copyWith(lines: updatedLines),
      );
      saveMInOutSilence();
      updatedMInOutLine('');
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al actualizar la ubicación: ${e.toString()}',
      );
    }
  }

  bool isRolComplete() {
    if (state.mInOutType == MInOutType.shipment ||
        state.mInOutType == MInOutType.receipt) {
      if (state.mInOut?.docStatus.id.toString() == 'DR' &&
          (state.rolPrepare || state.rolComplete)) {
        return true;
      } else if (state.mInOut?.docStatus.id.toString() == 'IP' &&
          state.rolComplete) {
        return true;
      } else {
        return false;
      }
    } else {
      if (state.rolComplete) {
        return true;
      } else {
        return false;
      }
    }
  }

  bool isConfirmMInOut() {
    /*print(
      'isConfirmMInOut',
    );
    if (((state.mInOutType == MInOutType.shipment ||
        state.mInOutType == MInOutType.receipt) &&
        state.mInOut?.docStatus.id.toString() == 'IP') ||
        state.mInOutType == MInOutType.move) {

      return true;
    }
    print(
      'state.rolQuickComplete ${state.rolQuickComplete}',
    );
*/
    final validStatuses = {
      'correct',
      'manually-correct',
      if (state.rolCompleteLow) 'minor',
      if (state.rolCompleteLow) 'manually-minor',
      if (state.rolCompleteOver) 'over',
      if (state.rolCompleteOver) 'manually-over',
    };
    return state.mInOut?.lines.every(
          (line) =>
      line.verifiedStatus != 'pending' &&
          validStatuses.contains(line.verifiedStatus),
    ) ??
        false;
  }


  Future<void> setDocAction(WidgetRef ref) async {
    final messageConfirm = '${Messages.COMFIRM} ${state.title}?';
    final bool? ok = await showConfirmationDialog(ref.context, ref, messageConfirm);
    if (ok == null || !ok) return;

    // UI loading switch to false, using other progress indicator
    state = state.copyWith(isLoading: false, errorMessage: '');

    final currentM = state.mInOut;
    if (currentM == null) {
      state = state.copyWith(isLoading: false, errorMessage: 'mInOut is null');
      return;
    }

    final progress = ref.read(actionProgressProvider.notifier);
    progress.start(message: 'Preparando operación...');
    await openProgressIfNeeded(ref);

    final List<Line> sourceLines = currentM.lines;

    final Set<int> movementLineIdsToUpdate = <int>{};
    final Map<int, double> movementConfirmedQtyByLineId = <int, double>{};
    int step = 1;
    try {

      progress.setStep(0, 'Analizando líneas a actualizar...');
      final List<Line> listLinesToUpdateMovementQty = [];

      for (final line in sourceLines) {
        final movementQty = line.movementQty;
        final confirmedQty = line.confirmedQty;

        final bool editQty = movementQty != null &&
            confirmedQty != null &&
            movementQty != confirmedQty;


        if (editQty) {
          listLinesToUpdateMovementQty.add(line);

          final id = line.id;
          if (id != null) {
            movementLineIdsToUpdate.add(id);
            movementConfirmedQtyByLineId[id] = confirmedQty;
          }
        }

      }

      final List<int> listIdsToUpdateMovementQty = movementLineIdsToUpdate.toList();

      // ---------------------------------------------------------
      // 1) Update movement lines qty
      // ---------------------------------------------------------

      debugPrint('setDocAction 1: ${state.isLoading}');
      if (sourceLines.isNotEmpty) {
        progress.setStep(1, 'Actualizando cantidades en líneas de movimiento...');
        for (final line in sourceLines) {
          await mInOutRepository.updateMInOutLineMovementQty(line, ref);
        }
      } else {
        // Igual avanzamos, para que el usuario vea que pasó esa etapa.
        progress.setStep(1, 'No hay líneas de movimiento para actualizar.');
      }

      // ---------------------------------------------------------
      // 2) Get draft confirms excluding current confirm
      // ---------------------------------------------------------
      step++;
      debugPrint('setDocAction 2: ${state.isLoading}');
      final int? mInOutId = state.mInOut?.id;
      final int currentConfirmId = state.mInOutConfirm?.id ?? -1;

      List<MInOutConfirm> confirmListDraft = [];
      if (mInOutId != null) {
        progress.setStep(2, 'Obteniendo confirms en borrador (excluyendo el actual)...');
        confirmListDraft = await mInOutRepository.getMInOutConfirmInDraftByMInOutID(
          mInOutId: mInOutId,
          excludedMInOutConfirmId: currentConfirmId,
          ref: ref,
        );
      } else {
        progress.setStep(2, 'Saltando borradores (faltan IDs de documento/confirm).');
      }

      // ---------------------------------------------------------
      // 3) Get LineConfirm rows to update by confirmIds + mInOutLineIds
      // ---------------------------------------------------------
      step++;
      debugPrint('setDocAction 3: ${state.isLoading}');
      final List<int> listConfirmsIds = confirmListDraft
          .map((c) => c.id)
          .whereType<int>()
          .toList();

      List<LineConfirm> listLinesToUpdateTargetQty = [];
      if (listConfirmsIds.isNotEmpty && listIdsToUpdateMovementQty.isNotEmpty) {
        progress.setStep(3, 'Buscando líneas LineConfirm a actualizar (draft confirms)...');
        listLinesToUpdateTargetQty =
        await mInOutRepository.getLinesMInOutConfirmToUpdateTargetQty(
          listConfirmsIds: listConfirmsIds,
          mInOutLineIds: listIdsToUpdateMovementQty,
          ref: ref,
        );
      } else {
        progress.setStep(3, 'No hay LineConfirm para actualizar (sin confirms o sin líneas editadas).');
      }
      debugPrint(
          'setDocActionConfirm listLinesToUpdateTargetQty.length = ${listLinesToUpdateTargetQty.length}');
      // ---------------------------------------------------------
      // 4) Update LineConfirm rows with new targetQty / confirmedQty from movement
      // ---------------------------------------------------------
      step++;
      debugPrint('setDocAction 4: ${state.isLoading}');
      if (listLinesToUpdateTargetQty.isNotEmpty) {
        progress.setStep(4, 'Actualizando LineConfirm en borradores (target/confirmed)...');

        // Copia confirmedQty desde movement
        for (final lc in listLinesToUpdateTargetQty) {
          final lineId = int.tryParse(lc.mInOutLineId?.id ?? '');
          if (lineId == null) continue;

          final confirmedQtyFromMovement = movementConfirmedQtyByLineId[lineId];
          if (confirmedQtyFromMovement == null) continue;

          lc.confirmedQty = confirmedQtyFromMovement;
        }

        for (final lc in listLinesToUpdateTargetQty) {
          await mInOutRepository.updateLineConfirmTargetQty(lc, ref);
        }
      } else {
        progress.setStep(4, 'No hay borradores LineConfirm para actualizar.');
      }
      debugPrint('setDocAction 5: ${state.isLoading}');

      // ---------------------------------------------------------
      // 5) SetDocAction confirm
      // ---------------------------------------------------------
      step++;
      progress.setStep(5, 'Confirmando documento (SetDocAction)...');
      final result = await mInOutRepository.setDocAction(ref);

      progress.finish(message: 'Completado ✅');
      debugPrint('setDocActionConfirm finish: ${state.isLoading}');

      state = state.copyWith(
        mInOut: result,
        errorMessage: '',
        isLoading: false,
        isComplete: true,
      );

      if (result.documentNo != null && result.documentNo!.isNotEmpty) {
        removeSavedMInOutData(ref);
      }
      closeProgressDialogSafe(ref);
      await showMInOutResultModalBottomSheet(
        ref: ref,
        data: result,
        type: state.mInOutType,
      );
    } catch (e) {
      debugPrint('setDocAction error $step: ${e.toString()}');
      final msg = e.toString().replaceAll('Exception: ', '');
      closeProgressDialogSafe(ref);
      state = state.copyWith(
        errorMessage: '',
        isLoading: false,
      );

      if (ref.context.mounted) {
        showErrorMessage(durationSeconds: 0, ref.context, ref, msg);
      }
    } finally {
      // Limpieza del provider (opcional)

      ref.read(actionProgressProvider.notifier).hide();
    }
  }
  Future<void> setDocActionConfirm(WidgetRef ref) async {
    final messageConfirm = '${Messages.COMFIRM} ${state.title}?';
    final bool? ok = await showConfirmationDialog(ref.context, ref, messageConfirm);
    if (ok == null || !ok) return;

    // UI loading switch to false, using other progress indicator
    state = state.copyWith(isLoading: false, errorMessage: '');

    final currentM = state.mInOut;
    if (currentM == null) {
      state = state.copyWith(isLoading: false, errorMessage: 'mInOut is null');
      return;
    }

    final progress = ref.read(actionProgressProvider.notifier);
    progress.start(message: 'Preparando operación...');
    await openProgressIfNeeded(ref);

    final List<Line> sourceLines = currentM.lines;

    final Set<int> movementLineIdsToUpdate = <int>{};
    final Map<int, double> movementConfirmedQtyByLineId = <int, double>{};
    int step =1;
    try {


      progress.setStep(0, 'Analizando líneas a actualizar...');
      final List<Line> listLinesToUpdateMovementQty = [];


      for (final line in sourceLines) {
        final movementQty = line.movementQty;
        final confirmedQty = line.confirmedQty;

        final bool editQty = movementQty != null &&
            confirmedQty != null &&
            movementQty != confirmedQty;



        if (editQty) {
          listLinesToUpdateMovementQty.add(line);

          final id = line.id;
          if (id != null) {
            movementLineIdsToUpdate.add(id);
            movementConfirmedQtyByLineId[id] = confirmedQty;

          }
        }

      }


      debugPrint('setDocActionConfirm 1: ${state.isLoading}');
      final List<int> listIdsToUpdateMovementQty = movementLineIdsToUpdate.toList();
      // ---------------------------------------------------------
      // 1) Update movement lines qty
      // ---------------------------------------------------------
      if (listLinesToUpdateMovementQty.isNotEmpty) {
        progress.setStep(1, 'Actualizando cantidades en líneas de movimiento...');
        for (final line in listLinesToUpdateMovementQty) {
          await mInOutRepository.updateMInOutLineMovementQty(line, ref);
        }
      } else {
        // Igual avanzamos, para que el usuario vea que pasó esa etapa.
        progress.setStep(1, 'No hay líneas de movimiento para actualizar.');
      }

      // ---------------------------------------------------------
      // 2) Get draft confirms excluding current confirm
      // ---------------------------------------------------------
      step++;
      final int? mInOutId = state.mInOut?.id;
      final int? currentConfirmId = state.mInOutConfirm?.id;
      debugPrint('setDocActionConfirm 2: ${state.isLoading}');
      List<MInOutConfirm> confirmListDraft = [];
      if (mInOutId != null && currentConfirmId != null) {
        progress.setStep(2, 'Obteniendo confirms en borrador (excluyendo el actual)...');
        confirmListDraft = await mInOutRepository.getMInOutConfirmInDraftByMInOutID(
          mInOutId: mInOutId,
          excludedMInOutConfirmId: currentConfirmId,
          ref: ref,
        );
      } else {
        progress.setStep(2, 'Saltando borradores (faltan IDs de documento/confirm).');
      }

      // ---------------------------------------------------------
      // 3) Get LineConfirm rows to update by confirmIds + mInOutLineIds
      // ---------------------------------------------------------
      step++;
      debugPrint('setDocActionConfirm 3: ${state.isLoading}');
      final List<int> listConfirmsIds = confirmListDraft
          .map((c) => c.id)
          .whereType<int>()
          .toList();

      List<LineConfirm> listLinesToUpdateTargetQty = [];
      if (listConfirmsIds.isNotEmpty && listIdsToUpdateMovementQty.isNotEmpty) {
        progress.setStep(3, 'Buscando líneas LineConfirm a actualizar (draft confirms)...');
        listLinesToUpdateTargetQty =
        await mInOutRepository.getLinesMInOutConfirmToUpdateTargetQty(
          listConfirmsIds: listConfirmsIds,
          mInOutLineIds: listIdsToUpdateMovementQty,
          ref: ref,
        );
      } else {
        progress.setStep(3, 'No hay LineConfirm para actualizar (sin confirms o sin líneas editadas).');
      }
      debugPrint(
        'setDocActionConfirm listLinesToUpdateTargetQty.length = ${listLinesToUpdateTargetQty.length}');
      // ---------------------------------------------------------
      // 4) Update LineConfirm rows with new targetQty / confirmedQty from movement
      // ---------------------------------------------------------
      step++;
      debugPrint('setDocActionConfirm 4: ${state.isLoading}');
      if (listLinesToUpdateTargetQty.isNotEmpty) {
        progress.setStep(4, 'Actualizando LineConfirm en borradores (target/confirmed)...');

        // Copia confirmedQty desde movement
        for (final lc in listLinesToUpdateTargetQty) {
          final lineId = int.tryParse(lc.mInOutLineId?.id ?? '');
          if (lineId == null) continue;

          final confirmedQtyFromMovement = movementConfirmedQtyByLineId[lineId];
          if (confirmedQtyFromMovement == null) continue;

          lc.confirmedQty = confirmedQtyFromMovement;
        }

        for (final lc in listLinesToUpdateTargetQty) {
          await mInOutRepository.updateLineConfirmTargetQty(lc, ref);
        }
      } else {
        progress.setStep(4, 'No hay borradores LineConfirm para actualizar.');
      }

      // ---------------------------------------------------------
      // 5) Update current confirm lines with new confirmedQty
      // ---------------------------------------------------------
      step++;
      debugPrint('setDocActionConfirm 5: ${state.isLoading}');
      progress.setStep(5, 'Actualizando líneas del confirm actual...');
      for (final line in currentM.lines) {
        final lineConfirmResponse = await mInOutRepository.updateLineConfirm(line, ref);
        if (lineConfirmResponse.id == null) {
          throw Exception('Error al confirmar la línea ${line.line}');
        }
      }
      step++;
      debugPrint('setDocActionConfirm 6: ${state.isLoading}');
      // ---------------------------------------------------------
      // 6) SetDocAction confirm
      // ---------------------------------------------------------
      progress.setStep(6, 'Confirmando documento (SetDocAction)...');
      final result = await mInOutRepository.setDocActionConfirm(ref);

      progress.finish(message: 'Completado ✅');
      debugPrint('setDocActionConfirm finish: ${state.isLoading}');

      state = state.copyWith(
        mInOutConfirm: result,
        errorMessage: '',
        isLoading: false,
        isComplete: true,
      );

      if (result.documentNo != null && result.documentNo!.isNotEmpty) {
        removeSavedMInOutData(ref);
      }
      closeProgressDialogSafe(ref);
      await showMInOutConfirmResultModalBottomSheet(
        ref: ref,
        data: result,
        type: state.mInOutType,
      );
    } catch (e) {
      debugPrint('setDocActionConfirm error $step: ${e.toString()}');
      final msg = e.toString().replaceAll('Exception: ', '');
      closeProgressDialogSafe(ref);
      state = state.copyWith(
        errorMessage: '',
        isLoading: false,
      );

      if (ref.context.mounted) {
        showErrorMessage(durationSeconds: 0, ref.context, ref, msg);
      }
    } finally {
      // Limpieza del provider (opcional)

      ref.read(actionProgressProvider.notifier).hide();
    }
  }

  Future<void> setDocActionConfirmOld2(WidgetRef ref) async {
    String message = '${Messages.COMFIRM} ${state.title}?';
    bool? result = await showConfirmationDialog(ref.context, ref, message);
    debugPrint('setDocActionConfirm started $result');
    if(result == null || !result) return;

    // EN: Switch UI into loading state and clear previous errors


    state = state.copyWith(isLoading: false, errorMessage: '');
    debugPrint('setDocActionConfirm started');

    final currentM = state.mInOut;
    if (currentM == null) {
      state = state.copyWith(isLoading: false, errorMessage: 'mInOut is null');
      return;
    }

    // EN: Use ONLY currentM.lines as requested
    final List<Line> sourceLines = currentM.lines;

    // EN: Track which movement lineIds need updates (targetQty != confirmedQty)
    final Set<int> movementLineIdsToUpdate = <int>{};

    // EN: Map movement lineId -> confirmedQty (source of truth for draft confirm updates)
    final Map<int, double> movementConfirmedQtyByLineId = <int, double>{};

    try {
      // ---------------------------------------------------------------------
      // 1) EN: Build list of movement lines where targetQty != confirmedQty
      //     and update MInOutLine rows (movement qty update).
      // ---------------------------------------------------------------------
      final List<Line> listLinesToUpdateMovementQty = [];

      for (final line in sourceLines) {
        final movementQty = line.movementQty;
        final confirmedQty = line.confirmedQty;
        bool editQty = movementQty != null &&
            confirmedQty != null &&
            movementQty != confirmedQty ;
        bool editLocator = line.editLocator != null;

        if (editQty || editLocator) {
          listLinesToUpdateMovementQty.add(line);

          final id = line.id;
          if (id != null) {
            movementLineIdsToUpdate.add(id);
            if(confirmedQty != null) movementConfirmedQtyByLineId[id] = confirmedQty; // <-- capture confirmedQty
          }
        }
      }

      debugPrint(
        'setDocActionConfirm listLinesToUpdateMovementQty.length = ${listLinesToUpdateMovementQty.length}',
      );

      // EN: Pre-build IDs list for repository calls
      final List<int> listIdsToUpdateMovementQty = movementLineIdsToUpdate.toList();
      debugPrint(
        'setDocActionConfirm listIdsToUpdateMovementQty.length = ${listIdsToUpdateMovementQty.length}',
      );

      if (listLinesToUpdateMovementQty.isNotEmpty) {
        // 1.1) EN: Update movement lines first
        for (final line in listLinesToUpdateMovementQty) {
          try {
            await mInOutRepository.updateMInOutLineMovementQty(line, ref);
          } catch (e) {
            final msg =
                'UpdateMovementQty: Error al actualizar cantidad en línea ${line.line}: ${e.toString()}';
            debugPrint('setDocActionConfirm preUpdate(1) error: $msg');

            state = state.copyWith(isLoading: false, errorMessage: msg);
            if (ref.context.mounted) showErrorMessage(durationSeconds: 0, ref.context, ref, msg);
            return;
          }
        }

        // -------------------------------------------------------------------
        // 2) EN: NEW FLOW (from confirmList via repository)
        //     - Get drafts confirms excluding current confirm
        //     - Extract confirm IDs
        //     - Ask backend for LineConfirm rows to update by confirmIds + mInOutLineIds
        //     - Copy confirmedQty(from movement) -> LineConfirm.confirmedQty
        //     - Update via updateLineConfirmTargetQty
        // -------------------------------------------------------------------
        final int? mInOutId = state.mInOut?.id;
        final int? currentConfirmId = state.mInOutConfirm?.id;

        if (mInOutId != null && currentConfirmId != null) {
          List<MInOutConfirm> confirmListDraft = [];
          try {
            confirmListDraft =
            await mInOutRepository.getMInOutConfirmInDraftByMInOutID(
              mInOutId: mInOutId,
              excludedMInOutConfirmId: currentConfirmId,
              ref: ref,
            );
          } catch (e) {
            final msg =
                'GetDraftConfirms: Error al obtener confirms draft: ${e.toString()}';
            debugPrint('setDocActionConfirm preUpdate(2) error: $msg');

            state = state.copyWith(isLoading: false, errorMessage: msg);
            if (ref.context.mounted) showErrorMessage(durationSeconds: 0, ref.context, ref, msg);
            return;
          }

          debugPrint(
            'setDocActionConfirm confirmListDraft.length = ${confirmListDraft.length}',
          );

          final List<int> listConfirmsIds = confirmListDraft
              .map((c) => c.id)
              .whereType<int>()
              .toList();

          debugPrint(
            'setDocActionConfirm listConfirmsIds.length = ${listConfirmsIds.length}',
          );

          if (listConfirmsIds.isNotEmpty && listIdsToUpdateMovementQty.isNotEmpty) {
            List<LineConfirm> listLinesToUpdateTargetQty = [];
            try {
              listLinesToUpdateTargetQty =
              await mInOutRepository.getLinesMInOutConfirmToUpdateTargetQty(
                listConfirmsIds: listConfirmsIds,
                mInOutLineIds: listIdsToUpdateMovementQty,
                ref: ref,
              );
            } catch (e) {
              final msg =
                  'GetLinesToUpdateTargetQty: Error al obtener líneas confirm a actualizar: ${e.toString()}';
              debugPrint('setDocActionConfirm preUpdate(3) error: $msg');

              state = state.copyWith(isLoading: false, errorMessage: msg);
              if (ref.context.mounted) showErrorMessage(durationSeconds: 0, ref.context, ref, msg);
              return;
            }

            debugPrint(
              'setDocActionConfirm listLinesToUpdateTargetQty.length = ${listLinesToUpdateTargetQty.length}',
            );

            if (listLinesToUpdateTargetQty.isNotEmpty) {
              // EN: Copy confirmedQty from movement -> LineConfirm.confirmedQty
              for (final lc in listLinesToUpdateTargetQty) {
                final lineId = int.tryParse(lc.mInOutLineId?.id ?? '');
                if (lineId == null) continue;

                final confirmedQtyFromMovement = movementConfirmedQtyByLineId[lineId];
                if (confirmedQtyFromMovement == null) continue;

                lc.confirmedQty = confirmedQtyFromMovement;
              }

              // EN: Update each LineConfirm
              for (final lineConfirm in listLinesToUpdateTargetQty) {
                try {
                  await mInOutRepository.updateLineConfirmTargetQty(lineConfirm, ref);
                } catch (e) {
                  final msg =
                      'UpdateLineConfirmTargetQty: Error al actualizar targetQty en LineConfirm (lineId: ${lineConfirm.mInOutLineId?.id}): ${e.toString()}';
                  debugPrint('setDocActionConfirm preUpdate(4) error: $msg');

                  state = state.copyWith(isLoading: false, errorMessage: msg);
                  if (ref.context.mounted) showErrorMessage(durationSeconds: 0, ref.context, ref, msg);
                  return;
                }
              }
            }
          }
        }
      }

      // ---------------------------------------------------------------------
      // EN: Normal confirmation flow (unchanged)
      // ---------------------------------------------------------------------
      for (final line in currentM.lines) {

        final lineConfirmResponse =
        await mInOutRepository.updateLineConfirm(line, ref);

        if (lineConfirmResponse.id == null) {
          state = state.copyWith(
            errorMessage: 'Error al confirmar la línea ${line.line}',
            isLoading: false,
          );
          return;
        }
      }

      debugPrint('setDocActionConfirm setDocAction');
      late MInOutConfirm result;

      try {
        result = await mInOutRepository.setDocActionConfirm(ref);
        debugPrint('setDocActionConfirm result ${result.docStatus.toJson()}');
      } catch (e) {
        debugPrint('setDocActionConfirm Error: ${e.toString()}');
        if (ref.context.mounted) showErrorMessage(durationSeconds: 0, ref.context, ref, e.toString());
        state = state.copyWith(isLoading: false);
        return;
      }

      state = state.copyWith(
        mInOutConfirm: result,
        errorMessage: '',
        isLoading: false,
        isComplete: true,
      );
      if(result.documentNo!=null && result.documentNo!.isNotEmpty)removeSavedMInOutData(ref);
      showMInOutConfirmResultModalBottomSheet(
        ref: ref,
        data: result,
        type: MInOutType.move,

      );
    } catch (e) {
      debugPrint('setDocActionConfirm error ${e.toString()}');
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
    }
  }

  void addBarcode(String code, BuildContext context) {
    if (code.trim().isEmpty) return;
    final List<Barcode> updatedTotalList = [...state.scanBarcodeListTotal];
    final existingBarcodes = updatedTotalList
        .where((barcode) => barcode.code == code)
        .toList();

    if (existingBarcodes.isNotEmpty) {
      final int newRepetitions = existingBarcodes.first.repetitions + 1;
      for (int i = 0; i < updatedTotalList.length; i++) {
        if (updatedTotalList[i].code == code) {
          updatedTotalList[i] = updatedTotalList[i].copyWith(
            repetitions: newRepetitions,
          );
        }
      }
      updatedTotalList.add(
        Barcode(
          index: updatedTotalList.length + 1,
          code: code,
          repetitions: newRepetitions,
          coloring: false,
        ),
      );
    } else {
      updatedTotalList.add(
        Barcode(
          index: updatedTotalList.length + 1,
          code: code,
          repetitions: 1,
          coloring: false,
        ),
      );
    }

    updatedBarcodeList(
      updatedTotalList: updatedTotalList,
      barcode: code,
      context: context,
    );
    moveScrollToBottom();
  }

  void removeBarcode({
    required Barcode barcode,
    bool isOver = false,
    required BuildContext context,
  }) {
    final int index = barcode.index - 1;
    if (index < 0 || index >= state.scanBarcodeListTotal.length) return;

    final List<Barcode> updatedTotalList = [...state.scanBarcodeListTotal];
    if (state.uniqueView || isOver) {
      updatedTotalList.removeWhere((item) => item.code == barcode.code);
    } else {
      final barcodeToRemove = updatedTotalList[index];
      updatedTotalList.removeAt(index);
      int newRepetitions = barcodeToRemove.repetitions - 1;
      for (int i = 0; i < updatedTotalList.length; i++) {
        if (updatedTotalList[i].code == barcodeToRemove.code) {
          updatedTotalList[i] = updatedTotalList[i].copyWith(
            repetitions: newRepetitions,
          );
        }
      }
    }

    final filteredTotalList = updatedTotalList
        .where((barcode) => barcode.repetitions > 0)
        .toList();
    updatedBarcodeList(
      updatedTotalList: filteredTotalList,
      barcode: barcode.code,
      context: context,
    );
    moveScrollToBottom();
  }

  void updatedBarcodeList({
    required List<Barcode> updatedTotalList,
    required String barcode,
    required BuildContext context,
  }) {
    for (int i = 0; i < updatedTotalList.length; i++) {
      updatedTotalList[i] = updatedTotalList[i].copyWith(index: i + 1);
    }

    final Map<String, Barcode> uniqueMap = {};
    for (final barcode in updatedTotalList) {
      if (!uniqueMap.containsKey(barcode.code) ||
          uniqueMap[barcode.code]!.repetitions < barcode.repetitions) {
        uniqueMap[barcode.code] = barcode.copyWith(
          repetitions: barcode.repetitions,
        );
      }
    }

    final List<Barcode> updatedUniqueList = uniqueMap.values.toList();
    for (int i = 0; i < updatedUniqueList.length; i++) {
      updatedUniqueList[i] = updatedUniqueList[i].copyWith(index: i + 1);
    }

    state = state.copyWith(
      scanBarcodeListTotal: updatedTotalList,
      scanBarcodeListUnique: updatedUniqueList,
    );
    saveMInOutSilence();
    updatedMInOutLine(barcode, context: context);
  }

  bool showUpdateScannedQuantity({
    required int scannedQty,
    required double totalMovementQty,
  }) {
    double dif = totalMovementQty - scannedQty;
    if (dif < 0) return true;
    if (totalMovementQty >
        quantityOfMovementAndScannedToAllowInputScannedQuantity) {
      if (dif <= quantityOfMovementAndScannedToAllowInputScannedQuantity) {
        return false;
      } else {
        return true;
      }
    }

    return false;
  }

  Icon getBarcodeExpressionIcon(Barcode barcode) {
    if (state.mInOut == null || state.mInOut!.lines.isEmpty) {
      return Icon(Icons.dangerous, color: Colors.red);
    }
    List<Line> lines = state.mInOut!.lines;
    List<Line> linesWithSameUPC = [];
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].upc == barcode.code) {
        linesWithSameUPC.add(lines[i]);
      }
    }
    Color color = Colors.amber[800]!;
    int qty = 0;
    for (int i = 0; i < linesWithSameUPC.length; i++) {
      qty += linesWithSameUPC[i].movementQty?.toInt() ?? 0;
    }

    if (qty == barcode.repetitions) {
      color = Colors.green;
      return Icon(Icons.check_circle, color: color);
    } else if (qty > barcode.repetitions) {
      color = Colors.amber[800]!;
      return Icon(Icons.indeterminate_check_box, color: color);
    } else {
      color = Colors.red;
      return Icon(Icons.add_box, color: color);
    }
  }

  Future<void> updatedMInOutLine(
      String barcodeString, {
        BuildContext? context,
      }) async {
    if (state.mInOut != null && state.viewMInOut) {
      String documentNo = state.mInOut!.documentNo ?? '';
      List<Line> lines = state.mInOut!.lines;
      List<Barcode> linesOver = [];
      List<Line> linesWithSameUPC = [];
      List<int> linesIndexWithSameUPC = [];
      double sumOfOtherLinesWithSameUPC = 0;
      double totalMovementQty = 0;
      Barcode? barcode;
      for (int i = 0; i < state.scanBarcodeListUnique.length; i++) {
        if (state.scanBarcodeListUnique[i].code == barcodeString) {
          barcode = state.scanBarcodeListUnique[i];
          break;
        }
      }

      bool showUpdateDialog = false;
      int qtyScanned = 0;
      int lineIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].upc == barcodeString) {
          linesWithSameUPC.add(lines[i]);
          linesIndexWithSameUPC.add(i);
        }
      }

      if (linesWithSameUPC.length == 1) {
        lineIndex = linesIndexWithSameUPC[0];
      } else {
        if (context != null && context.mounted) {
          lineIndex =
              await showDialog<int>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Seleccionar Línea'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: linesWithSameUPC.length,
                        itemBuilder: (BuildContext context, int i) {
                          final currentLine = linesWithSameUPC[i];
                          double requiredQty = currentLine.movementQty ?? 0;
                          requiredQty -= currentLine.confirmedQty ?? 0;
                          requiredQty -= currentLine.scrappedQty ?? 0;
                          String requiredQtyString = Memory.numberFormatter0Digit.format(requiredQty);
                          String movementQtyString = Memory.numberFormatter0Digit.format(currentLine.movementQty ?? 0);
                          String confirmedQtyString = Memory.numberFormatter0Digit.format(currentLine.confirmedQty ?? 0);
                          String scrappedQtyString = Memory.numberFormatter0Digit.format(currentLine.scrappedQty ?? 0);
                          String manualQtyString = Memory.numberFormatter0Digit.format(currentLine.manualQty ?? 0);
                          String scanningQtyString = Memory.numberFormatter0Digit.format(currentLine.scanningQty ?? 0);





                          return Card(
                            color: Colors.grey[200],
                            child: ListTile(
                              title: Text('Doc No: $documentNo : Línea: ${currentLine.line}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cant. Movement: $movementQtyString',
                                  ),
                                  Text(
                                    'Cant. Manual: $manualQtyString',
                                  ),
                                  Text(
                                    'Cant. Escaneada: $scanningQtyString',
                                  ),
                                  Text(
                                    'Cant. Confirmada: $confirmedQtyString',
                                  ),
                                  Text(
                                    'Cant. Desecho: $scrappedQtyString',
                                  ),
                                  Text(
                                    'Cant. Requerido: $requiredQtyString',
                                    style: TextStyle(color: Colors.purple),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pop(linesIndexWithSameUPC[i]);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop(-1);
                        },
                      ),
                    ],
                  );
                },
              ) ??
                  -1;
          if (lineIndex >= 0) {
            showUpdateDialog = true;
          }
        }
      }

      if (lineIndex < 0) return;

      Line line;
      line = lines[lineIndex];
      for (int i = 0; i < linesWithSameUPC.length; i++) {
        totalMovementQty += (linesWithSameUPC[i].movementQty ?? 0);
        if (line.id != linesWithSameUPC[i].id) {
          sumOfOtherLinesWithSameUPC += (linesWithSameUPC[i].movementQty ?? 0);
        }
      }

      int qty = 0;
      qty = line.scanningQty ?? 0;

      if (barcode != null) {
        qty = barcode.repetitions;
      }
      if (!showUpdateDialog) {
        showUpdateDialog = showUpdateScannedQuantity(
          scannedQty: qty,
          totalMovementQty: totalMovementQty,
        );
      }
      if (linesWithSameUPC.length == 1) {
        if (context != null && context.mounted) {
          final container = ProviderScope.containerOf(context, listen: false);
          final adjustScannedQty = container.read(adjustScannedQtyProvider);
          if (!adjustScannedQty) showUpdateDialog = false;
        }
      }
      if (context != null &&
          context.mounted &&
          line.movementQty != null &&
          showUpdateDialog) {
        int lastQty = qty - 1;
        final TextEditingController qtyToSumController = TextEditingController(
          text: '1',
        );
        final TextEditingController qtyController = TextEditingController(
          text: qty.toString(),
        );
        final TextEditingController lastQtyController = TextEditingController(
          text: (qty > 0 ? qty - 1 : 0).toString(),
        );

        String subtitle = 'UPC: ${line.upc ?? ''}';
        if (qty == 1) {
          String title = 'Editar : Linea : ${line.line ?? 0}';
          qty = await openSetLineScannedQuantityDialog(
            context: context,
            qtyController: qtyController,
            title: title,
            subtitle: subtitle,
            quantity: qty,
          );
        } else {
          String title = 'UPC con cantidad existente';
          String subtitle =
              '¿Desea definir una nueva cantidad o sumar a la existente?';
          String textButton1 = 'Cancelar';
          String textButton2 = 'Definir';
          String textButton3 = 'Sumar';
          final container = ProviderScope.containerOf(context, listen: false);
          final defaultAction = container.read(
            defaultActionWhenUPCIsScannedProvider,
          );
          int buttonsToShow = 2;
          if (linesWithSameUPC.length < 2) {
            buttonsToShow = 3;
          }
          switch (defaultAction) {
            case DefaultActionWhenUPCIsScanned.ask:
              String? action = await openDialogSelect3Actions(
                context: context,
                title: title,
                subtitle: subtitle,
                textButton1: textButton1,
                textButton2: textButton2,
                textButton3: textButton3,
                buttonsToShow: buttonsToShow,
              );

              if (action == textButton2) {
                if (context.mounted) {
                  String title = 'Editar : Linea : ${line.line ?? 0}';
                  qty = await openSetLineScannedQuantityDialog(
                    context: context,
                    qtyController: qtyController,
                    title: title,
                    subtitle: subtitle,
                    quantity: qty,
                  );
                }
              } else if (action == textButton3) {
                if (context.mounted) {
                  String title = 'Sumar : Linea : ${line.line ?? 0}';
                  qty = await openSumLineScannedQuantityDialog(
                    context: context,
                    lastQtyController: lastQtyController,
                    qtyToSumController: qtyToSumController,
                    resultController: qtyController,
                    title: title,
                    subtitle: subtitle,
                    lastQty: lastQty,
                  );
                }
              }
              break;
            case DefaultActionWhenUPCIsScanned.edit:
              String title = 'Editar : Linea : ${line.line ?? 0}';
              qty = await openSetLineScannedQuantityDialog(
                context: context,
                qtyController: qtyController,
                title: title,
                subtitle: subtitle,
                quantity: qty,
              );
              break;
            case DefaultActionWhenUPCIsScanned.sum:
              String title = 'Sumar : Linea : ${line.line ?? 0}';
              qty = await openSumLineScannedQuantityDialog(
                context: context,
                lastQtyController: lastQtyController,
                qtyToSumController: qtyToSumController,
                resultController: qtyController,
                title: title,
                subtitle: subtitle,
                lastQty: lastQty,
              );
              break;
            case DefaultActionWhenUPCIsScanned.ignore:
            // No abrir nada, sólo registrar / loguear
              break;
          }
        }

        if (qty > 0) {
          qtyScanned = qty;
          if (barcode != null) {
            barcode.repetitions = qty + sumOfOtherLinesWithSameUPC.toInt();
            print('------- Repetitions ${barcode.repetitions}');
          }
          for (int i = 0; i < state.scanBarcodeListTotal.length; i++) {
            if (state.scanBarcodeListTotal[i].code == barcodeString) {
              Barcode barcode = state.scanBarcodeListTotal[i];
              barcode.repetitions = qty + sumOfOtherLinesWithSameUPC.toInt();
              print('------- Repetitions Total ${barcode.repetitions}');
            }
          }
        }
      }

      if (qtyScanned <= 0) {
        if (barcode != null) qtyScanned = barcode.repetitions;
      }
      if (lineIndex >= 0) {
        Line line = lines[lineIndex];
        line = line.copyWith(
          manualQty: 0,
          scanningQty: 0,
          confirmedQty: 0,
          scrappedQty: 0,
          verifiedStatus: 'pending',
        );

        lines[lineIndex] = _verifyLineStatusQty(
          line,
          qtyScanned.toDouble(),
          line.manualQty ?? 0,
          line.scrappedQty ?? 0,
        );
      } else {
        if (barcode != null) {
          linesOver.add(barcode.copyWith(index: linesOver.length + 1));
        }
      }
      state = state.copyWith(
        mInOut: state.mInOut!.copyWith(lines: lines),
        linesOver: linesOver,
      );
      saveMInOutSilence();
    }
  }

  void updatedMInOutLineSilence(String barcode) {
    if (state.mInOut != null && state.viewMInOut) {
      List<Line> lines = state.mInOut!.lines;
      List<Barcode> linesOver = [];


      for (final barcode in state.scanBarcodeListUnique) {
        final lineIndex = lines.indexWhere((line) => line.upc == barcode.code);
        if (lineIndex != -1) {
          final line = lines[lineIndex];
          lines[lineIndex] = _verifyLineStatusQty(
            line,
            barcode.repetitions.toDouble(),
            line.manualQty ?? 0,
            line.scrappedQty ?? 0,
          );
        } else {
          linesOver.add(barcode.copyWith(index: linesOver.length + 1));
        }
      }

      state = state.copyWith(
        mInOut: state.mInOut!.copyWith(lines: lines),
        linesOver: linesOver,
      );
    }
  }

  void moveScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scanBarcodeListScrollController.hasClients) {
        scanBarcodeListScrollController.animateTo(
          scanBarcodeListScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void selectRepeat(String code) {
    final List<Barcode> updatedListTotal = state.scanBarcodeListTotal;
    final List<Barcode> updatedListUnique = state.scanBarcodeListUnique;
    final List<Barcode> updatedLinesOver = state.linesOver;

    _toggleColoring(updatedListTotal, code);
    _toggleColoring(updatedListUnique, code);
    _toggleColoring(updatedLinesOver, code);

    state = state.copyWith(
      scanBarcodeListTotal: updatedListTotal,
      scanBarcodeListUnique: updatedListUnique,
      linesOver: updatedLinesOver,
    );
  }

  int getTotalCount() => state.scanBarcodeListTotal.length;

  int getUniqueCount() => state.scanBarcodeListUnique.length;

  void setUniqueView(bool value) {
    state = state.copyWith(uniqueView: value);
  }

  bool getUniqueView() => state.uniqueView;

  void setOrderBy(String orderBy) {
    final List<Line> sortedLines = [...state.mInOut!.lines];
    if (state.orderBy == orderBy) {
      sortedLines.sort((a, b) => a.line!.compareTo(b.line!));
      state = state.copyWith(
        orderBy: 'line',
        mInOut: state.mInOut!.copyWith(lines: sortedLines),
      );
    } else {
      _sortLinesByStatus(sortedLines, orderBy);
      state = state.copyWith(
        orderBy: orderBy,
        mInOut: state.mInOut!.copyWith(lines: sortedLines),
      );
    }
  }

  Line _verifyLineStatusQty(
      Line line,
      double scanningQty,
      double manualQty,
      double scrappedQty,
      ) {
    String status = 'pending';
    double confirmedQty = 0;

    if (manualQty > 0) {


      if (manualQty == line.targetQty) {
        status = 'manually-correct';
      } else if (manualQty < (line.targetQty ?? 0)) {
        status = 'manually-minor';
      } else {
        status = 'manually-over';
      }
      confirmedQty = manualQty;
    } else if (scanningQty > 0) {
      if (scanningQty == line.targetQty) {
        status = 'correct';
      } else if (scanningQty < (line.targetQty ?? 0)) {
        status = 'minor';
      } else {
        status = 'over';
      }
      confirmedQty = scanningQty;
    }

    final newLine = line.copyWith(
      manualQty: manualQty,
      scanningQty: scanningQty.toInt(),
      confirmedQty: confirmedQty,
      scrappedQty: scrappedQty,
      verifiedStatus: status,
    );

    return newLine;
  }

  Line _setLineStatusByQty(
      Line line,
    ) {
    String status = 'pending';
    double confirmedQty = line.confirmedQty ?? 0;
    double movementQty = line.movementQty ?? 0;
    double targetQty = line.targetQty ?? 0;
    double scrappedQty = line.scrappedQty ?? 0;
    double diff = movementQty - confirmedQty;
    if (diff == 0) {
      status = 'manually-correct';
    } else if (diff < 0) {
      status = 'manually-minor';
    } else {
      status = 'manually-over';
    }




    return line.copyWith(
      manualQty: confirmedQty,
      scanningQty: 0,
      confirmedQty: confirmedQty,
      scrappedQty: scrappedQty,
      targetQty:(targetQty==0 && movementQty>0) ? movementQty : targetQty,
      verifiedStatus: status,
    );
  }

  void _toggleColoring(List<Barcode> list, String code) {
    for (int i = 0; i < list.length; i++) {
      if (list[i].code == code) {
        list[i] = list[i].copyWith(coloring: !list[i].coloring);
      } else {
        list[i] = list[i].copyWith(coloring: false);
      }
    }
  }

  void _sortLinesByStatus(List<Line> lines, String orderBy) {
    final statuses = ['manually-minor', 'manually-over', 'manually-correct'];
    if (orderBy == 'manually') {
      for (final status in statuses) {
        lines.sort((a, b) {
          if (a.verifiedStatus == status && b.verifiedStatus != status) {
            return -1;
          } else if (a.verifiedStatus != status && b.verifiedStatus == status) {
            return 1;
          } else {
            return 0;
          }
        });
      }
    } else {
      lines.sort((a, b) {
        if (a.verifiedStatus == orderBy && b.verifiedStatus != orderBy) {
          return -1;
        } else if (a.verifiedStatus != orderBy && b.verifiedStatus == orderBy) {
          return 1;
        } else {
          return 0;
        }
      });
    }
  }

  Future<void> findMovementBetweenDates(WidgetRef ref, {required DateTimeRange<DateTime> dates,
    required String inOut}) async {
    debugPrint('>>> findMovementBetweenDates llamado');
    final start = DateFormat('yyyy-MM-dd').format(dates.start);
    final end   = DateFormat('yyyy-MM-dd').format(dates.end);



    if (state.mInOutType == MInOutType.move ||
        state.mInOutType == MInOutType.moveConfirm) {
      await getMovementListByDateRange(ref:ref,dates: dates,inOut:inOut);
    } else {
      await getMInOutListByDateRange(ref:ref,dates:dates,inOut:inOut);
    }

  }

  void saveMInOutSilence() {

    final box = GetStorage();
    final payload = buildSaveMInOutPayload(state);
    if (payload == null) return;

    // Use per-type list key
    final key = keySaveMInOutList(state.mInOutType.name);
    debugPrint('>>> saveMInOutSilence llamado: $key');

    try {
      // Read existing list
      final list = readSavedPayloadList(box: box, key: key);

      // De-duplicate by documentNo (keep latest only)
      final newDoc = payloadDocumentNo(payload);
      final filtered = list.where((p) => payloadDocumentNo(p) != newDoc).toList();

      // Insert newest first
      filtered.insert(0, payload);

      // Keep only last 10
      final trimmed = filtered.take(10).toList();

      // Write back
      _writeSavedPayloadList(box: box, key: key, list: trimmed);

      // Optional: still store last type for debugging / legacy
      box.write(KEY_SAVED_MINOUT_V1_TYPE, state.mInOutType.name);
    } catch (_) {
      // Keep silent
    }
  }


  // -------------------------------
  // Merge from local storage (logic)
  // -------------------------------

  // Parses a barcode list from JSON array.
  List<Barcode> _parseBarcodeList(dynamic v) {
    if (v is! List) return <Barcode>[];
    return v
        .whereType<Map<String, dynamic>>()
        .map((e) => Barcode.fromJson(e))
        .toList();
  }

  // Builds a map of saved lines by id for O(1) lookup.
  Map<int, Line> _indexLinesById(List<Line> lines) {
    final out = <int, Line>{};
    for (final l in lines) {
      final id = l.id;
      if (id != null) out[id] = l;
    }
    return out;
  }

  // Copies only the requested fields from saved line into current line.
  Line _mergeLineFields(Line current, Line saved) {
    return current.copyWith(
      verifiedStatus: saved.verifiedStatus,
      confirmedQty: saved.confirmedQty,
      scanningQty: saved.scanningQty,
      scrappedQty: saved.scrappedQty,
      manualQty: saved.manualQty,
    );
  }

  /// Merges saved state (barcodes + selected line fields) into the current state.
  ///
  /// UI should call this and show [MergeMInOutResult.message].
  MergeMInOutResult mergeFromStorage() {
    final currentMInOut = state.mInOut;
    final currentDocumentNo = (currentMInOut?.documentNo ?? '').trim();

    if (currentMInOut == null || currentDocumentNo.isEmpty) {
      return const MergeMInOutResult(ok: false, message: 'No hay datos para cargar.');
    }

    final box = GetStorage();
    final key = keySaveMInOutList(state.mInOutType.name);

    // Read saved list
    final list = readSavedPayloadList(box: box, key: key);
    if (list.isEmpty) {
      return const MergeMInOutResult(ok: false, message: 'No hay un guardado local para fusionar.');
    }

    // Find saved payload by current documentNo
    Map<String, dynamic>? map;
    for (final p in list) {
      if (payloadDocumentNo(p).trim() == currentDocumentNo) {
        map = p;
        break;
      }
    }

    if (map == null) {
      return MergeMInOutResult(
        ok: false,
        message: 'No existe guardado para el documento $currentDocumentNo.',
      );
    }

    // --- Validate version ---
    final version = (map['version'] ?? 0) as int;
    if (version != 1) {
      return MergeMInOutResult(
        ok: false,
        message: 'Guardado local incompatible (version=$version).',
      );
    }

    // --- Validate type ---
    final savedTypeName = (map['mInOutType'] ?? '').toString().trim();
    final currentTypeName = state.mInOutType.name;
    if (savedTypeName.isEmpty || savedTypeName != currentTypeName) {
      return MergeMInOutResult(
        ok: false,
        message: 'El guardado corresponde a otro tipo.\nActual: $currentTypeName\nGuardado: $savedTypeName',
      );
    }

    // --- Parse saved MInOut ---
    MInOut? savedMInOut;
    final savedMInOutJson = map['mInOut'];
    if (savedMInOutJson is Map<String, dynamic>) {
      try {
        savedMInOut = MInOut.fromJson(savedMInOutJson);
      } catch (_) {
        return const MergeMInOutResult(ok: false, message: 'El guardado local está dañado (mInOut).');
      }
    }

    final savedDocumentNo = (savedMInOut?.documentNo ?? '').trim();
    if (savedDocumentNo.isEmpty || savedDocumentNo != currentDocumentNo) {
      return MergeMInOutResult(
        ok: false,
        message: 'El guardado corresponde a otro documento.\nActual: $currentDocumentNo\nGuardado: $savedDocumentNo',
      );
    }

    // --- Parse barcode lists ---
    final savedTotal = _parseBarcodeList(map['scanBarcodeListTotal']);
    final savedUnique = _parseBarcodeList(map['scanBarcodeListUnique']);
    final savedOver = _parseBarcodeList(map['linesOver']);

    // --- Merge line fields by id ---
    final List<Line> savedLines = savedMInOut?.lines ?? const <Line>[] ;
    final List<Line> allLines = savedMInOut?.allLines ?? const <Line>[] ;
    final savedById = _indexLinesById(savedLines);

    // Merge current lines
    final List<Line> currentLines = currentMInOut.lines ;
    int mergedCount = 0;

    final mergedLines = currentLines.map((line) {
      final id = line.id;
      if (id == null) return line;

      final saved = savedById[id];
      if (saved == null) return line;

      mergedCount++;
      return _mergeLineFields(line, saved);
    }).toList();

    // --- Apply to state using copyWith ---
    final updatedMInOut = currentMInOut.copyWith(
      lines: mergedLines,
      allLines: allLines,
    );
// --- Parse saved MInOutConfirm (copyWith approach) ---
    MInOutConfirm? savedConfirm;
    final savedConfirmJson = map['mInOutConfirm'];
    if (savedConfirmJson is Map<String, dynamic>) {
      try {
        savedConfirm = MInOutConfirm.fromJson(savedConfirmJson);
      } catch (_) {
        return const MergeMInOutResult(
          ok: false,
          message: 'El guardado local está dañado (mInOutConfirm).',
        );
      }
    }

// --- Merge confirm into current confirm (copyWith) ---
    final currentConfirm = state.mInOutConfirm;
    MInOutConfirm? updatedConfirm;

    if (currentConfirm != null && savedConfirm != null) {
      updatedConfirm = _mergeMInOutConfirmCopyWith(
        current: currentConfirm,
        saved: savedConfirm,
      );
    } else {
      updatedConfirm = currentConfirm; // keep current if missing either side
    }

    state = state.copyWith(
      mInOut: updatedMInOut,
      mInOutConfirm: updatedConfirm,
      scanBarcodeListTotal: savedTotal,
      scanBarcodeListUnique: savedUnique,
      linesOver: savedOver,
      errorMessage: '',
    );

    return MergeMInOutResult(
      ok: true,
      mergedLines: mergedCount,
      message: 'Fusión completada ✅ (líneas actualizadas: $mergedCount)',
    );
  }

  void removeSavedMInOutData(WidgetRef ref) {
    // EN: Remove saved payload for the current documentNo in the per-type list
    final box = GetStorage();

    try {
      final stateNow = ref.read(mInOutProvider);

      // EN: Use current loaded documentNo (best source of truth)
      final currentDoc = (stateNow.mInOut?.documentNo ?? '').trim();
      if (currentDoc.isEmpty) return;

      // EN: Per-type storage key
      final key = keySaveMInOutList(stateNow.mInOutType.name);

      // EN: Read list
      final list = readSavedPayloadList(box: box, key: key);
      if (list.isEmpty) return;

      // EN: Filter out the payload matching current documentNo
      final filtered = list.where((p) => payloadDocumentNo(p).trim() != currentDoc).toList();

      if (filtered.isEmpty) {
        // EN: Clean key if list becomes empty
        box.remove(key);
      } else {
        _writeSavedPayloadList(box: box, key: key, list: filtered);
      }

      debugPrint('removeSavedMInOutData OK doc=$currentDoc key=$key before=${list.length} after=${filtered.length}');
    } catch (e) {
      // EN: Keep silent; never break main flow
      debugPrint('removeSavedMInOutData ERROR: $e');
    }
  }

  void setConfirmedQtyEqualsMovementQty(List<Line> filteredLines) {
    for (int i = 0; i < filteredLines.length; i++) {
      filteredLines[i] = filteredLines[i].copyWith(
        confirmedQty: filteredLines[i].movementQty,
        verifiedStatus: 'manually-correct',
      );
    }
    state = state.copyWith(
      usingRolQuickComplete: true,
      mInOut: state.mInOut!.copyWith(lines: filteredLines),
    );
  }
  void resetConfirmedQty(List<Line> filteredLines) {
    for (int i = 0; i < filteredLines.length; i++) {
      filteredLines[i] = filteredLines[i].copyWith(
        confirmedQty: 0,
        verifiedStatus: 'pending',
      );
    }
    state = state.copyWith(
      usingRolQuickComplete: false,
      mInOut: state.mInOut!.copyWith(lines: filteredLines),
    );
  }

  bool documentCanComplete(MInOutStatus mInOutState) {
    bool isDraft = false;

    if(isMInOutConfirmType(mInOutState.mInOutType)){
      isDraft = mInOutState.mInOutConfirm?.docStatus.id == 'DR' ;
    } else {
      isDraft=  mInOutState.mInOut?.docStatus.id == 'DR' ||
       mInOutState.mInOut?.docStatus.id == 'IP'  ;
    }
    return isDraft;

  }





}

// Result object for merge operation (UI-friendly).
class MergeMInOutResult {
  final bool ok;
  final String message;
  final int mergedLines;

  const MergeMInOutResult({
    required this.ok,
    required this.message,
    this.mergedLines = 0,
  });
}

enum MInOutType {
  shipment,
  shipmentConfirm,
  shipmentPrepare,
  receipt,
  receiptConfirm,
  pickConfirm,
  qaConfirm,
  move,
  moveConfirm,
}

class MInOutStatus {
  final String doc;
  final MInOutType mInOutType;
  final MInOut? mInOut;
  final List<MInOut> mInOutList;
  final MInOutConfirm? mInOutConfirm;
  final bool isSOTrx;
  final String title;
  final List<Barcode> scanBarcodeListTotal;
  final List<Barcode> scanBarcodeListUnique;
  final List<Barcode> linesOver;
  final bool viewMInOut;
  final bool uniqueView;
  final String orderBy;
  final double manualQty;
  final double scrappedQty;
  final String editLocator;
  final String errorMessage;
  final bool isLoading;
  final bool isLoadingMInOutList;
  final bool isComplete;
  final List<MInOutConfirm> mInOutConfirmList;
  final bool usingRolQuickComplete;


  // ROLES
  final bool rolShowQty;
  final bool rolShowScrap;
  final bool rolManualQty;
  final bool rolManualScrap;
  final bool rolCompleteLow;
  final bool rolCompleteOver;
  final bool rolPrepare;
  final bool rolComplete;
  final bool rolQuickComplete;

  MInOutStatus({
    this.doc = '',
    this.mInOutType = MInOutType.shipment,
    this.mInOut,
    this.mInOutList = const [],
    this.mInOutConfirm,
    this.isSOTrx = false,
    this.title = 'Shipment',
    required this.scanBarcodeListTotal,
    required this.scanBarcodeListUnique,
    this.linesOver = const [],
    this.viewMInOut = false,
    this.uniqueView = false,
    this.orderBy = '',
    this.manualQty = 0,
    this.scrappedQty = 0,
    this.editLocator = '',
    this.errorMessage = '',
    this.isLoading = false,
    this.isLoadingMInOutList = false,
    this.isComplete = false,
    this.rolShowQty = false,
    this.rolShowScrap = false,
    // temporaria
    this.rolManualQty = true,
    this.rolManualScrap = false,
    this.rolCompleteLow = false,
    this.rolCompleteOver = false,
    this.rolPrepare = false,
    this.rolComplete = false,
    this.rolQuickComplete = false,
    this.mInOutConfirmList = const [],
    this.usingRolQuickComplete = false,
  });

  bool get isConfirmFlow => mInOutType==MInOutType.moveConfirm ||
      mInOutType == MInOutType.shipmentConfirm ||
     mInOutType == MInOutType.pickConfirm ||
     mInOutType == MInOutType.qaConfirm ||
     mInOutType == MInOutType.receiptConfirm
  ;
  bool get isMovement => mInOutType == MInOutType.move || mInOutType == MInOutType.moveConfirm ;

  MInOutStatus copyWith({
    String? doc,
    MInOutType? mInOutType,
    List<MInOut>? mInOutList,
    MInOut? mInOut,
    MInOutConfirm? mInOutConfirm,
    bool? isSOTrx,
    String? title,
    List<Barcode>? scanBarcodeListTotal,
    List<Barcode>? scanBarcodeListUnique,
    List<Barcode>? linesOver,
    bool? viewMInOut,
    bool? uniqueView,
    String? orderBy,
    double? manualQty,
    double? scrappedQty,
    String? editLocator,
    String? errorMessage,
    bool? isLoading,
    bool? isLoadingMInOutList,
    bool? isComplete,
    bool? rolShowQty,
    bool? rolShowScrap,
    bool? rolManualQty,
    bool? rolManualScrap,
    bool? rolCompleteLow,
    bool? rolCompleteOver,
    bool? rolPrepare,
    bool? rolComplete,
    bool? rolQuickComplete,
    List<MInOutConfirm>? mInOutConfirmList,
    bool? usingRolQuickComplete,
  }) => MInOutStatus(
    doc: doc ?? this.doc,
    mInOutType: mInOutType ?? this.mInOutType,
    mInOutList: mInOutList ?? this.mInOutList,
    mInOut: mInOut ?? this.mInOut,
    mInOutConfirm: mInOutConfirm ?? this.mInOutConfirm,
    isSOTrx: isSOTrx ?? this.isSOTrx,
    title: title ?? this.title,
    scanBarcodeListTotal: scanBarcodeListTotal ?? this.scanBarcodeListTotal,
    scanBarcodeListUnique: scanBarcodeListUnique ?? this.scanBarcodeListUnique,
    linesOver: linesOver ?? this.linesOver,
    viewMInOut: viewMInOut ?? this.viewMInOut,
    orderBy: orderBy ?? this.orderBy,
    manualQty: manualQty ?? this.manualQty,
    scrappedQty: scrappedQty ?? this.scrappedQty,
    editLocator: editLocator ?? this.editLocator,
    uniqueView: uniqueView ?? this.uniqueView,
    errorMessage: errorMessage ?? this.errorMessage,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMInOutList: isLoadingMInOutList ?? this.isLoadingMInOutList,
    isComplete: isComplete ?? this.isComplete,
    rolShowQty: rolShowQty ?? this.rolShowQty,
    rolShowScrap: rolShowScrap ?? this.rolShowScrap,
    rolManualQty: rolManualQty ?? this.rolManualQty,
    rolManualScrap: rolManualScrap ?? this.rolManualScrap,
    rolCompleteLow: rolCompleteLow ?? this.rolCompleteLow,
    rolCompleteOver: rolCompleteOver ?? this.rolCompleteOver,
    rolPrepare: rolPrepare ?? this.rolPrepare,
    rolComplete: rolComplete ?? this.rolComplete,
    rolQuickComplete: rolQuickComplete ?? this.rolQuickComplete,
    mInOutConfirmList: mInOutConfirmList ?? this.mInOutConfirmList,
    usingRolQuickComplete: usingRolQuickComplete ?? this.usingRolQuickComplete,
  );


}


Color getMInOutHeaderColor(MInOutStatus mInOutState) {
  final docStatusId = mInOutState.mInOut?.docStatus.id?.toString();
  final confirmStatusId = mInOutState.mInOutConfirm?.docStatus.id?.toString();

  if (mInOutState.mInOutType == MInOutType.move) {
    if (docStatusId == 'DR') return themeColorWarningLight;
    if (docStatusId == 'IP') return Colors.cyan.shade200;
    if (docStatusId == 'CO') return themeColorSuccessfulLight;
    return Colors.grey.shade200;
  }

  if (mInOutState.mInOutType == MInOutType.moveConfirm) {
    if (confirmStatusId == 'DR') return themeColorWarningLight;
    if (confirmStatusId == 'IP') return Colors.cyan.shade200;
    if (confirmStatusId == 'CO') return themeColorSuccessfulLight;
    return Colors.grey.shade200;
  }

  final type = mInOutState.mInOutType;

  final esInOutNormal =
      type == MInOutType.shipment ||
          type == MInOutType.receipt ||
          type == MInOutType.move ||
          type == MInOutType.moveConfirm;

  if (!esInOutNormal) {
    // usar docStatus del confirm
    if (confirmStatusId == 'IP') return themeColorWarningLight;
    if (confirmStatusId == 'CO') return themeColorSuccessfulLight;
  } else {
    // usar docStatus del mInOut principal
    if (docStatusId == 'IP') return themeColorWarningLight;
    if (docStatusId == 'CO') return themeColorSuccessfulLight;
  }

  return themeBackgroundColorLight;
}
MInOutType? parseMInOutTypeFromWidget(String type) {
  switch (type.toLowerCase()) {
    case 'shipment':
      return MInOutType.shipment;
    case 'shipmentconfirm':
      return MInOutType.shipmentConfirm;
    case 'shipmentprepare':
      return MInOutType.shipmentPrepare;
    case 'receipt':
      return MInOutType.receipt;
    case 'receiptconfirm':
      return MInOutType.receiptConfirm;
    case 'pickconfirm':
      return MInOutType.pickConfirm;
    case 'qaconfirm':
      return MInOutType.qaConfirm;
    case 'move':
      return MInOutType.move;
    case 'moveconfirm':
      return MInOutType.moveConfirm;
    default:
      return null;
  }
}

Map<String, dynamic>? buildSaveMInOutPayload(MInOutStatus stateNow) {
  debugPrint('>>> buildSaveMInOutPayload llamado');
  final stateLines = stateNow.mInOut?.lines ?? [];
  for(final line in stateLines){
    debugPrint('${line.line ?? ''}, M ${line.movementQty ?? ''}, C ${line.confirmedQty ?? ''}, S ${line.scanningQty ?? ''}');
  }

  debugPrint('>>> buildSaveMInOutPayload llamado');
  final hasDoc = stateNow.doc.trim().isNotEmpty;
  final hasLines = (stateNow.mInOut?.lines.isNotEmpty ?? false) ||
      (stateNow.mInOut?.allLines.isNotEmpty ?? false);
  final hasBarcodes = stateNow.scanBarcodeListTotal.isNotEmpty ||
      stateNow.scanBarcodeListUnique.isNotEmpty;

  if (!hasDoc && !hasLines && !hasBarcodes) return null;
  return <String, dynamic>{
    'version': 1,
    'savedAt': DateTime.now().toIso8601String(),

    // Estado básico
    'doc': stateNow.doc,
    'mInOutType': stateNow.mInOutType.name,
    'title': stateNow.title,
    'isSOTrx': stateNow.isSOTrx,
    'viewMInOut': stateNow.viewMInOut,
    'uniqueView': stateNow.uniqueView,
    'orderBy': stateNow.orderBy,
    'manualQty': stateNow.manualQty,
    'scrappedQty': stateNow.scrappedQty,
    'editLocator': stateNow.editLocator,
    'isComplete': stateNow.isComplete,


    // Roles
    'rolShowQty': stateNow.rolShowQty,
    'rolShowScrap': stateNow.rolShowScrap,
    'rolManualQty': stateNow.rolManualQty,
    'rolManualScrap': stateNow.rolManualScrap,
    'rolCompleteLow': stateNow.rolCompleteLow,
    'rolCompleteOver': stateNow.rolCompleteOver,
    'rolPrepare': stateNow.rolPrepare,
    'rolComplete': stateNow.rolComplete,
    'rolQuickComplete': stateNow.rolQuickComplete,
    'usingRolQuickComplete': stateNow.usingRolQuickComplete,


    // Entities
    'mInOut': stateNow.mInOut?.toJson(),
    'mInOutConfirm': stateNow.mInOutConfirm?.toJson(),

    // Barcodes / over
    'scanBarcodeListTotal':
    stateNow.scanBarcodeListTotal.map((b) => b.toJson()).toList(),
    'scanBarcodeListUnique':
    stateNow.scanBarcodeListUnique.map((b) => b.toJson()).toList(),
    'linesOver': stateNow.linesOver.map((b) => b.toJson()).toList(),
    'mInOutConfirmList': stateNow.mInOutConfirmList.map((b) => b.toJson()).toList(),

  };
}

// Builds a map of LineConfirm by LineConfirm.id (int key).
Map<int, LineConfirm> _indexConfirmByConfirmId(
    List<LineConfirm> lines,
    ) {
  final out = <int, LineConfirm>{};

  for (final c in lines) {
    final key = c.id;
    if (key != null) {
      out[key] = c;
    }
  }
  return out;
}

// Merges MInOutConfirm.linesConfirm using mInOutLineId.id as key (copyWith).
MInOutConfirm _mergeMInOutConfirmCopyWith({
  required MInOutConfirm current,
  required MInOutConfirm saved,
}) {
  //final savedByLineId = _indexConfirmByInOutLineId(saved.linesConfirm);
  final savedById =  _indexConfirmByConfirmId(saved.linesConfirm);

  final mergedLines = current.linesConfirm.map((c) {
    //final key = c.mInOutLineId?.id;
    final key = c.id;
    if (key == null) return c;

    //final s = savedByLineId[key];
    final s = savedById[key];
    if (s == null) return c;

    //return _mergeLineConfirmFields(c, s);
    return c.copyWith(
      targetQty: s.targetQty,
      confirmedQty: s.confirmedQty,
      differenceQty: s.differenceQty,
      scrappedQty: s.scrappedQty,
    );
  }).toList();

  return current.copyWith(linesConfirm: mergedLines);
}



// Validates if saved payload matches current documentNo + mInOutType.
final canMergeSavedProvider = Provider<bool>((ref) {
  final stateNow = ref.watch(mInOutProvider);
  final currentM = stateNow.mInOut;

  final currentDoc = (currentM?.documentNo ?? '').trim();
  if (currentM == null || currentDoc.isEmpty) return false;

  // Read saved list by current type
  final key = keySaveMInOutList(stateNow.mInOutType.name);


  final raw = GetStorage().read(key);
  if (raw == null || raw.toString().trim().isEmpty) return false;

  List list;
  try {
    final decoded = jsonDecode(raw is String ? raw : raw.toString());
    if (decoded is! List) return false;
    list = decoded;
  } catch (_) {
    return false;
  }

  // Find payload matching current documentNo
  for (final item in list) {
    if (item is! Map<String, dynamic>) continue;

    // Version check
    final version = (item['version'] ?? 0);
    if (version != 1) continue;

    // Type check
    final savedTypeName = (item['mInOutType'] ?? '').toString().trim();
    if (savedTypeName != stateNow.mInOutType.name) continue;

    // DocumentNo check (best-effort)
    final doc = payloadDocumentNo(item).trim();
    if (doc == currentDoc) return true;
  }

  return false;
});

// Reads saved payload list from storage (per type).
List<Map<String, dynamic>> readSavedPayloadList({
  required GetStorage box,
  required String key,
}) {
  final raw = box.read(key);
  if (raw == null || raw.toString().trim().isEmpty) return <Map<String, dynamic>>[];

  try {
    final decoded = jsonDecode(raw is String ? raw : raw.toString());
    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
  } catch (_) {
    // Ignore invalid JSON
  }
  return <Map<String, dynamic>>[];
}

// Writes saved payload list to storage (per type).
void _writeSavedPayloadList({
  required GetStorage box,
  required String key,
  required List<Map<String, dynamic>> list,
}) {
  final jsonString = jsonEncode(list);
  box.write(key, jsonString);
}

// Extracts a safe documentNo from a payload (best-effort).
String payloadDocumentNo(Map<String, dynamic> payload) {
  final m = payload['mInOut'];
  if (m is Map<String, dynamic>) {
    final doc = (m['documentNo'] ?? '').toString().trim();
    if (doc.isNotEmpty) return doc;
  }
  // Fallback to 'doc' state field
  return (payload['doc'] ?? '').toString().trim();
}

// Extracts savedAt from payload.
String payloadSavedAt(Map<String, dynamic> payload) {
  return (payload['savedAt'] ?? '').toString();
}
Future<void> openProgressIfNeeded(WidgetRef ref) async {
  if (!ref.context.mounted) return;
  // Abrimos el dialog UNA sola vez al inicio.
  // Si ya está abierto, no pasa nada malo, pero evitamos duplicar.
  // Truco simple: abrir y dejar que el flujo lo cierre al final.
  showActionProgressDialog(context: ref.context, ref: ref);
}


bool canCreateDocument(MInOutType type) {
    switch (type) {
      case MInOutType.shipmentConfirm:
        return RolesApp.appShipmentconfirmComplete;
      case MInOutType.receiptConfirm:
        return RolesApp.appReceiptconfirmComplete;
      case MInOutType.pickConfirm:
        return RolesApp.appPickconfirmComplete;
      case MInOutType.qaConfirm:
        return RolesApp.appQaconfirmComplete;
      case MInOutType.moveConfirm:
        return RolesApp.appMovementconfirmComplete;
      case MInOutType.shipment:
        return RolesApp.appShipmentCreate;
      case MInOutType.receipt:
        return false;
      case MInOutType.move:
        return RolesApp.appMovementComplete;
      case MInOutType.shipmentPrepare:
        return RolesApp.appShipmentPrepare;
    }
}

PutAwayMovement? createPutAwayMovementFromMinOut({required WidgetRef ref,
  required Line line, required IdempiereLocator locatorFrom}){

  // English: Ensure org link is consistent (some models need org propagation)
  final org = ref.read(authProvider).selectedOrganization;
  int orgId = int.tryParse(org?.id.toString() ?? '') ?? 0;

  final int productId = int.tryParse(line.mProductId?.id ?? '') ?? 0;
  MInOut? mInOut = ref.read(mInOutProvider).mInOut;
  final currentLocatorFrom = line.mLocatorId;
  final int locatorToId = int.tryParse(currentLocatorFrom?.id ?? '') ?? 0;

  final PutAwayMovement putAwayMovement = PutAwayMovement();
  putAwayMovement.setUser(Memory.sqlUsersData);
  final IdempiereDocumentType documentType = Memory.materialMovement ;

  putAwayMovement.movementLineToCreate!.mProductID = IdempiereProduct(id: productId);
  putAwayMovement.movementLineToCreate!.mLocatorID = locatorFrom;
  putAwayMovement.movementLineToCreate!.mLocatorToID =IdempiereLocator(id: locatorToId);
  putAwayMovement.movementLineToCreate!.movementQty = line.confirmedQty?? 0 ;
  putAwayMovement.movementLineToCreate!.line = 10;
  putAwayMovement.movementToCreate!.cDocTypeID = documentType;

  putAwayMovement.movementToCreate!.locatorFromId = locatorFrom.id;
  int warehouseId = int.tryParse(mInOut?.mWarehouseId.id ??'') ?? 0;
  if(warehouseId<=0) return null ;
  IdempiereWarehouse warehouse = IdempiereWarehouse(id: warehouseId,aDOrgID: IdempiereOrganization(id: orgId));
  putAwayMovement.movementToCreate!.mWarehouseID = warehouse;
  putAwayMovement.movementToCreate!.mWarehouseToID = warehouse;

  final check = putAwayMovement.canCreatePutAwayMovement();

  final ui = mapPutAwayCheckToUi(check);

  if (!ui.ok) {
    showErrorCenterToast(ref.context, ui.message);
    return null;
  }

  return putAwayMovement;

}

