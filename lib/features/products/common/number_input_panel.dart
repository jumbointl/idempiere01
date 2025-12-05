

import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../shared/data/messages.dart';
double get fontSizeMedium => themeFontSizeNormal;
double get fontSizeLarge => themeFontSizeLarge;
Widget numberInputPanel({required BuildContext context,
  required TextEditingController quantityController,
  required double buttonWidth,
}){
  //double widthButton = 40 ;
  return Center(

    //margin: EdgeInsets.only(left: 10, right: 10,),
    child: Column(
      children: [
        Row(
          //spacing: 4,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => addQuantityText(context,quantityController,0),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '0',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,1),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '1',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,2),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),

                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '2',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,3),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '3',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,4),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '4',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),

          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //spacing: 4,
          children: [


            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,5),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '5',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,6),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '6',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,7),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '7',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,8),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '8',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),

            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,9),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '9',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),

          ],
        ),
        SizedBox(height: 10,),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //spacing: 4,
          children: [
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,-4),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '-',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,-3),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '.',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            TextButton(
              onPressed: () =>addQuantityText(context,quantityController,-2),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: Size(buttonWidth, 37),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(5),

                  )
              ),
              child: Text(
                '<=',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSizeMedium
                ),
              ),
            ),
            SizedBox(
              width: buttonWidth*2,
              height: 37,
              child: TextButton(
                onPressed: () =>addQuantityText(context,quantityController,-1),
                style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: Size(buttonWidth*2 + 3*4, 37), // width of 5 buttons + 4 spacing
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.black),
                      borderRadius: BorderRadius.circular(5),

                    )
                ),

                child: Text(
                  Messages.CLEAR,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeMedium
                  ),
                ),
              ),
            ),
          ],
        ),

      ],
    ),
  );


}



void addQuantityText(BuildContext context, TextEditingController quantityController, int i) {
  String currentText = quantityController.text;
  if(i>=0){
    currentText = '$currentText$i';
    double? newQuantity = double.tryParse(currentText);
    if (newQuantity != null) {
      quantityController.text = currentText;
    }
  } else if(i==-1){
    quantityController.text ='';
  } else if(i==-2) {
    quantityController.text = currentText.substring(0, currentText.length - 1);
  } else if(i==-3){
    quantityController.text = '$currentText.';
  } else if(i==-4){
    if(!currentText.startsWith('-')) quantityController.text = '-$currentText';

  }


}
Future<int> openSetLineScannedQuantityDialog({
  required String title,
  required String subtitle,
  required BuildContext context,
  required TextEditingController qtyController,
  //required Line line,
  required int quantity,
}) async {
  int qty =quantity ;
  qty = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true, // 👈 para que tenga más altura si hace falta
    builder: (BuildContext sheetContext) {


      return SafeArea(
        child: PopScope(
          canPop: false, // el back físico no hace pop automático
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) {
              // Si por alguna razón ya poppeó, no hagas nada.
              return;
            }
          },
          child: Padding(
            // Para que el teclado no tape el bottom sheet
            padding: EdgeInsets.only(top: 40, left: 40, right: 40,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom+20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- "Título" estilo bottom sheet ---
                  Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: themeFontSizeTitle,
                    ),
                  ),

                  ListTile(
                    title: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: themeFontSizeLarge,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),



                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: TextFormField(
                      textAlign: TextAlign.center,
                      controller: qtyController,
                      keyboardType: TextInputType.none,
                      readOnly: true,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: themeFontSizeLarge,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad resultado',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  numberInputPanel(context: sheetContext,
                      quantityController: qtyController,
                      buttonWidth: 37),

                  const SizedBox(height: 8),

                  // --- Botones OK / Cancelar al estilo bottom sheet ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cancelar',
                              style: TextStyle(fontSize: 20)),
                          onPressed: () {
                            Navigator.of(sheetContext).pop(qty);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child:
                          const Text('Ok', style: TextStyle(fontSize: 20)),
                          onPressed: () {
                            final result =
                                int.tryParse(qtyController.text) ?? qty;
                            Navigator.of(sheetContext).pop(result);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ) ?? qty;
  return qty;
}

Future<int> showSetQtyDialog(BuildContext context,
    {
      required String title,
      required String subtitle,
      required int quantity,
      required TextEditingController quantityController,
    }) async {
  double? result =  await showDialog<double>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title, style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: themeFontSizeTitle),),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [

              Text(subtitle,
                style: TextStyle(fontSize: themeFontSizeTitle),),

              TextFormField(
                textAlign: TextAlign.center,
                controller: quantityController,
                keyboardType: TextInputType.none,
                readOnly: true,
                style: const TextStyle(
                    color: Colors.purple, fontSize: themeFontSizeLarge),
                decoration: const InputDecoration(
                  labelText: 'Cantidad final',
                  alignLabelWithHint: true,
                ),
              ),
              numberInputPanel(context: context,
                  quantityController: quantityController,
                  buttonWidth : 37),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(child: const Text('Cancelar'), onPressed: () {
            Navigator.of(context).pop(quantity);
          }),
          TextButton(child: const Text('Ok'), onPressed: () {
            String aux = quantityController.text;
            if (aux.endsWith('.')) aux = aux.substring(0, aux.length - 1);
            double qtyToSum = double.tryParse(aux) ?? 0;

            Navigator.of(context).pop(qtyToSum);
          }),
        ],);
    },);
  if(result!=null){
    return result.toInt();
  } else {
    return quantity;
  }
}

Future<void> showQtyToSumDialog(BuildContext context,
    {
      required String title,
      required String subtitle,
      required int lastQty,
      required TextEditingController qtyController,
      required TextEditingController qtyToSumController,
    }) async {
  final double buttonWidth = 37;
  double? result =  await showDialog<double>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title, style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: themeFontSizeTitle),),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text('Cantidad a sumar puede ser negativa',
                style: TextStyle(color: Colors.black,),),
              Text(subtitle,
                style: TextStyle(fontSize: themeFontSizeTitle),),
              TextFormField(
                textAlign: TextAlign.center,
                controller: TextEditingController(text: '$lastQty',),
                keyboardType: TextInputType.none,
                readOnly: true,
                style: const TextStyle(
                    color: Colors.purple, fontSize: themeFontSizeLarge),
                decoration: const InputDecoration(
                  labelText: 'Cantidad anterior',
                  alignLabelWithHint: true,
                ),
              ),
              TextFormField(
                textAlign: TextAlign.center,
                controller: qtyToSumController,
                keyboardType: TextInputType.none,
                readOnly: true,
                style: const TextStyle(
                    color: Colors.purple, fontSize: themeFontSizeLarge),
                decoration: const InputDecoration(
                  labelText: 'Cantidad a sumar al anterior',
                  alignLabelWithHint: true,
                ),
              ),
              numberInputPanel(context: context,
                  quantityController: qtyToSumController,
                  buttonWidth : 37),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(child: const Text('Cancelar'), onPressed: () {
            qtyToSumController.text ='1';
            Navigator.of(context).pop(1.0);
          }),
          TextButton(child: const Text('Ok'), onPressed: () {
            String aux = qtyToSumController.text;
            if (aux.endsWith('.')) aux = aux.substring(0, aux.length - 1);
            double qtyToSum = double.tryParse(aux) ?? 0;

            Navigator.of(context).pop(qtyToSum);
          }),
        ],);
    },);
  if(result!=null){
    lastQty += result.toInt();
    qtyController.text = lastQty.toString();
  }
}