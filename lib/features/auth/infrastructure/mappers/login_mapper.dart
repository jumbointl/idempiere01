import 'package:monalisa_app_001/features/auth/domain/entities/client.dart';
import 'package:monalisa_app_001/features/auth/domain/dtos/login_dto.dart';

class LoginMapper {
  static LoginDto loginDtoJsonToEntity(Map<String, dynamic> json) =>
      LoginDto(
        clients: List<Client>.from(
          json['clients'].map((clientJson) =>
              Client.fromJson(clientJson as Map<String, dynamic>)),
        ),
        token: json['token'] ?? '',
      );
}
