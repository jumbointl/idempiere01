class FieldCrud {
  String? column;
  String? val;

  FieldCrud({
    this.column,
    this.val,
  });

  Map<String, dynamic> toJson() => {
        "@column": column,
        "val": val,
      };

  FieldCrud copyWith({
    String? column,
    String? val,
  }) =>
      FieldCrud(
        column: column ?? this.column,
        val: val ?? this.val,
      );
}
