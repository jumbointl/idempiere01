// lib/features/m_inout/presentation/providers/m_in_out_status.dart

import 'package:flutter/material.dart';

import '../../domain/entities/barcode.dart';
import '../../domain/entities/m_in_out.dart';
import '../../domain/entities/m_in_out_confirm.dart';
import '../../../../config/theme/app_theme.dart';
import 'm_in_out_type.dart';

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

  bool get isConfirmFlow =>
      mInOutType == MInOutType.moveConfirm ||
          mInOutType == MInOutType.shipmentConfirm ||
          mInOutType == MInOutType.pickConfirm ||
          mInOutType == MInOutType.qaConfirm ||
          mInOutType == MInOutType.receiptConfirm;

  bool get isMovement =>
      mInOutType == MInOutType.move || mInOutType == MInOutType.moveConfirm;

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
  }) =>
      MInOutStatus(
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
    if (confirmStatusId == 'IP') return themeColorWarningLight;
    if (confirmStatusId == 'CO') return themeColorSuccessfulLight;
  } else {
    if (docStatusId == 'IP') return themeColorWarningLight;
    if (docStatusId == 'CO') return themeColorSuccessfulLight;
  }

  return themeBackgroundColorLight;
}