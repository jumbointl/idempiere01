class CategoryAgg {
  final String categoryId;
  final String categoryName;
  final num totalQty;
  int? sequence;


  CategoryAgg({
    required this.categoryId,
    required this.categoryName,
    required this.totalQty,
    this.sequence,
  });

  CategoryAgg copyWith({num? totalQty}) => CategoryAgg(
    categoryId: categoryId,
    categoryName: categoryName,
    totalQty: totalQty ?? this.totalQty,
  );
}
class TokenItem {
  final String section;
  final String token;
  const TokenItem(this.section, this.token);
}