import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../config/constants/roles_app.dart';

import '../../../domain/entities/m_in_out.dart';
import '../../../domain/entities/m_in_out_confirm.dart';
import '../../../domain/repositories/m_in_out_repositiry.dart';
import '../../../presentation/providers/m_in_out_providers.dart'; // MInOutType, MInOutStatus
import 'm_inout_flow_actions.dart';

typedef LoadHeaderAndLinesFn = Future<MInOut> Function(WidgetRef ref, String doc, MInOutType type);

class MInOutFlowService {
  final MInOutRepository repo;
  final LoadHeaderAndLinesFn loadHeaderAndLines;

  MInOutFlowService({
    required this.repo,
    required this.loadHeaderAndLines,
  });

  Future<LoadMInOutAction> run(WidgetRef ref, MInOutStatus state) async {
    final doc = state.doc.trim();
    if (doc.isEmpty) {
      return const LoadError('Por favor ingrese un número de documento válido');
    }

    // 1) header + lines
    final mInOut = await loadHeaderAndLines(ref, doc, state.mInOutType);
    if (mInOut.id == null) {
      return LoadError('No se encontró el documento: $doc');
    }

    // 2) 非 confirm 類型直接成功
    if (!_isConfirmType(state.mInOutType)) {
      return const LoadSuccess();
    }

    // 3) confirm 類型：取得 confirm list
    final List<MInOutConfirm> confirms = await repo.getMInOutConfirmList(mInOut.id!, ref);

    // 3.1 沒有 confirm 且允許建立 → 根據規則回傳建立動作
    if (confirms.isEmpty && RolesApp.canCreateConfirm) {
      final type = state.mInOutType;

      // ✅ 新規則：QA Confirm = pickConfirm 規則（一起走 pickLike）
      final isPickLike = type == MInOutType.pickConfirm || type == MInOutType.qaConfirm;
      final isShipment = type == MInOutType.shipmentConfirm;

      if (isPickLike && mInOut.canCreatePickConfirm) {
        return NeedCreateConfirm(
          kind: ConfirmCreateKind.pickLike,
          targetType: type, // pickConfirm 或 qaConfirm
          documentNo: doc,
          mInOutId: mInOut.id!.toString(),
        );
      }

      if (isShipment && mInOut.canCreateShipmentConfirm) {
        return NeedCreateConfirm(
          kind: ConfirmCreateKind.shipment,
          targetType: type, // shipmentConfirm
          documentNo: doc,
          mInOutId: mInOut.id!.toString(),
        );
      }
    }

    // 3.2 有 confirm：回傳讓 UI 選
    return NeedSelectConfirm(confirms);
  }

  bool _isConfirmType(MInOutType type) {
    return type == MInOutType.shipmentConfirm ||
        type == MInOutType.receiptConfirm ||
        type == MInOutType.pickConfirm ||
        type == MInOutType.qaConfirm ||
        type == MInOutType.moveConfirm;
  }
}
