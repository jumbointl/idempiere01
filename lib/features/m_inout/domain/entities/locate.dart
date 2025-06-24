class Locate {
  int? id;
  String? value;

  Locate({
    this.id,
    this.value,
  });

  factory Locate.fromJson(Map<String, dynamic> json) => Locate(
        id: json["id"],
        value: json["Value"] ?? '',
      );

  Locate copyWith({
    int? id,
    String? value,
  }) {
    return Locate(
      id: id ?? this.id,
      value: value ?? this.value,
    );
  }
}
