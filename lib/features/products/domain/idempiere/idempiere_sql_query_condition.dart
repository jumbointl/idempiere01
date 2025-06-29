import 'idempiere_filter.dart';

class IdempiereSqlQueryCondition {
  List<IdempiereFilter> idempiereFilters ;
  String? _filter;

  IdempiereSqlQueryCondition({
    required this.idempiereFilters,

  });
  String getFilter (){
    if(idempiereFilters.isEmpty){
      return '';
    }
    _filter = '';

    for(int i=0;i<idempiereFilters.length;i++){
      IdempiereFilter data = idempiereFilters[i];
      if(i>0){
        _filter ="${_filter!} ${data.getSentence()}";
      } else {
        data.conjunction = '';
        _filter ="${_filter!} ${data.getSentence()}";
      }
    }
    _filter = _filter!.replaceAll('  ', ' ');
    _filter = _filter!.replaceAll(' ', '%20');
    return _filter!.trim();
  }

}