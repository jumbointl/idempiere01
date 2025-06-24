import '../../../shared/domain/entities/ad_entity_id.dart';

class AdRoleIncluded {
    AdEntityId includedRoleId;


    AdRoleIncluded({
        required this.includedRoleId,
    });

    factory AdRoleIncluded.fromJson(Map<String, dynamic> json) => AdRoleIncluded(
        includedRoleId: json["Included_Role_ID"] != null ? AdEntityId.fromJson(json["Included_Role_ID"]) : AdEntityId(),
    );

    AdRoleIncluded copyWith({
      AdEntityId? includedRoleId,
    }) {
      return AdRoleIncluded(
        includedRoleId: includedRoleId ?? this.includedRoleId,
      );
    }
}