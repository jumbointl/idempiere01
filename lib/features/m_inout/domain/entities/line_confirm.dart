import 'package:monalisa_app_001/features/shared/domain/entities/ad_entity_id.dart';

class LineConfirm {
  int? id;
  AdEntityId? mInOutLineId;
  AdEntityId? mMovementLineId;
  double? targetQty;
  double? confirmedQty;
  double? differenceQty;
  double? scrappedQty;

  LineConfirm({
    this.id,
    this.mInOutLineId,
    this.mMovementLineId,
    this.targetQty,
    this.confirmedQty,
    this.differenceQty,
    this.scrappedQty,
  });

  factory LineConfirm.fromJson(Map<String, dynamic> json) => LineConfirm(
        id: json["id"],
        mInOutLineId: AdEntityId.fromJson(json["M_InOutLine_ID"] ?? {}),
        mMovementLineId: AdEntityId.fromJson(json["M_MovementLine_ID"] ?? {}),
        targetQty: (json["TargetQty"] != null) ? (json["TargetQty"] is double ? json["TargetQty"] : double.tryParse(json["TargetQty"].toString()) ?? 0.0) : 0.0,
        confirmedQty: (json["ConfirmedQty"] != null) ? (json["ConfirmedQty"] is double ? json["ConfirmedQty"] : double.tryParse(json["ConfirmedQty"].toString()) ?? 0.0) : 0.0,
        differenceQty: (json["DifferenceQty"] != null) ? (json["DifferenceQty"] is double ? json["DifferenceQty"] : double.tryParse(json["DifferenceQty"].toString()) ?? 0.0) : 0.0,
        scrappedQty: (json["ScrappedQty"] != null) ? (json["ScrappedQty"] is double ? json["ScrappedQty"] : double.tryParse(json["ScrappedQty"].toString()) ?? 0.0) : 0.0,

      );

  LineConfirm copyWith({
    int? id,
    AdEntityId? mInOutLineId,
    AdEntityId? mMovementLineId,
    double? targetQty,
    double? confirmedQty,
    double? differenceQty,
    double? scrappedQty,
  }) {
    return LineConfirm(
      id: id ?? this.id,
      mInOutLineId: mInOutLineId ?? this.mInOutLineId,
      mMovementLineId: mMovementLineId ?? this.mMovementLineId,
      targetQty: targetQty ?? this.targetQty,
      confirmedQty: confirmedQty ?? this.confirmedQty,
      differenceQty: differenceQty ?? this.differenceQty,
      scrappedQty: scrappedQty ?? this.scrappedQty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "M_InOutLine_ID": mInOutLineId?.toJson(),
      "M_MovementLine_ID": mMovementLineId?.toJson(),
      "TargetQty": targetQty,
      "ConfirmedQty": confirmedQty,
      "DifferenceQty": differenceQty,
      "ScrappedQty": scrappedQty,
    };
  }

}
