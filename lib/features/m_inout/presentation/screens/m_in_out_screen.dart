import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:monalisa_app_001/config/config.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/m_in_out_confirm.dart';
import 'package:monalisa_app_001/features/shared/shared.dart';
import 'package:monalisa_app_001/features/m_inout/domain/entities/line.dart';
import 'package:monalisa_app_001/features/m_inout/presentation/widgets/barcode_list.dart';
import 'package:intl/intl.dart';
import '../../../products/common/selections_dialog.dart';
import '../../../products/presentation/providers/common_provider.dart';
import '../../domain/entities/barcode.dart';
import '../providers/m_in_out_providers.dart';
import '../widgets/enter_barcode_button.dart';

class MInOutScreen extends ConsumerStatefulWidget {
  final String type;
  final String documentNo;

  const MInOutScreen({super.key, required this.type,required this.documentNo});

  @override
  MInOutScreenState createState() => MInOutScreenState();
}

class MInOutScreenState extends ConsumerState<MInOutScreen> {
  late MInOutNotifier mInOutNotifier;
  late String documentNo;


  @override
  void initState() {
    super.initState();
    documentNo = widget.documentNo ;
    int quantityToAllow = ref.read(
      quantityOfMovementAndScannedToAllowInputScannedQuantityProvider,
    );
    if(quantityToAllow >1){
      quantityOfMovementAndScannedToAllowInputScannedQuantity = quantityToAllow;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mInOutNotifier = ref.read(mInOutProvider.notifier);
      mInOutNotifier.setParameters(widget.type);
      if(documentNo.isNotEmpty && documentNo !='-1'){
        print('----documentNo: $documentNo');

        //String message = Messages.PASTE_THE_DOCUMENT_NUMBER_IN_THE_FIELD_THEN_SEARCH ;
        //showWarningMessage(context, ref, message);
      } else {
        mInOutNotifier.cargarLista(ref);
      }

    });
  }

  @override
  Widget build(BuildContext context) {
    final mInOutState = ref.watch(mInOutProvider);
    final mInOutNotifier = ref.read(mInOutProvider.notifier);

    ref.listen(mInOutProvider, (previous, next) {
      if (next.errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage)));
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (mInOutState.scanBarcodeListTotal.isNotEmpty &&
            !mInOutState.isComplete) {
          final shouldPop = await _showExitConfirmationDialog(context);
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
            mInOutNotifier.clearMInOutData();
          }
        } else {
          Navigator.of(context).pop();
          mInOutNotifier.clearMInOutData();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            appBar: AppBar(
              title: TabBar(
                tabs: [
                  Tab(text: mInOutState.title),
                  Tab(text: 'Scan'),
                ],
                isScrollable: true,
                indicatorWeight: 4,
                indicatorColor: themeColorPrimary,
                dividerColor: themeColorPrimary,
                tabAlignment: TabAlignment.start,
                labelStyle: TextStyle(
                    fontSize: themeFontSizeTitle,
                    fontWeight: FontWeight.bold,
                    color: themeColorPrimary),
                unselectedLabelStyle: TextStyle(fontSize: themeFontSizeLarge),
              ),
              actions: mInOutState.viewMInOut &&
                  !mInOutState.isComplete &&
                  mInOutState.mInOut?.docStatus.id.toString() != 'CO'
                  ? [
                IconButton(
                  onPressed: mInOutNotifier.isRolComplete()
                      ? mInOutNotifier.isConfirmMInOut()
                      ? mInOutState.mInOutType ==
                      MInOutType.shipment ||
                      mInOutState.mInOutType ==
                          MInOutType.receipt ||
                      mInOutState.mInOutType ==
                          MInOutType.move
                      ? () {
                    print(' mInOutNotifier.setDocAction');
                      mInOutNotifier.setDocAction(ref);
                    }
                      : () {
                    print(' mInOutNotifier.setDocActionConfirm');
                    mInOutNotifier.setDocActionConfirm(ref);}
                      : () {
                    print(' mInOutNotifier._showConfirmMInOut');
                    _showConfirmMInOut(context);
                  }
                      : () {
                    print(' mInOutNotifier._showWithoutRole');
                    _showWithoutRole(context);
                  },
                  icon: Icon(
                    Icons.check,
                    color: mInOutNotifier.isConfirmMInOut()
                    //? themeColorSuccessful
                        ? Colors.purple
                        : null,
                  ),
                ),
              ]
                  : null,
            ),
            body: TabBarView(
              children: [
                _MInOutView(mInOutState: mInOutState, mInOutNotifier: mInOutNotifier,
                  initialDocumentNo: widget.documentNo.isNotEmpty ? widget.documentNo : '',),
                _ScanView(
                    mInOutState: mInOutState, mInOutNotifier: mInOutNotifier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showConfirmMInOut(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Confirmar Lineas'),
          content: const Text(
              'Por favor, verifica las líneas. Puede que falten códigos por escanear o que se hayan escaneado de más.'),
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

  Future<void> _showWithoutRole(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: const Text('Acción no permitida'),
          content: const Text(
              'No tienes los roles necesarios para realizar esta acción.'),
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

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeBorderRadius),
        ),
        title: const Text('¿Salir?'),
        content: const Text(
            '¿Realmente deseas salir de esta pantalla? Se perderá todo el trabajo actual realizado.'),
        actions: <Widget>[
          CustomFilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            label: 'Si',
            icon: const Icon(Icons.check),
            buttonColor: themeColorError,
          ),
          CustomFilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'No',
            icon: const Icon(Icons.close_rounded),
            buttonColor: themeColorGray,
          ),
        ],
      ),
    ) ??
        false;
  }
}
class _MInOutView extends ConsumerStatefulWidget {
  final MInOutStatus mInOutState;
  final MInOutNotifier mInOutNotifier;
  final String initialDocumentNo;

  const _MInOutView({
    required this.mInOutState,
    required this.mInOutNotifier,
    required this.initialDocumentNo,
  });

  @override
  ConsumerState<_MInOutView> createState() => _MInOutViewState();
}

class _MInOutViewState extends ConsumerState<_MInOutView> {
  late final MInOutStatus mInOutState;
  late final MInOutNotifier mInOutNotifier;
  bool _sentInitialToNotifier = false;
  String initialDocumentNo = '';


  @override
  void initState() {
    super.initState();
    mInOutState = widget.mInOutState;
    mInOutNotifier = widget.mInOutNotifier;
    // Envia o valor inicial para o notifier só uma vez
    if (widget.initialDocumentNo.isNotEmpty && widget.initialDocumentNo != '-1') {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!_sentInitialToNotifier) {
          widget.mInOutNotifier.onDocChange(widget.initialDocumentNo);
          //await Future.delayed(Duration(microseconds: 100));
          if(context.mounted){
            _loadMInOutAndLine(context, ref);
            _sentInitialToNotifier = true;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mInOutState = widget.mInOutState;
    final mInOutNotifier = widget.mInOutNotifier;

    return SafeArea(
      child: !mInOutState.viewMInOut
          ? Column(
        children: [
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomTextFormField(
              label: 'Documento',
              keyboardType: TextInputType.text,
              hint: 'Ingresar documento',
              onChanged: (value) {
                mInOutNotifier.onDocChange(value);
              },
              onFieldSubmitted: (value) async {
                await _loadMInOutAndLine(context, ref);
              },
              prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded),
                color: themeColorPrimary,
                onPressed: () async {
                  await _loadMInOutAndLine(context, ref);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (mInOutState.mInOutList.isNotEmpty) const Divider(height: 0),
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
          ? const Center(child: CircularProgressIndicator())
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
              : const SizedBox(),
        ],
      ),
    );
  }

  Future<void> _loadMInOutAndLine(BuildContext context, WidgetRef ref) async {
    final mInOutState = widget.mInOutState;
    final mInOutNotifier = widget.mInOutNotifier;

    if (mInOutState.mInOutType == MInOutType.shipmentConfirm ||
        mInOutState.mInOutType == MInOutType.receiptConfirm ||
        mInOutState.mInOutType == MInOutType.pickConfirm ||
        mInOutState.mInOutType == MInOutType.qaConfirm) {
      _showScreenLoading(context);

      try {
        final mInOut = await mInOutNotifier.getMInOutAndLine(ref);
        if (mInOut.id != null) {
          final mInOutConfirmList =
          await mInOutNotifier.getMInOutConfirmList(mInOut.id!, ref);
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

  // ---------- resto dos métodos auxiliares (_buildMInOutHeader, _buildActionOrderList, etc.) ----------
  // Aqui eu só reaproveito exatamente o que você já tinha.
  // Só copiei de volta, sem alterações de lógica:

  Color _getHeaderBackgroundColor(MInOutStatus mInOutState) {
    final docStatusId = mInOutState.mInOut?.docStatus.id.toString();
    final confirmStatusId = mInOutState.mInOutConfirm?.docStatus.id.toString();

    print('mInoutColor ${mInOutState.mInOutType}');
    if (mInOutState.mInOutType == MInOutType.move ||
        mInOutState.mInOutType == MInOutType.moveConfirm) {
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


  Widget _buildMInOutHeader(BuildContext context, WidgetRef ref) {
    final mInOutState = widget.mInOutState;
    final mInOutNotifier = widget.mInOutNotifier;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(themeBorderRadius),
              color: ref.watch(mInOutHeaderColorProvider(mInOutState)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Document No.: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Confirm No.: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Date: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Order: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'O. Date: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Org.: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Whs.: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'BP: ',
                      style: TextStyle(
                        fontSize: themeFontSizeSmall,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mInOutState.mInOut?.documentNo ?? '',
                      style: const TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    if (mInOutState.mInOutType == MInOutType.shipmentConfirm ||
                        mInOutState.mInOutType == MInOutType.receiptConfirm ||
                        mInOutState.mInOutType == MInOutType.pickConfirm ||
                        mInOutState.mInOutType == MInOutType.qaConfirm)
                      Text(
                        mInOutState.mInOutConfirm?.documentNo ?? '',
                        style:
                        const TextStyle(fontSize: themeFontSizeSmall),
                      ),
                    Text(
                      mInOutState.mInOut?.movementDate != null
                          ? DateFormat('dd/MM/yyyy').format(
                        mInOutState.mInOut!.movementDate!,
                      )
                          : '',
                      style: const TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut?.cOrderId.identifier ?? '',
                      style: const TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut?.dateOrdered != null
                          ? DateFormat('dd/MM/yyyy').format(
                        mInOutState.mInOut!.dateOrdered!,
                      )
                          : '',
                      style: const TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut?.adOrgId.identifier ?? '',
                      style: const TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut?.mWarehouseId.identifier ?? '',
                      style: const TextStyle(fontSize: themeFontSizeSmall),
                    ),
                    Text(
                      mInOutState.mInOut?.cBPartnerId.identifier ?? '',
                      style: const TextStyle(fontSize: themeFontSizeSmall),
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
              icon: const Icon(Icons.clear, size: 20),
              onPressed: mInOutState.scanBarcodeListTotal.isNotEmpty
                  ? () => _showConfirmclearMInOutData(
                context,
                mInOutNotifier,
                mInOutState,
                ref,
              )
                  : () {
                mInOutNotifier.clearMInOutData();
                mInOutNotifier.cargarLista(ref);
              },
            ),
          ),
        ],
      ),
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
            initialValue: _sentInitialToNotifier ? '' :initialDocumentNo,
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
          onPressed: () {
            mInOutNotifier.cargarLista(ref);
          },
        ),
      ),
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
              onPressed: () {
                mInOutNotifier.clearMInOutData();
                Navigator.of(context).pop();
                mInOutNotifier.cargarLista(ref);
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


// ... aqui continuam os outros métodos (_buildActionOrderList, _buildMInOutList, etc.)
// Você pode manter exatamente os que já tinha no seu arquivo original.
}


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

      try {
        final mInOut = await mInOutNotifier.getMInOutAndLine(ref);
        if (mInOut.id != null) {
          final mInOutConfirmList =
          await mInOutNotifier.getMInOutConfirmList(mInOut.id!, ref);
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
                  : () {
                mInOutNotifier.clearMInOutData();
                mInOutNotifier.cargarLista(ref);
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
          onPressed: () {
            mInOutNotifier.cargarLista(ref);
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


  /*Future<void> _showSelectMInOutConfirm(
      List<MInOutConfirm> mInOutConfirmList,
      BuildContext context,
      MInOutNotifier mInOutNotifier,
      MInOutStatus mInOutState,
      WidgetRef ref) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(themeBorderRadius),
          ),
          title: Text('Seleccione el ${mInOutState.title}'),
          content: mInOutConfirmList.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mInOutConfirmList.length,
            itemBuilder: (context, index) {
              final item = mInOutConfirmList[index];
              return GestureDetector(
                onTap: () {
                  MInOutType.moveConfirm == mInOutState.mInOutType
                      ? mInOutNotifier.getMovementConfirmAndLine(
                      item.id!, ref)
                      : mInOutNotifier.getMInOutConfirmAndLine(
                      item.id!, ref);
                  Navigator.of(context).pop();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(height: 0),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        item.documentNo.toString(),
                        style: const TextStyle(
                          fontSize: themeFontSizeLarge,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        item.mInOutId.identifier ?? '',
                        style: TextStyle(
                            fontSize: themeFontSizeSmall,
                            color: themeColorGray),
                      ),
                    ),
                    Divider(height: 0),
                  ],
                ),
              );
            },
          )
              : Text('No hay confirmaciones pendientes.'),
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
  }*/
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
              onPressed: () {
                mInOutNotifier.clearMInOutData();
                Navigator.of(context).pop();
                mInOutNotifier.cargarLista(ref);
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

class _ScanView extends ConsumerWidget {
  final MInOutStatus mInOutState;
  final MInOutNotifier mInOutNotifier;

  const _ScanView({
    required this.mInOutState,
    required this.mInOutNotifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barcodeList = mInOutState.uniqueView
        ? mInOutState.scanBarcodeListUnique
        : mInOutState.scanBarcodeListTotal;

    return SafeArea(
      child: Column(
        children: [
          SizedBox(height: 4),
          _buildActionFilterList(ref,mInOutNotifier),
          SizedBox(height: 8),
          Divider(height: 0),
          _buildBarcodeList(barcodeList, mInOutNotifier),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: EnterBarcodeButton(mInOutNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFilterList(WidgetRef ref,MInOutNotifier mInOutNotifier) {
    final adjustScanned = ref.watch(adjustScannedQtyProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFilterList(
          text: 'Total',
          counting: mInOutNotifier.getTotalCount().toString(),
          isActive: !mInOutNotifier.getUniqueView(),
          onPressed: () => mInOutNotifier.setUniqueView(false),
        ),
        SizedBox(width: 8),
        _buildFilterList(
          text: 'Únicos',
          counting: mInOutNotifier.getUniqueCount().toString(),
          isActive: mInOutNotifier.getUniqueView(),
          onPressed: () => mInOutNotifier.setUniqueView(true),
        ),
        SizedBox(width: 8),
        Row(
          children: [
            Checkbox(
              activeColor: Colors.purple,
              value: adjustScanned,
              onChanged: (value) {
                if (value != null) {
                  ref.read(adjustScannedQtyProvider.notifier).state = value;
                }
              },
            ),
            GestureDetector(
                onTap: () {
                  showDialog(
                    context: ref.context,
                    builder: (BuildContext context) {
                      final qty = ref.read(
                        quantityOfMovementAndScannedToAllowInputScannedQuantityProvider,
                      );
                      return AlertDialog(
                        title: const Text('Ajustar Cantidad'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('La funcion de ajuste de cantidad se ejecutará cuando:'),
                              SizedBox(height: 8),
                              Text('A. Ajustable:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('1. el movementQty > $qty o diferencia entre movementQty y scannedQty > $qty.'),
                              SizedBox(height: 8),
                              Text('B. No ajustable(Se muestra siemple):', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('1. En caso de contener múltiples lineas con el miso UPC.'),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cerrar'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },),
                        ],
                      );
                    },
                  );
                },
                child: const Text("Ajustar",style: TextStyle(color: Colors.purple),)),
            IconButton(
              icon: const Icon(Icons.settings,color: Colors.purple),
              onPressed: () {
                showDialog(
                  context: ref.context,
                  builder: (BuildContext context) {
                    return Consumer(
                      builder: (context, ref, _) {
                        final selectedAction =
                        ref.watch(defaultActionWhenUPCIsScannedProvider);

                        final qty = ref.watch(
                          quantityOfMovementAndScannedToAllowInputScannedQuantityProvider,
                        );

                        return AlertDialog(
                          title: const Text('AJUSTES'),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔽 Texto explicativo para la acción por defecto
                                const Text(
                                  'Cuando se escanea un UPC existente, '
                                      '¿qué acción predeterminada le gustaría tomar?',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                verticalSegmentedButtons(
                                  selected: selectedAction,
                                  onSelected: (value) {
                                    ref
                                        .read(defaultActionWhenUPCIsScannedProvider.notifier)
                                        .state = value;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // 🔽 NUEVO BLOQUE: configuración de cantidad
                                const Text(
                                  'Cantidad mínima de movimientos/escaneos\n'
                                      'para permitir ingresar cantidad escaneada:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: qty.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    labelText: 'Cantidad (ej: 3)',
                                  ),
                                  onChanged: (value) {
                                    final parsed = int.tryParse(value);
                                    if (parsed != null && parsed > 1) {
                                      ref
                                          .read(
                                        quantityOfMovementAndScannedToAllowInputScannedQuantityProvider
                                            .notifier,
                                      )
                                          .state = parsed;
                                      // Guarda en GetStorage
                                      GetStorage().write(KEY_QTY_ALLOW_INPUT, parsed);

                                      print("Guardado -> $parsed");

                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cerrar'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );

                  },
                );
              },
            ),

          ],
        ),
      ],
    );
  }

  Widget _buildFilterList({
    required String text,
    required String counting,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final styleText = TextStyle(
      fontSize: themeFontSizeSmall,
      fontWeight: FontWeight.bold,
      color: isActive ? themeColorPrimary : themeColorGray,
    );

    final styleCounting = TextStyle(
      fontSize: themeFontSizeLarge,
      fontWeight: FontWeight.bold,
      color: isActive ? themeColorPrimary : themeColorGray,
    );

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(themeBorderRadius),
          color: isActive ? themeColorPrimaryLight : themeBackgroundColorLight,
        ),
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(text, style: styleText),
              SizedBox(width: 8),
              Text(counting, style: styleCounting),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeList(
      List<Barcode> barcodeList, MInOutNotifier mInOutNotifier) {
    return Flexible(
      child: ListView.builder(
        controller: mInOutNotifier.scanBarcodeListScrollController,
        itemCount: barcodeList.length,
        itemBuilder: (BuildContext context, int index) {
          final barcode = barcodeList[index];
          return BarcodeList(
            barcode: barcode,
            onPressedDelete: () =>
                _showConfirmDeleteItem(context, mInOutNotifier, barcode),
            onPressedrepetitions: () =>
                mInOutNotifier.selectRepeat(barcode.code),
            mInOutNotifier: mInOutNotifier,
          );
        },
      ),
    );
  }

  Future<void> _showConfirmDeleteItem(
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
                mInOutNotifier.removeBarcode(barcode: barcode,context: context);
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
}
