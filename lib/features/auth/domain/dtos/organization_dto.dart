import '../entities/organization.dart';

class OrganizationDto {
  final List<Organization> organizations;

  OrganizationDto({
    required this.organizations,
  });

  factory OrganizationDto.fromJson(Map<String, dynamic> json) {
    return OrganizationDto(
      organizations: (json['organizations'] as List<dynamic>)
          .map((organization) =>
              Organization.fromJson(organization as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizations':
          organizations.map((organization) => organization.toJson()).toList(),
    };
  }
}
