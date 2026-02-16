import 'package:flutter/src/material/date.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/line_confirm.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out_confirm.dart';

import '../entities/line.dart';

abstract class MInOutDataSource {
  Future<List<MInOut>> getMInOutList(WidgetRef ref);
  Future<List<MInOutConfirm>> getMInOutConfirmList(int mInOutId, WidgetRef ref);
  Future<List<MInOut>> getMovementList(WidgetRef ref);
  Future<List<MInOutConfirm>> getMovementConfirmList(int movementId, WidgetRef ref);
  Future<MInOut> getMInOut(String mInOutDoc, WidgetRef ref);
  Future<List<Line>> getLinesMInOut(int mInOutId, WidgetRef ref);
  Future<MInOutConfirm> getMInOutConfirm(int mInOutConfirmId, WidgetRef ref);
  Future<List<MInOutConfirm>> getMInOutConfirmInDraftByMInOutID({
      required int mInOutId,
      required int excludedMInOutConfirmId,
       required WidgetRef ref,
      });
  Future<List<LineConfirm>> getLinesMInOutConfirm(int mInOutConfirmId, WidgetRef ref);
  Future<MInOut> getMovement(String movementDoc, WidgetRef ref);
  Future<List<Line>> getLinesMovement(int movementId, WidgetRef ref);
  Future<MInOutConfirm> getMovementConfirm(int movementConfirmId, WidgetRef ref);
  Future<List<LineConfirm>> getLinesMovementConfirm(int movementConfirmId, WidgetRef ref);
  Future<MInOut> setDocAction(WidgetRef ref);
  Future<MInOutConfirm> setDocActionConfirm(WidgetRef ref);
  Future<LineConfirm> updateLineConfirm(Line line, WidgetRef ref);
  Future<Line> updateMInOutLineMovementQtyAndLocator(Line line, WidgetRef ref);
  Future<int> getLocator(String value, WidgetRef ref);
  Future<bool> updateLocator(Line line, WidgetRef ref);
  Future<bool> updateMovementQty(Line line, WidgetRef ref);
  Future<bool> updateLineConfirmConfirmQty(LineConfirm line, WidgetRef ref);

  Future getMInOutListByDateRange({required WidgetRef ref, required DateTimeRange<DateTime> dates
    , required String inOut});

  Future getMovementListByDateRange({required WidgetRef ref, required DateTimeRange<DateTime> dates
    , required String inOut});

  Future<List<LineConfirm>> getLinesMInOutConfirmToUpdateTargetQty({
  required List<int> listConfirmsIds, required List<int> mInOutLineIds, required WidgetRef ref});

}
