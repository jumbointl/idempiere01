import 'package:monalisa_app_001/features/products/domain/idempiere/idempiere_object_id_string.dart';


class IdempiereReferenceList extends IdempiereObjectIdString {
  IdempiereReferenceList({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'ad_ref_list',
    super.image,
    super.category,
  });

  IdempiereReferenceList.fromJson(super.json)
      : super.fromJson();
}