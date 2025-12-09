class AdEntityId {
  String? propertyLabel;
  String? id;
  String? identifier;
  String? modelName;

  AdEntityId({
    this.propertyLabel,
    this.id,
    this.identifier,
    this.modelName,
  });

  AdEntityId copyWith({
    String? propertyLabel,
    String? id,
    String? identifier,
    String? modelName,
  }) =>
      AdEntityId(
        propertyLabel: propertyLabel ?? this.propertyLabel,
        id: id ?? this.id,
        identifier: identifier ?? this.identifier,
        modelName: modelName ?? this.modelName,
      );

  factory AdEntityId.fromJson(Map<String, dynamic> json) => AdEntityId(
        propertyLabel: json["propertyLabel"] ?? '',
        id: json["id"].toString() != "null" ? json["id"].toString() : null,
        identifier: json["identifier"] ?? '',
        modelName: json["model-name"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "propertyLabel": propertyLabel,
        "id": id,
        "identifier": identifier,
        "model-name": modelName,
      };
}
