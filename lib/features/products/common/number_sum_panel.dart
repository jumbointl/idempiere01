

import 'package:flutter/material.dart';

import '../../../config/theme/app_theme.dart';
import '../../shared/data/messages.dart';
double get fontSizeMedium => themeFontSizeNormal;
double get fontSizeLarge => themeFontSizeLarge;
Widget numberSumPanel({required BuildContext context,
  required TextEditingController qtyToSumController,
  required TextEditingController lastQtyController,
  required TextEditingController resultQtyController,
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum: 0),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:1),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:2),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:3),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:4),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:5),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:6),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:7),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:8),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:9),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:-4),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:-3),
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
              onPressed: () => addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum:-2),
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
                onPressed: () =>addAndSumQuantityText(context: context,
                  qtyToSumController: qtyToSumController,
                  lastQtyController: lastQtyController,
                  resultController: resultQtyController,
                  numToSum: -1),
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

void addAndSumQuantityText({required BuildContext context, 
    required TextEditingController qtyToSumController,
    required TextEditingController lastQtyController,
    required  TextEditingController resultController,
    required int numToSum}) {
  String lastQty = lastQtyController.text;
  int lastQtyNum = int.tryParse(lastQty) ?? 0;
  String currentText = qtyToSumController.text;
  if(numToSum>=0){
    currentText = '$currentText$numToSum';
    double? newQuantity = double.tryParse(currentText);
    if (newQuantity != null) {
      int result = lastQtyNum + newQuantity.toInt();
      qtyToSumController.text = currentText;
      resultController.text = result.toString();
      
    }
  } else if(numToSum==-1){
    qtyToSumController.text ='';
    resultController.text = (lastQtyNum).toString();
  } else if(numToSum==-2) {
    qtyToSumController.text = currentText.substring(0, currentText.length - 1);
    double? newQuantity = double.tryParse(qtyToSumController.text);
    if(newQuantity == null) {
      resultController.text = lastQty.toString();
    } else {
      int result = lastQtyNum + newQuantity.toInt();
      qtyToSumController.text = currentText;
      resultController.text = result.toString();  
    }
    
  } else if(numToSum==-3){
    qtyToSumController.text = '$currentText.';
  } else if(numToSum==-4){
    if(!currentText.startsWith('-')) qtyToSumController.text = '-$currentText';
    double? newQuantity = double.tryParse(qtyToSumController.text);
    if(newQuantity == null) {
      resultController.text = lastQty.toString();
    } else {
      int result = lastQtyNum + newQuantity.toInt();
      qtyToSumController.text = currentText;
      resultController.text = result.toString();
    }
  }


}

Future<int> openSumLineScannedQuantityDialog({required BuildContext context,
  required TextEditingController qtyToSumController,
  required TextEditingController resultController,
  required int lastQty,
  required TextEditingController lastQtyController,
  required String title,
  required String subtitle,
}) async {
  int qty =lastQty ;
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
                    title: Text(subtitle,
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
                      controller: lastQtyController,
                      keyboardType: TextInputType.none,
                      readOnly: true,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: themeFontSizeLarge,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad anterior',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: TextFormField(
                      textAlign: TextAlign.center,
                      controller: qtyToSumController,
                      keyboardType: TextInputType.none,
                      readOnly: true,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: themeFontSizeLarge,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad a sumar',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: TextFormField(
                      textAlign: TextAlign.center,
                      controller: resultController,
                      keyboardType: TextInputType.none,
                      readOnly: true,
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: themeFontSizeLarge,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Cantidad resultado:',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  numberSumPanel(context: sheetContext,
                      qtyToSumController: qtyToSumController,
                      lastQtyController: lastQtyController,
                      resultQtyController: resultController,
                      buttonWidth: 37),

                  const SizedBox(height: 8),

                  // --- Botones OK / Cancelar al estilo bottom sheet ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                                int.tryParse(resultController.text) ?? qty;
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
