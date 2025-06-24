import 'package:monalisa_app_001/features/auth/domain/entities/organization.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/organization_dto.dart';

class OrganizationMapper {
  static OrganizationDto organizationDtoJsonToEntity(
          Map<String, dynamic> json) =>
      OrganizationDto(
        organizations: List<Organization>.from(
          json['organizations'].map((organizationJson) =>
              Organization.fromJson(organizationJson as Map<String, dynamic>)),
        ),
      );
}
