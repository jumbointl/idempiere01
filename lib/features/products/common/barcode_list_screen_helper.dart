import '../domain/models/barcode_models.dart';

List<BarcodeItem> buildBarcodeModels(List<BarcodeItem> input) {
  if(input.length>1){
    int countSortByLine = 0;
    for(int i=0;i<input.length;i++){
      if(input[i].line!=null || input[i].line!=0){
        countSortByLine++;
      }
      if(countSortByLine>1) break ;
    }
    if(countSortByLine>1) {
      return input
          .where((e) => e.code.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => (a.line ?? 0).compareTo(b.line ?? 0));
    }
  }

  return input
      .where((e) => e.code.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => a.title.compareTo(b.title));
}
