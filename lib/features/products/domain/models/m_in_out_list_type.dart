enum MInOutListType {
  all,
  receive,
  shipping,
}
extension MInOutListTypeX on MInOutListType {
  String get value {
    switch (this) {
      case MInOutListType.all:
        return 'ALL';
      case MInOutListType.receive:
        return 'RECEIVE';
      case MInOutListType.shipping:
        return 'SHIPPING';
    }
  }
  static const String ALL = 'ALL';
  static const String RECEIVE = 'RECEIVE';
  static const String SHIPPING = 'SHIPPING';
  static List<String> get mInOutTypes =>
      MInOutListType.values.map((e) => e.value).toList();
}
