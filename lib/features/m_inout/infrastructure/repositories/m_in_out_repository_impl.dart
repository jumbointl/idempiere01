import 'package:flutter/src/material/date.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/line_confirm.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/m_inout/domain/repositories/m_in_out_repositiry.dart';

import '../../domain/datasources/m_inout_datasource.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/m_in_out_confirm.dart';
import '../datasources/m_in_out_datasource_impl.dart';

class MInOutRepositoryImpl implements MInOutRepository {
  final MInOutDataSource dataSource;

  MInOutRepositoryImpl({MInOutDataSource? dataSource})
      : dataSource = dataSource ?? MInOutDataSourceImpl();

  @override
  Future<List<MInOut>> getMInOutList(WidgetRef ref) {
    return dataSource.getMInOutList(ref);
  }

  @override
  Future<List<MInOutConfirm>> getMInOutConfirmList(
      int mInOutId, WidgetRef ref) {
    return dataSource.getMInOutConfirmList(mInOutId, ref);
  }

  @override
  Future<MInOut> getMInOut(String mInOutDoc, WidgetRef ref) {
    return dataSource.getMInOut(mInOutDoc, ref);
  }

  @override
  Future<List<Line>> getLinesMInOut(int mInOutId, WidgetRef ref) {
    return dataSource.getLinesMInOut(mInOutId, ref);
  }

  @override
  Future<MInOutConfirm> getMInOutConfirm(
      int mInOutConfirmId, WidgetRef ref) {
    return dataSource.getMInOutConfirm(mInOutConfirmId, ref);
  }

  @override
  Future<List<LineConfirm>> getLinesMInOutConfirm(
      int mInOutConfirmId, WidgetRef ref) {
    return dataSource.getLinesMInOutConfirm(mInOutConfirmId, ref);
  }

  @override
  Future<List<MInOut>> getMovementList(WidgetRef ref) {
    return dataSource.getMovementList(ref);
  }

  @override
  Future<MInOut> getMovement(String movementDoc, WidgetRef ref) {
    return dataSource.getMovement(movementDoc, ref);
  }

  @override
  Future<List<Line>> getLinesMovement(int movementId, WidgetRef ref) {
    return dataSource.getLinesMovement(movementId, ref);
  }

  @override
  Future<List<MInOutConfirm>> getMovementConfirmList(
      int movementId, WidgetRef ref) {
    return dataSource.getMovementConfirmList(movementId, ref);
  }

  @override
  Future<MInOutConfirm> getMovementConfirm(
      int movementConfirmId, WidgetRef ref) {
    return dataSource.getMovementConfirm(movementConfirmId, ref);
  }

  @override
  Future<List<LineConfirm>> getLinesMovementConfirm(
      int movementConfirmId, WidgetRef ref) {
    return dataSource.getLinesMovementConfirm(movementConfirmId, ref);
  }

  @override
  Future<MInOut> setDocAction(WidgetRef ref) {
    return dataSource.setDocAction(ref);
  }

  @override
  Future<LineConfirm> updateLineConfirm(Line line, WidgetRef ref) {
    return dataSource.updateLineConfirm(line, ref);
  }

  @override
  Future<int> getLocator(String value, WidgetRef ref) {
    return dataSource.getLocator(value, ref);
  }

  @override
  Future<bool> updateLocator(Line line, WidgetRef ref) {
    return dataSource.updateLocator(line, ref);
  }

  @override
  Future getMInOutListByDateRange({required WidgetRef ref, required DateTimeRange<DateTime> dates, required String inOut}) {
    return dataSource.getMInOutListByDateRange(ref:ref, dates:dates, inOut:inOut);
  }

  @override
  Future getMovementListByDateRange(WidgetRef ref, {required DateTimeRange<DateTime> dates, required String inOut}) {
    return dataSource.getMovementListByDateRange(ref:ref, dates:dates, inOut:inOut);
  }
  @override
  Future getSalesOrderListByDateRange({required WidgetRef ref, required DateTimeRange<DateTime> dates}){
    return dataSource.getSalesOrderListByDateRange(ref:ref, dates:dates);

  }
}
