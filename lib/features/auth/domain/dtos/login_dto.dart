import '../entities/client.dart';

class LoginDto {
  final String token;
  final List<Client> clients;

  LoginDto({
    required this.token,
    required this.clients,
  });

  factory LoginDto.fromJson(Map<String, dynamic> json) {
    return LoginDto(
      clients: (json['clients'] as List<dynamic>)
          .map((client) => Client.fromJson(client as Map<String, dynamic>))
          .toList(),
      token: json['token'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clients': clients.map((client) => client.toJson()).toList(),
      'token': token,
    };
  }
}
