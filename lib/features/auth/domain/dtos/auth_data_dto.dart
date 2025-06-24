import 'package:monalisa_app_001/features/auth/domain/entities/client.dart';

import '../entities/organization.dart';
import '../entities/role.dart';
import '../entities/warehouse.dart';

class AuthDataDto {
  Client? client;
  Role? role;
  Organization? organization;
  Warehouse? warehouse;
  int? userId;
  String? language;
  String? token;
  String? refreshToken;
  String? userName;
  String? password;

  AuthDataDto({
    this.client,
    this.role,
    this.organization,
    this.warehouse,
    this.userId,
    this.language,
    this.token,
    this.refreshToken,
    this.userName,
    this.password,
  });

  static AuthDataDto empty() {
    return AuthDataDto();
  }

  factory AuthDataDto.fromJson(Map<String, dynamic> json) {
    return AuthDataDto(
      client: json['client'] != null ? Client.fromJson(json['client']) : null,
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      organization: json['organization'] != null
          ? Organization.fromJson(json['organization'])
          : null,
      warehouse: json['warehouse'] != null
          ? Warehouse.fromJson(json['warehouse'])
          : null,
      userId: json['userId'] as int?,
      language: json['language'] as String?,
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      userName: json['userName'] as String?,
      password: json['password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (client != null) 'client': client,
      if (role != null) 'role': role,
      if (organization != null) 'organization': organization,
      if (warehouse != null) 'warehouse': warehouse,
      if (userId != null) 'userId': userId,
      if (language != null) 'language': language,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (userName != null) 'userName': userName,
      if (password != null) 'password': password,
    };
  }
}
