import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../config/theme/app_theme.dart';
import '../../../../shared/presentation/widgets/custom_filled_button.dart';
import '../../../../shared/presentation/widgets/custom_text_form_field.dart';
import '../../../domain/entities/barcode.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/m_in_out.dart';
import '../../../domain/entities/m_in_out_confirm.dart';
import '../../providers/m_in_ot_utils.dart';
import '../../providers/m_in_out_providers.dart';
import '../../widgets/barcode_list.dart';

class _MInOutViewOld extends ConsumerWidget {
  final MInOutStatus mInOutState;
  final MInOutNotifier mInOutNotifier;
  final String? initialDocument;

  const _MInOutViewOld(this.initialDocument, {
    required this.mInOutState,
    required this.mInOutNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();

    return SafeArea(
      child: !mInOutState.viewMInOut
          ? Column(
        children: [
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTextFormField(
              keyboardType: TextInputType.text,
              hint: 'Ingresar documento',
              onChanged: mInOutNotifier.onDocChange,
              onFieldSubmitted: (value) async {
                await _loadMInOutAndLine(context, ref);
              },
              prefixIcon: Icon(Icons.qr_code_scanner_rounded),
              suffixIcon: IconButton(
                icon: Icon(Icons.send_rounded),
                color: themeColorPrimary,
                onPressed: () async {
                  await _loadMInOutAndLine(context, ref);
                },
              ),
            ),
          ),
          SizedBox(height: 8),
          if (mInOutState.mInOutList.isNotEmpty) Divider(height: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  _buildMInOutList(ref),
                ],
              ),
            ),
          ),
        ],
      )
          : mInOutState.isLoading
          ? SizedBox(
        child: const Center(child: CircularProgressIndicator()),
      )
          : ListView(
        children: [
          _buildMInOutHeader(context, ref),
          const SizedBox(height: 5),
          _buildActionOrderList(mInOutNotifier),
          const SizedBox(height: 5),
          _buildMInOutLineList(mInOutState, ref),
          mInOutState.linesOver.isNotEmpty
              ? _buildListOver(
            context,
            mInOutState.linesOver,
            mInOutNotifier,
          )
              : SizedBox(),
        ],
      ),
    );
  }

  Future<void> _loadMInOutAndLine(BuildContext context, WidgetRef ref) async {
    if (mInOutState.mInOutType == MInOutType.shipmentConfirm ||
        mInOutState.mInOutType == MInOutType.receiptConfirm ||
        mInOutState.mInOutType == MInOutType.pickConfirm ||
        mInOutState.mInOutType == MInOutType.qaConfirm) {
      _showScreenLoading(context);
      print('------------mInOutType s ${mInOutState.mInOutType}');
      try {
        print('---------try---mInOutType ${mInOutState.mInOutType}');
        final mInOut = await mInOutNotifier.getMInOutAndLine(ref);
        if (mInOut.id != null) {
          final mInOutConfirmList =
          await mInOutNotifier.getMInOutConfirmList(mInOut.id!, ref);
          if (context.mounted) {
            Navigator.of(context).pop();

            if(mInOutConfirmList.isEmpty && mInOutState.mInOutType == MInOutType.pickConfirm){
              //add funtion here
              await showCreatePickOrQaConfirmModalBottomSheet(
                isQaConfirm: false,
                documentNo: mInOutState.doc,
                ref: ref,
                onResultSuccess: () async {
                  print('onResult 2');
                  _loadMInOutAndLine(context, ref);

                },
                type: MInOutType.pickConfirm,
                mInOutId: mInOut.id?.toString() ?? '',
              );
            } else {
              _showSelectMInOutConfirm(
                  mInOutConfirmList, context, mInOutNotifier, mInOutState, ref);
            }

          }
          print('------------mInOut');
        } else if (context.mounted) {
          print('------------mInOutType not found 1');
        }
      } catch (e) {
        print('------------mInOutType not found 2 exception ${mInOutState.mInOutType}');

        if (context.mounted) {
          //Navigator.of(context).pop();




          //Navigator.of(context).pop();
        }
      }
    } else if (mInOutState.mInOutType == MInOutType.moveConfirm) {
      _showScreenLoading(context);
      try {
        final mInOut = await mInOutNotifier.getMovementAndLine(ref);
        if (mInOut.id != null) {
          final mInOutConfirmList =
          await mInOutNotifier.getMovementConfirmList(mInOut.id!, ref);
          if (context.mounted) {
            Navigator.of(context).pop();
            _showSelectMInOutConfirm(
                mInOutConfirmList, context, mInOutNotifier, mInOutState, ref);
          }
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    } else if (mInOutState.mInOutType == MInOutType.move) {
      mInOutNotifier.getMovementAndLine(ref);
    } else {
      mInOutNotifier.getMInOutAndLine(ref);
    }
  }

  Color _getHeaderBackgroundColor(MInOutStatus mInOutState) {
    final docStatusId = mInOutState.mInOut?.docStatus.id.toString();
    final confirmStatusId = mInOutState.mInOutConfirm?.docStatus.id.toString();


    print('mInoutColor ${mInOutState.mInOutType}');
    if (mInOutState.mInOutType == MInOutType.move
        || mInOutState.mInOutType == MInOutType.moveConfirm) {
      print('mInoutColor1 ${MInOutType.move}');
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

    if (mInOutState.mInOutType != MInOutType.shipment &&
        mInOutState.mInOutType != MInOutType.receipt &&
        mInOutState.mInOutType != MInOutType.move &&
        mInOutState.mInOutType != MInOutType.moveConfirm) {
      if (confirmStatusId == 'IP') {
        return themeColorWarningLight;
      } else if (confirmStatusId == 'CO') {
        return themeColorSuccessfulLight;
      }
    } else {


      if (docStatusId == 'IP') {
        return themeColorWarningLight;
      } else if (docStatusId == 'CO') {
        return themeColorSuccessfulLight;
      }
    }
    return themeBackgroundColorLight;
  }

  Widget _buildMInOutHeader(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(themeBorderRadius),
              //color: _getHeaderBackgroundColor(mInOutState),
              color: ref.watch(mInOutHeaderColorProvider(mInOutState)),

            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document No.: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (mInOutState.mInOutType == MInOutType.shipmentConfirm ||
                        mInOutState.mInOutType == MInOutType.receiptConfirm ||
                        mInOutState.mInOutType == MInOutType.pickConfirm ||
                        mInOutState.mInOutType == MInOutType.qaConfirm)
                      Text(
                        'Confirm No.: ',
                        style: const TextStyle(
                          fontSize: themeFontSizeSmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      'Date: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'O. Date: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Org.: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Whs.: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'BP: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      mInOutState.title.contains(' Confirm')
                          ? '${mInOutState.title.replaceAll(' Confirm', '')} Status: '
                          : 'Status: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (mInOutState.mInOutType == MInOutType.shipmentConfirm ||
                        mInOutState.mInOutType == MInOutType.receiptConfirm ||
                        mInOutState.mInOutType == MInOutType.pickConfirm ||
                        mInOutState.mInOutType == MInOutType.qaConfirm)
                      Text(
                        'Confirm Status: ',
                        style: const TextStyle(
                          fontSize: themeFontSizeSmall,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mInOutState.mInOut!.documentNo ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    if (mInOutState.mInOutType == MInOutType.shipmentConfirm ||
                        mInOutState.mInOutType == MInOutType.receiptConfirm ||
                        mInOutState.mInOutType == MInOutType.pickConfirm ||
                        mInOutState.mInOutType == MInOutType.qaConfirm)
                      Text(
                        mInOutState.mInOutConfirm!.documentNo ?? '',
                        style: TextStyle(fontSize: themeFontSizeSmall),
                      ),
                    Text(
                      mInOutState.mInOut!.movementDate != null
                          ? DateFormat('dd/MM/yyyy')
                          .format(mInOutState.mInOut!.movementDate!)
                          : '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut!.cOrderId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut!.dateOrdered != null
                          ? DateFormat('dd/MM/yyyy')
                          .format(mInOutState.mInOut!.dateOrdered!)
                          : '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut!.adOrgId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut!.mWarehouseId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut!.cBPartnerId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut!.docStatus.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    if (mInOutState.mInOutType == MInOutType.shipmentConfirm ||
                        mInOutState.mInOutType == MInOutType.receiptConfirm ||
                        mInOutState.mInOutType == MInOutType.pickConfirm ||
                        mInOutState.mInOutType == MInOutType.qaConfirm)
                      Text(
                        mInOutState.mInOutConfirm!.docStatus.identifier ?? '',
                        style: TextStyle(fontSize: themeFontSizeSmall),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: Icon(Icons.clear, size: 20),
              onPressed: mInOutState.scanBarcodeListTotal.isNotEmpty
                  ? () => _showConfirmclearMInOutData(
                  context, mInOutNotifier, mInOutState, ref)
                  : () async {
                mInOutNotifier.clearMInOutData();
                await mInOutNotifier.loadDataList(ref);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionOrderList(MInOutNotifier mInOutNotifier) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // pendiente
        _buildOrderList(
          icon: Icons.circle_outlined,
          color: themeColorError,
          background: themeColorErrorLight,
          onPressed: () => mInOutNotifier.setOrderBy('pending'),
          name: 'pending',
        ),
        SizedBox(width: 4),
        // menor
        _buildOrderList(
          icon: Icons.radio_button_checked_rounded,
          color: themeColorWarning,
          background: themeColorWarningLight,
          onPressed: () => mInOutNotifier.setOrderBy('minor'),
          name: 'minor',
        ),
        SizedBox(width: 4),
        // supera
        _buildOrderList(
          icon: Icons.warning_amber_rounded,
          color: themeColorWarning,
          background: themeColorWarningLight,
          onPressed: () => mInOutNotifier.setOrderBy('over'),
          name: 'over',
        ),
        SizedBox(width: 4),
        // manual
        _buildOrderList(
          icon: Icons.touch_app_outlined,
          color: themeColorSuccessful,
          background: themeColorSuccessfulLight,
          onPressed: () => mInOutNotifier.setOrderBy('manually'),
          name: 'manually',
        ),
        SizedBox(width: 4),
        // correcto
        _buildOrderList(
          icon: Icons.check_circle_outline_rounded,
          color: themeColorSuccessful,
          background: themeColorSuccessfulLight,
          onPressed: () => mInOutNotifier.setOrderBy('correct'),
          name: 'correct',
        ),
      ],
    );
  }

  Widget _buildOrderList({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required Color background,
    required String name,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(themeBorderRadius),
          color: mInOutState.orderBy == name
              ? background
              : themeBackgroundColorLight,
        ),
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.straight_rounded,
                  size: 18,
                  color: mInOutState.orderBy == name ? color : themeColorGray),
              Icon(icon,
                  size: 18,
                  color: mInOutState.orderBy == name ? color : themeColorGray),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMInOutList(WidgetRef ref) {
    final mInOutList = mInOutState.mInOutList;
    return mInOutList.isNotEmpty
        ? Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mInOutList.length,
          itemBuilder: (context, index) {
            final item = mInOutList[index];
            return GestureDetector(
              onTap: () async {
                mInOutNotifier.onDocChange(item.documentNo.toString());
                await _loadMInOutAndLine(context, ref);
              },
              child: Column(
                children: [
                  Divider(height: 0),
                  Container(
                    color: item.docStatus.id == 'IP'
                        ? themeColorWarningLight
                        : null,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                          child: Text(
                            item.movementDate != null
                                ? DateFormat('dd/MM/yyyy')
                                .format(item.movementDate!)
                                : '',
                            style: TextStyle(
                                fontSize: themeFontSizeSmall,
                                color: themeColorGray),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              item.documentNo.toString(),
                              style: const TextStyle(
                                fontSize: themeFontSizeLarge,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: GestureDetector(
                            onTap: () => _showMInOutData(context, item),
                            child: Icon(
                              Icons.info_rounded,
                              color: themeColorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 0),
                ],
              ),
            );
          },
        ),
      ],
    )
        : mInOutState.isLoadingMInOutList
        ? Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    )
        : Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: CustomFilledButton(
          label: 'Cargar lista',
          onPressed: () async {
            await mInOutNotifier.loadDataList(ref);
          },
        ),
      ),
    );
  }
  Future<void> _showSelectMInOutConfirm(
      List<MInOutConfirm> mInOutConfirmList,
      BuildContext context,
      MInOutNotifier mInOutNotifier,
      MInOutStatus mInOutState,
      WidgetRef ref,
      ) {
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

                    return InkWell(
                      onTap: () {
                        if (mInOutState.mInOutType == MInOutType.moveConfirm) {
                          mInOutNotifier.getMovementConfirmAndLine(item.id!, ref);
                        } else {
                          mInOutNotifier.getMInOutConfirmAndLine(item.id!, ref);
                        }
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.documentNo.toString(),
                              style: const TextStyle(
                                fontSize: themeFontSizeLarge,
                                fontWeight: FontWeight.bold,
                              ),
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


  Future<void> _showMInOutData(BuildContext context, MInOut mInOut) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: Text(mInOutState.title),
          content: SingleChildScrollView(
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doc. No.: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Date: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'O. Date: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Org.: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Whs.: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'BP: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Status: ',
                      style: const TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mInOut.documentNo ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOut.movementDate != null
                          ? DateFormat('dd/MM/yyyy')
                          .format(mInOut.movementDate!)
                          : '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOut.cOrderId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOut.dateOrdered != null
                          ? DateFormat('dd/MM/yyyy').format(mInOut.dateOrdered!)
                          : '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOut.adOrgId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOut.mWarehouseId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOut.cBPartnerId.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOut.docStatus.identifier ?? '',
                      style: TextStyle(fontSize: themeFontSizeSmall),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Cerrar',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMInOutLineList(MInOutStatus mInOutState, WidgetRef ref) {
    final mInOutLines = mInOutState.mInOut?.lines ?? [];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mInOutLines.length,
      itemBuilder: (context, index) {
        final item = mInOutLines[index];
        return GestureDetector(
          onTap: () =>
              _selectLine(context, mInOutNotifier, mInOutState, item, ref),
          child: Column(
            children: [
              Divider(height: 0),
              Container(
                color: item.verifiedStatus == 'over' ||
                    item.verifiedStatus == 'manually-over'
                    ? themeColorWarningLight
                    : null,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Text(
                        item.line.toString(),
                        style: TextStyle(
                            fontSize: themeFontSizeSmall,
                            color: themeColorGray),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                item.upc?.isNotEmpty == true
                                    ? item.upc.toString()
                                    : '',
                                style: const TextStyle(
                                  fontSize: themeFontSizeLarge,
                                ),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.sku ?? ''} - ${item.productName.toString()}',
                                style: TextStyle(
                                  fontSize: themeFontSizeSmall,
                                  color: themeColorGray,
                                ),
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '${item.mLocatorId!.identifier}',
                                style: TextStyle(
                                  fontSize: themeFontSizeSmall,
                                  color: themeColorGray,
                                ),
                              ),
                            ),
                          ),
                          // SingleChildScrollView(
                          //   scrollDirection: Axis.horizontal,
                          //   child: Text(
                          //     'Tar:${item.targetQty}/Man:${item.manualQty}/Sca:${item.scanningQty}/Con:${item.confirmedQty}/Scr:${item.scrappedQty}',
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                    mInOutState.rolShowQty
                        ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        item.targetQty.toString(),
                        style: const TextStyle(
                            fontSize: themeFontSizeLarge,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                        : SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        item.verifiedStatus == 'correct'
                            ? Icons.check_circle_outline_rounded
                            : item.verifiedStatus == 'over'
                            ? Icons.warning_amber_rounded
                            : item.verifiedStatus == 'manually-correct' ||
                            item.verifiedStatus ==
                                'manually-minor' ||
                            item.verifiedStatus == 'manually-over'
                            ? Icons.touch_app_outlined
                            : item.verifiedStatus == 'minor'
                            ? Icons.radio_button_checked_rounded
                            : Icons.circle_outlined,
                        color: item.verifiedStatus == 'correct' ||
                            item.verifiedStatus == 'manually-correct'
                            ? themeColorSuccessful
                            : item.verifiedStatus == 'minor' ||
                            item.verifiedStatus == 'over' ||
                            item.verifiedStatus == 'manually-minor' ||
                            item.verifiedStatus == 'manually-over'
                            ? themeColorWarning
                            : themeColorError,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 0),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showConfirmclearMInOutData(BuildContext context,
      MInOutNotifier mInOutNotifier, MInOutStatus mInOutState, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: Text('Limpiar ${mInOutState.title}'),
          content: Text(
              '¿Estás seguro de que deseas limpiar este ${mInOutState.title}?'),
          actions: <Widget>[
            CustomFilledButton(
              onPressed: () async {
                mInOutNotifier.clearMInOutData();
                Navigator.of(context).pop();
                await mInOutNotifier.loadDataList(ref);
              },
              label: 'Si',
              icon: const Icon(Icons.check),
              buttonColor: themeColorError,
            ),
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'No',
              icon: const Icon(Icons.close_rounded),
              buttonColor: themeColorGray,
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectLine(BuildContext context, MInOutNotifier mInOutNotifier,
      MInOutStatus mInOutState, Line item, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Detalles de la Línea'),
          content: SingleChildScrollView(

            child: Column(
              children: [
                Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow("UPC:", item.upc?.toString() ?? '', false),
                    _buildTableRow("SKU:", item.sku?.toString() ?? '', false),
                    _buildTableRow(
                        "Producto:", item.productName?.toString() ?? '', false),
                    _buildTableRow("Estante:",
                        item.mLocatorId?.identifier.toString() ?? '', false),
                    if (mInOutState.rolShowQty)
                      _buildTableRow(
                          "Cantidad:", item.targetQty?.toString() ?? '0', true),
                    _buildTableRow("Escaneado:",
                        item.scanningQty?.toString() ?? '0', true),
                    if (item.verifiedStatus?.contains('manually') ?? false)
                      _buildTableRow("Conf. Manual:",
                          item.manualQty?.toString() ?? '0', true),
                    if (mInOutState.rolShowScrap)
                      _buildTableRow("Desechado:",
                          item.scrappedQty?.toString() ?? '0', true),
                    if (mInOutState.rolShowQty)
                      _buildTableRow("Diferencia:",
                          item.differenceQty?.toString() ?? '0', true),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            if (mInOutState.rolManualQty && (item.verifiedStatus?.contains('manually') ?? false))
              CustomFilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  mInOutNotifier.onManualQuantityChange('${item.manualQty ?? 0}');
                  mInOutNotifier.onManualScrappedChange('${item.scrappedQty ?? 0}');
                  _showUpdateManualLine(context, mInOutState, item);
                },
                //
                label: 'Editar',
                icon: const Icon(Icons.edit),
                buttonColor: themeColorGray,
                expand: true,
                small: true,
              ),
            if (mInOutState.rolManualQty)
              CustomFilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (item.verifiedStatus?.contains('manually') ?? false) {
                    _showResetManualLine(context, item);
                  } else {
                    mInOutNotifier.onManualQuantityChange('0');
                    mInOutNotifier.onManualScrappedChange('0');
                    _showInsertManualLine(context, mInOutState, item);
                  }
                },
                //
                label: (item.verifiedStatus?.contains('manually') ?? false)
                    ? 'Resetear'
                    : 'Manual',
                icon: const Icon(Icons.touch_app_outlined),
                buttonColor: themeColorGray,
                expand: true,
                small: true,
              ),
            CustomFilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showEditLocator(context, mInOutState, item, ref);
              },
              label: 'Estante',
              icon: const Icon(Icons.view_in_ar),
              labelColor: Colors.black87,
              buttonColor: themeColorWarning,
              expand: true,
              small: true,
            ),
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Cerrar',
              icon: const Icon(Icons.close_rounded),
              expand: true,
              small: true,
            ),
          ],
        );
      },
    );
  }

  Future<void> _showInsertManualLine(
      BuildContext context, MInOutStatus mInOutState, Line item) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Confirmar Manual'),
          content: Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  label: 'Confirmar',
                  textAlign: TextAlign.center,
                  initialValue: '',
                  onChanged: mInOutNotifier.onManualQuantityChange,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                ),
              ),
              if (mInOutState.rolManualScrap) SizedBox(width: 8),
              if (mInOutState.rolManualScrap)
                Expanded(
                  child: CustomTextFormField(
                    label: 'Desechar',
                    textAlign: TextAlign.center,
                    initialValue: '',
                    onChanged: mInOutNotifier.onManualScrappedChange,
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            CustomFilledButton(
              onPressed: () {
                mInOutNotifier.confirmManualLine(context,item);
                Navigator.of(context).pop();
              },
              label: 'Confirmar',
              icon: const Icon(Icons.check),
            ),
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Cancelar',
              icon: const Icon(Icons.close_rounded),
              buttonColor: themeColorGray,
            ),
          ],
        );
      },
    );
  }
  Future<void> _showUpdateManualLine(
      BuildContext context, MInOutStatus mInOutState, Line item) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Confirmar Manual'),
          content: Row(
            children: [
              Expanded(
                child: CustomTextFormField(
                  label: 'Confirmar',
                  textAlign: TextAlign.center,
                  initialValue: '${item.manualQty ?? 0}',
                  onChanged: mInOutNotifier.onManualQuantityChange,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                ),
              ),
              if (mInOutState.rolManualScrap) SizedBox(width: 8),
              if (mInOutState.rolManualScrap)
                Expanded(
                  child: CustomTextFormField(
                    label: 'Desechar',
                    textAlign: TextAlign.center,
                    initialValue: '',
                    onChanged: mInOutNotifier.onManualScrappedChange,
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            CustomFilledButton(
              onPressed: () {
                mInOutNotifier.confirmManualLine(context,item);
                Navigator.of(context).pop();
              },
              label: 'Confirmar',
              icon: const Icon(Icons.check),
            ),
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Cancelar',
              icon: const Icon(Icons.close_rounded),
              buttonColor: themeColorGray,
            ),
          ],
        );
      },
    );
  }

  Future<void> _showResetManualLine(BuildContext context, Line line) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Resetear Manual'),
          content: const Text(
              '¿Estás seguro de que deseas resetear la confirmación manual?'),
          actions: <Widget>[
            CustomFilledButton(
              onPressed: () {
                mInOutNotifier.resetManualLine(line);
                Navigator.of(context).pop();
              },
              label: 'Si',
              icon: const Icon(Icons.check),
              buttonColor: themeColorError,
            ),
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'No',
              icon: const Icon(Icons.close_rounded),
              buttonColor: themeColorGray,
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditLocator(BuildContext context, MInOutStatus mInOutState,
      Line item, WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Cambiar Estante'),
          content: CustomTextFormField(
            label: 'Estante Nueva',
            initialValue: '',
            onChanged: mInOutNotifier.onEditLocatorChange,
            autofocus: true,
          ),
          actions: <Widget>[
            CustomFilledButton(
              onPressed: () {
                mInOutNotifier.confirmEditLocator(item, ref);
                Navigator.of(context).pop();
              },
              label: 'Confirmar',
              icon: const Icon(Icons.check),
            ),
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Cancelar',
              icon: const Icon(Icons.close_rounded),
              buttonColor: themeColorGray,
            ),
          ],
        );
      },
    );
  }

  Column _buildListOver(BuildContext context, List<Barcode> barcodeList,
      MInOutNotifier mInOutNotifier) {

    return Column(
      children: [
        SizedBox(height: 32),
        Text('Productos a remover',
            style:
            TextStyle(fontSize: themeFontSizeSmall, color: themeColorGray)),
        SizedBox(height: 4),
        Divider(height: 0),
        Column(
          children: barcodeList.map((barcode) {
            return BarcodeList(
              barcode: barcode,
              onPressedDelete: () =>
                  _showConfirmDeleteItemOver(context, mInOutNotifier, barcode),
              onPressedrepetitions: () =>
                  mInOutNotifier.selectRepeat(barcode.code),
              mInOutNotifier: mInOutNotifier,
            );
          }).toList(),
        ),
        SizedBox(height: 4),
      ],
    );
  }

  Future<void> _showConfirmDeleteItemOver(
      BuildContext context, MInOutNotifier mInOutNotifier, Barcode barcode) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Eliminar Código'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar este código de barras?'),
          actions: <Widget>[
            CustomFilledButton(
              onPressed: () {
                mInOutNotifier.removeBarcode(barcode: barcode, isOver: true,context: context);
                Future.delayed(const Duration(milliseconds: 500), () {
                });
                Navigator.of(context).pop();
              },
              label: 'Si',
              icon: const Icon(Icons.check),
              buttonColor: themeColorError,
            ),
            CustomFilledButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'No',
              icon: const Icon(Icons.close_rounded),
              buttonColor: themeColorGray,
            ),
          ],
        );
      },
    );
  }

  void _showScreenLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            color: themeBackgroundColor,
          ),
        );
      },
    );
  }
}
TableRow _buildTableRow(String label, String value, bool alignRight) {

  return TableRow(
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
        alignment: alignRight ? AlignmentDirectional(-1, -0.3) : null,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      Container(
        padding: EdgeInsets.fromLTRB(4, 2, alignRight ? 22 : 0, 2),
        alignment: alignRight ? AlignmentDirectional(1, -0.3) : null,
        child: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.normal,
            color: themeColorGray,
          ),
        ),
      ),
    ],
  );
}