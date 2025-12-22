
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/line.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out_confirm.dart';
import 'package:monalisa_app_001/features/m_inout/domain/repositories/m_in_out_repositiry.dart';
import 'package:monalisa_app_001/features/products/common/messages_dialog.dart';
import 'package:monalisa_app_001/features/products/common/number_input_panel.dart';
import '../../../../config/constants/roles_app.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../products/common/number_sum_panel.dart';
import '../../../products/common/selections_dialog.dart';
import '../../domain/entities/barcode.dart';
import '../../domain/entities/line_confirm.dart';
import '../../infrastructure/repositories/m_in_out_repository_impl.dart';
import 'm_in_ot_utils.dart';

int quantityOfMovementAndScannedToAllowInputScannedQuantity = 3;
const String KEY_QTY_ALLOW_INPUT =
    'qtyOfMovementAndScannedToAllowInputScannedQuantity';
final adjustScannedQtyProvider = StateProvider<bool>((ref) => true);

final mInOutProvider = StateNotifierProvider<MInOutNotifier, MInOutStatus>((
  ref,
) {
  return MInOutNotifier(mInOutRepository: MInOutRepositoryImpl());
});

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
    if (type == 'shipment') {
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
        rolCompleteLow: RolesApp.appShipmentLowqty,
        rolCompleteOver: false,
        rolPrepare: RolesApp.appShipmentPrepare,
        rolComplete: RolesApp.appShipmentComplete,
      );
    } else if (type == 'shipmentconfirm') {
      state = state.copyWith(
        isSOTrx: true,
        mInOutType: MInOutType.shipmentConfirm,
        title: 'Shipment Confirm',
        rolShowQty: RolesApp.appShipmentconfirmQty,
        rolManualQty: RolesApp.appShipmentconfirmManual,
        rolShowScrap: false,
        rolManualScrap: false,
        rolCompleteLow: RolesApp.appShipmentLowqty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appShipmentconfirmComplete,
      );
    } else if (type == 'pickconfirm') {
      state = state.copyWith(
        isSOTrx: true,
        mInOutType: MInOutType.pickConfirm,
        title: 'Pick Confirm',
        rolShowQty: RolesApp.appPickconfirmQty,
        rolManualQty: RolesApp.appPickconfirmManual,
        rolShowScrap: RolesApp.appPickconfirmQty,
        rolManualScrap: RolesApp.appPickconfirmManual,
        rolCompleteLow: RolesApp.appShipmentLowqty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appPickconfirmComplete,
      );
    } else if (type == 'receipt') {
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
        rolCompleteLow: RolesApp.appShipmentLowqty,
        rolCompleteOver: false,
        rolPrepare: RolesApp.appReceiptPrepare,
        rolComplete: RolesApp.appReceiptComplete,
      );
    } else if (type == 'receiptconfirm') {
      state = state.copyWith(
        isSOTrx: false,
        mInOutType: MInOutType.receiptConfirm,
        title: 'Receipt Confirm',
        rolShowQty: RolesApp.appReceiptconfirmQty,
        rolManualQty: RolesApp.appReceiptconfirmManual,
        rolShowScrap: RolesApp.appReceiptconfirmQty,
        rolManualScrap: RolesApp.appReceiptconfirmManual,
        rolCompleteLow: RolesApp.appShipmentLowqty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appReceiptconfirmComplete,
      );
    } else if (type == 'qaconfirm') {
      state = state.copyWith(
        isSOTrx: false,
        mInOutType: MInOutType.qaConfirm,
        title: 'QA Confirm',
        rolShowQty: RolesApp.appQaconfirmQty,
        rolManualQty: RolesApp.appQaconfirmManual,
        rolShowScrap: RolesApp.appQaconfirmQty,
        rolManualScrap: RolesApp.appQaconfirmManual,
        rolCompleteLow: RolesApp.appShipmentLowqty,
        rolCompleteOver: false,
        rolComplete: RolesApp.appQaconfirmComplete,
      );
    } else if (type == 'move') {
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
      );
    } else if (type == 'moveconfirm') {
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
      );
    }
  }

  Future<void> cargarLista(WidgetRef ref) async {
    if (state.mInOutType == MInOutType.move ||
        state.mInOutType == MInOutType.moveConfirm) {
      await getMovementList(ref);
    } else {
      await getMInOutList(ref);
    }
  }

  Future<void> getMInOutList(WidgetRef ref) async {
    state = state.copyWith(isLoadingMInOutList: true, errorMessage: '');
    try {
      final mInOutResponse = await mInOutRepository.getMInOutList(ref);
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

  Future<void> getMovementList(WidgetRef ref) async {
    state = state.copyWith(isLoadingMInOutList: true, errorMessage: '');
    try {
      final mInOutResponse = await mInOutRepository.getMovementList(ref);
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
    if (state.mInOutType == MInOutType.shipment ||
        state.mInOutType == MInOutType.receipt) {
      state = state.copyWith(
        isLoading: true,
        viewMInOut: true,
        errorMessage: '',
      );
    }

    try {
      final mInOutResponse = await mInOutRepository.getMInOut(state.doc, ref);
      print('mInOutResponse ${mInOutResponse.toJson()}');
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
      state = state.copyWith(
        viewMInOut:
            state.mInOutType == MInOutType.receipt ||
            state.mInOutType == MInOutType.shipment,
        mInOut: mInOutResponse.copyWith(lines: filteredLines),
        isLoading: false,
      );
      return mInOutResponse;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
        viewMInOut: false,
      );
      //if(ref.context.mounted)showWarningMessage(ref.context, ref, e.toString());
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
    if (state.doc.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Por favor ingrese un número de documento válido',
      );
      throw Exception('Por favor ingrese un número de documento válido');
    }
    if (state.mInOutType == MInOutType.move) {
      state = state.copyWith(
        isLoading: true,
        viewMInOut: true,
        errorMessage: '',
      );
    }

    try {
      final mInOutResponse = await mInOutRepository.getMovement(state.doc, ref);
      final filteredLines = mInOutResponse.lines
          .where((line) => line.mProductId?.id != null)
          .toList();
      if (state.mInOutType == MInOutType.move) {
        for (int i = 0; i < filteredLines.length; i++) {
          filteredLines[i] = filteredLines[i].copyWith(
            targetQty: filteredLines[i].movementQty,
            verifiedStatus: 'pending',
          );
        }
      }
      state = state.copyWith(
        viewMInOut: state.mInOutType == MInOutType.move,
        mInOut: mInOutResponse.copyWith(lines: filteredLines),
        isLoading: false,
      );
      return mInOutResponse;
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

  void clearMInOutData() {
    print('clearMInOutData');
    state = state.copyWith(
      doc: '',
      mInOut: state.mInOut?.copyWith(id: null, lines: null),
      mInOutList: [],
      mInOutConfirm: state.mInOutConfirm?.copyWith(
        id: null,
        linesConfirm: null,
      ),
      isSOTrx: false,
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

  void confirmManualLine(BuildContext context, Line line) {
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
      updatedMInOutLine('');
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
      updatedMInOutLine('');
    }
  }

  void onEditLocatorChange(String value) {
    state = state.copyWith(editLocator: value, errorMessage: '');
  }

  Future<void> confirmEditLocator(Line line, WidgetRef ref) async {
    String locator = line.mLocatorId!.identifier!.split(' => ').first.trim();
    try {
      final idLocator = await mInOutRepository.getLocator(
        state.editLocator,
        ref,
      );
      final updatedLocator = line.mLocatorId?.copyWith(
        identifier: '$locator => ${state.editLocator}',
      );
      final updatedLine = line.copyWith(
        editLocator: idLocator,
        mLocatorId: updatedLocator,
      );
      final updatedLines = state.mInOut!.lines
          .map((l) => l.id == line.id ? updatedLine : l)
          .toList();
      state = state.copyWith(
        mInOut: state.mInOut!.copyWith(lines: updatedLines),
      );
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
    print(
      'state.mInOut?.docStatus.id ${state.mInOut?.docStatus.id?.toString() ?? 'NULL'}',
    );
    if (((state.mInOutType == MInOutType.shipment ||
                state.mInOutType == MInOutType.receipt) &&
            state.mInOut?.docStatus.id.toString() == 'IP') ||
        state.mInOutType == MInOutType.move) {
      print(
        'state.mInOut?.docStatus.id ${state.mInOut?.docStatus.id?.toString() ?? 'NULL'}',
      );
      return true;
    }
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
    print('setDocAction init');
    state = state.copyWith(isLoading: true, errorMessage: '');
    if (state.mInOut?.id == null) {
      state = state.copyWith(
        errorMessage: '${state.title} ID is null',
        isLoading: false,
      );
      return;
    }
    try {
      print('try setDocAction lines ${state.mInOut!.lines.length}');
      for (final line in state.mInOut!.lines) {
        print('try setDocAction ${line.id ?? '--'}');
        if (line.editLocator != null) {
          print('try setDocAction line.editLocator ${line.editLocator}');
          final update = await mInOutRepository.updateLocator(line, ref);
          print(
            'update  mInOutRepository ${line.id} ${update ? 'true' : 'no true'}',
          );
          if (!update) {
            state = state.copyWith(
              errorMessage:
                  'Error al actualizar la ubicación: ${line.mLocatorId!.identifier}',
              isLoading: false,
            );
            return;
          }
        }
      }
      print('mInOutResponse');
      final mInOutResponse = await mInOutRepository.setDocAction(ref);
      print('update  mInOutRepository ${mInOutResponse.docStatus.identifier}');
      print('setDocAction showMInOutResultModalBottomSheet');

      showMInOutResultModalBottomSheet(
        ref: ref,
        data: mInOutResponse,
        type: MInOutType.move,
        text: '',
        onOk: () async {
          /*print('setDocAction onOk');
          if(mInOutResponse.docStatus.id=='CO' || mInOutResponse.docStatus.id=='IP'){

            onDocChange(state.doc);

            //getMInOutAndLine(ref);
            if(state.mInOutType == MInOutType.moveConfirm || state.mInOutType == MInOutType.move){
                print('setDocAction clearMInOutData');
                await getMovementAndLine(ref);
            }



          }
        */
          /*if(state.mInOutType == MInOutType.moveConfirm || state.mInOutType == MInOutType.move){
            print('setDocAction clearMInOutData');
            await getMovementAndLine(ref);
          }*/
        },
      );
      state = state.copyWith(
        mInOut: mInOutResponse.copyWith(lines: state.mInOut!.lines),
        isLoading: false,
        isComplete: true,

      );
      print(
        'update  mInOutRepository ${mInOutResponse.documentNo?.toString() ?? '--'}',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
    }
  }

  Future<void> setDocActionConfirm(WidgetRef ref) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    print('setDocActionConfirm');

    try {
      for (final line in state.mInOut!.lines) {
        if (line.editLocator != null) {
          print('setDocActionConfirm updateLocator');
          final update = await mInOutRepository.updateLocator(line, ref);
          if (!update) {
            state = state.copyWith(
              errorMessage:
                  'Error al actualizar la ubicación: ${line.mLocatorId!.identifier}',
              isLoading: false,
            );
            return;
          }
        }
        final lineConfirmResponse = await mInOutRepository.updateLineConfirm(
          line,
          ref,
        );
        if (lineConfirmResponse.id == null) {
          state = state.copyWith(
            errorMessage: 'Error al confirmar la línea ${line.line}',
            isLoading: false,
          );
          return;
        }
      }
      print('setDocActionConfirm setDocAction');
      late MInOut result;
      try {
        result = await mInOutRepository.setDocAction(ref);
        print('setDocActionConfirm result ${result.toJson()}');

      } catch (e) {
        print('setDocActionConfirm Error: ${e.toString()}');
        if(ref.context.mounted){
          showErrorMessage(ref.context, ref, e.toString());
        }
        return ;
      }

      state = state.copyWith(
        errorMessage: '',
        isLoading: false,
        isComplete: true,
      );

      showMInOutResultModalBottomSheet(
        ref: ref,
        data: result,
        type: MInOutType.move,
        text: '',
        onOk: () async {

          late MInOutConfirm result2 ;
          if (state.mInOutType == MInOutType.moveConfirm) {
            print('getMovementConfirmAndLine ${state.mInOutConfirm!.id!}');
            result2 = await getMovementConfirmAndLine(state.mInOutConfirm!.id!, ref);
          } else {
            print('getMInOutConfirmAndLine ${state.mInOutConfirm!.id!}');
            result2 = await getMInOutConfirmAndLine(state.mInOutConfirm!.id!, ref);
          }
          print('setDocActionConfirm result2 ${result2.toJson()}');

        },
      );

    } catch (e) {
      print('setDocActionConfirm error ${e.toString()}');
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
    }
  }

 /* Future<void> setDocActionConfirm(WidgetRef ref) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      for (final line in state.mInOut!.lines) {
        if (line.editLocator != null) {
          final update = await mInOutRepository.updateLocator(line, ref);
          if (!update) {
            state = state.copyWith(
              errorMessage:
                  'Error al actualizar la ubicación: ${line.mLocatorId!.identifier}',
              isLoading: false,
            );
            return;
          }
        }
        final lineConfirmResponse = await mInOutRepository.updateLineConfirm(
          line,
          ref,
        );
        if (lineConfirmResponse.id == null) {
          state = state.copyWith(
            errorMessage: 'Error al confirmar la línea ${line.line}',
            isLoading: false,
          );
          return;
        }
      }

      await mInOutRepository.setDocAction(ref);
      if (state.mInOutType == MInOutType.moveConfirm) {
        await getMovementConfirmAndLine(state.mInOutConfirm!.id!, ref);
      } else {
        await getMInOutConfirmAndLine(state.mInOutConfirm!.id!, ref);
      }

      state = state.copyWith(
        errorMessage: '',
        isLoading: false,
        isComplete: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      );
    }
  }*/

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

                          return Card(
                            color: Colors.grey[200],
                            child: ListTile(
                              title: Text('Línea: ${currentLine.line}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cant. Movement: ${currentLine.movementQty ?? 0}',
                                  ),
                                  Text(
                                    'Cant. Manual: ${currentLine.manualQty ?? 0}',
                                  ),
                                  Text(
                                    'Cant. Escaneada: ${currentLine.scanningQty ?? 0}',
                                  ),
                                  Text(
                                    'Cant. Confirmada: ${currentLine.confirmedQty ?? 0}',
                                  ),
                                  Text(
                                    'Cant. Desecho: ${currentLine.scrappedQty ?? 0}',
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
    }
  }

  void updatedMInOutLineOld(String barcode) {
    if (state.mInOut != null && state.viewMInOut) {
      List<Line> lines = state.mInOut!.lines;
      List<Barcode> linesOver = [];

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].verifiedStatus == null ||
            !lines[i].verifiedStatus!.contains('manually') ||
            lines[i].upc == barcode) {
          lines[i] = lines[i].copyWith(
            manualQty: 0,
            scanningQty: 0,
            confirmedQty: 0,
            scrappedQty: 0,
            verifiedStatus: 'pending',
          );
        }
      }

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
    return line.copyWith(
      manualQty: manualQty,
      scanningQty: scanningQty.toInt(),
      confirmedQty: confirmedQty,
      scrappedQty: scrappedQty,
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
}

enum MInOutType {
  shipment,
  shipmentConfirm,
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

  // ROLES
  final bool rolShowQty;
  final bool rolShowScrap;
  final bool rolManualQty;
  final bool rolManualScrap;
  final bool rolCompleteLow;
  final bool rolCompleteOver;
  final bool rolPrepare;
  final bool rolComplete;

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
  });

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
  );
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:monalisa_app_001/config/theme/app_theme.dart';
// import 'tu_path/minout_status.dart'; // donde esté MInOutStatus + MInOutType

/// Provider que devuelve el color de fondo del header según el estado del MInOut
final mInOutHeaderColorProvider = Provider.family<Color, MInOutStatus>((
  ref,
  mInOutState,
) {
  final docStatusId = mInOutState.mInOut?.docStatus.id?.toString();
  final confirmStatusId = mInOutState.mInOutConfirm?.docStatus.id?.toString();

  print('mInOutHeaderColorProvider mInoutColor ${mInOutState.mInOutType}');
  if (mInOutState.mInOutType == MInOutType.move) {
    print('mInoutColor1 ${mInOutState.mInOutType}');
    print('docStatus $docStatusId');
    print('confirmStatusId $confirmStatusId');

    if (docStatusId == 'DR') {
      return themeColorWarningLight;
    } else if (docStatusId == 'IP') {
      return Colors.cyan.shade200;
    } else if (docStatusId == 'CO') {
      return themeColorSuccessfulLight;
    } else {
      return Colors.grey.shade200;
    }
  }
  if (mInOutState.mInOutType == MInOutType.moveConfirm) {
    print('mInoutColor2 ${mInOutState.mInOutType}');
    print('docStatus $docStatusId');
    print('confirmStatusId $confirmStatusId');

    if (confirmStatusId == 'DR') {
      return themeColorWarningLight;
    } else if (confirmStatusId == 'IP') {
      return Colors.cyan.shade200;
    } else if (confirmStatusId == 'CO') {
      return themeColorSuccessfulLight;
    } else {
      return Colors.grey.shade200;
    }
  }

  final type = mInOutState.mInOutType;

  final esInOutNormal =
      type == MInOutType.shipment ||
      type == MInOutType.receipt ||
      type == MInOutType.move ||
      type == MInOutType.moveConfirm;

  if (!esInOutNormal) {
    // usar docStatus del confirm
    if (confirmStatusId == 'IP') {
      return themeColorWarningLight;
    } else if (confirmStatusId == 'CO') {
      return themeColorSuccessfulLight;
    }
  } else {
    // usar docStatus del mInOut principal
    if (docStatusId == 'IP') {
      return themeColorWarningLight;
    } else if (docStatusId == 'CO') {
      return themeColorSuccessfulLight;
    }
  }

  return themeBackgroundColorLight;
});
