// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

import 'package:idempiere_rest/idempiere_rest.dart';

import '../../../shared/data/memory.dart';
import 'idempiere_object.dart';

import 'idempiere_tenant.dart';
import 'idempiere_organization.dart';
import 'idempiere_rol.dart';
import 'idempiere_warehouse.dart';

IdempiereUser idempiereUserFromJson(String str) => IdempiereUser.fromJson(json.decode(str));

String idempiereUserToJson(IdempiereUser data) => json.encode(data.toJson());

class IdempiereUser extends IdempiereObject{

  String? password;
  String? userName;
  String? token;
  String? tokenCreatedAt;
  String? refreshToken;
  String? refreshTokenCreatedAt;
  List<IdempiereRol>? roles = [];
  List<IdempiereTenant>? clients = [];
  List<IdempiereWarehouse>? warehouses = [];
  List<IdempiereOrganization>? organizations = [];

  String? language;
  String? notificationToken;
  DateTime? ntfTokenCreatedAt;
  int? userId;
  int? organizationId;
  int? roleId;
  int? clientId;
  int? warehouseId;
  
  IdempiereUser({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName = 'ad_user',
    this.userName,
    this.password,
    this.token,
    this.tokenCreatedAt,
    this.refreshToken,
    this.refreshTokenCreatedAt,
    this.notificationToken,
    this.userId,
    this.organizationId,
    this.roleId,
    this.clientId,
    this.warehouseId,

    this.roles,
    this.clients,
    this.warehouses,
    this.organizations,
    this.ntfTokenCreatedAt,
    this.language,

  });


  factory IdempiereUser.fromJson(Map<String, dynamic> json) => IdempiereUser(
    id: json["id"],
    name: json["name"],
    userName: json["userName"],
    password: json["password"],
    notificationToken: json["notification_token"],
    ntfTokenCreatedAt: json["ntf_token_created_at"] ,
    token: json["token"],
    tokenCreatedAt: json["token_created_at"],
    refreshToken: json["refresh_token"] ,
    refreshTokenCreatedAt: json["refresh_token_created_at"] ,
    language: json["language"],
    roles: json["roles"] == null ? null : IdempiereRol.fromJsonList(json["roles"]),
    clients: json["clients"] == null ? null : IdempiereTenant.fromJsonList(json["clients"]),
    warehouses: json["warehouses"] == null ? null : IdempiereWarehouse.fromJsonList(json["warehouses"]),
    organizations: json["organizations"] == null ? null : IdempiereOrganization.fromJsonList(json["organizations"]),

    userId: json["userId"],
    organizationId: json["organizationId"],
    roleId: json["roleId"],
    clientId: json["clientId"],
    warehouseId: json["warehouseId"],
    active: json["active"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
  );

  @override
  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "userName": userName,
    "password": password,
    "roles": roles,
    "clients": clients,
    "warehouses": warehouses,
    "organizations": organizations,
    "language": language,
    "notification_token": notificationToken,
    "ntf_token_created_at": ntfTokenCreatedAt,
    "token": token,
    "token_created_at": tokenCreatedAt,
    "refresh_token": refreshToken,
    "refresh_token_created_at": refreshTokenCreatedAt,
    "userId": userId,
    "clientId": clientId,
    "organization": organizationId,
    "roleId": roleId,
    "warehouseId": warehouseId,
    "active":active,
    "propertyLabel":propertyLabel,
    "identifier":identifier,
    "modelName":modelName,
  };
  static List<IdempiereUser> fromJsonList(List<dynamic> list){
    List<IdempiereUser> newList =[];
    for (var item in list) {
      if(item is IdempiereUser){
        newList.add(item);
      } else {
        IdempiereUser idempiereUser = IdempiereUser.fromJson(item);
        newList.add(idempiereUser);
      }

    }
    return newList;
  }
  // when ...route.., request body = json, for login userName and password
  String getRequestRouteLogin(){
    return '/api/v1/auth/tokens';
  }
  Map<String, dynamic> objectToJsonToLogin() => {

    "userName": userName,
    "password": password,
  };
  void setClientsFromLoginRequest1(List<dynamic>? list){
    if(list==null){
      return;
    }
    List<IdempiereTenant> data = [];
    if(list is List<IdempiereTenant>){
      data.addAll(list);
      clients = data;
    } else if(list is List<Client>){
      for (var item in list) {
        IdempiereTenant idempiereTenant = IdempiereTenant(id: item.id!, name: item.name);
        data.add(idempiereTenant);
      }
      clients = data;
    } else  {
      data = IdempiereTenant.fromJsonList(list);
      clients = data;
    }

  }
  // when ...sentence.. apply get directly
  String getRequestSentence2GetRoles(){
    return '/api/v1/auth/roles?client=$clientId';
  }
  void setRolesFromLoginRequest2(List<dynamic>? list){
    if(list==null){
      return;
    }
    List<IdempiereRol> data = [];
    if(list is List<IdempiereRol>){
      data.addAll(list);
      roles = data;
    } else{
      data = IdempiereRol.fromJsonList(list);
      roles = data;
    }

  }
  // when ...sentence.. apply get directly
  String getRequestSentence3GetOrganizations(){
    return '/api/v1/auth/organizations?client=$clientId&role=$roleId';
  }
  void setOrganizationFromRequest3(List<dynamic>? list){
    if(list==null){
      return;
    }
    List<IdempiereOrganization> data = [];
    if(list is List<IdempiereOrganization>){
      data.addAll(list);
      organizations = data;
    } else{
      data = IdempiereOrganization.fromJsonList(list);
      organizations = data;
    }

  }
  // when ...sentence.. apply get directly
  String getRequestSentence4GetWarehouses(){
    return '/api/v1/auth/warehouses?client=$clientId&role=$roleId&organization=$organizationId';
  }

  void setWarehouseFromLoginRequest4(List<dynamic>? list){
    if(list==null){
      return;
    }
    List<IdempiereWarehouse> data = [];
    if(list is List<IdempiereWarehouse>){
      data.addAll(list);
      warehouses = data;
    } else{
      data = IdempiereWarehouse.fromJsonList(list);

      warehouses = data;
    }

  }
// when ...route.., request body = json
  String getRequestRouteGetTokens(){
    return '/api/v1/auth/tokens';
  }
  Map<String, dynamic> objectToJsonToGetTokens() => {

    "clientId": clientId,
    "organization": organizationId,
    "roleId": roleId,
    "warehouseId": warehouseId,
    "language": language,
  };
  void setDataFromRequestTokens(Map<String, dynamic>? data){
    if(data == null || data.isEmpty){
      return;
    }
    token = data["token"];
    refreshToken = data["refresh_token"];
    userId = data["userId"];
    language = data["language"];
  }
  // when ...route.., request body = json
  String getRequestRouteToRefreshTokens(){
    return '/api/v1/auth/refresh';
  }

  Map<String, dynamic> objectToJsonToRefreshTokens() => {
    "clientId": clientId,
    "userId": userId,
    "refresh_token":refreshToken,
  };

  bool canDoRefresh(){
    if(refreshToken==null || refreshToken!.isEmpty || refreshTokenCreatedAt==null
        || refreshTokenCreatedAt==''){
      return false;
    }
    DateTime now = DateTime.now();
    DateTime dateTimeRefresh = DateTime.parse(refreshTokenCreatedAt!);
    if(now.difference(dateTimeRefresh).inMinutes>Memory.REFRESH_TOKEN_EXPIRE_MINUTES-10){
      return false;
    }
    return true;
  }

  bool needDoRefresh(){

    if(refreshToken==null || refreshToken!.isEmpty || refreshTokenCreatedAt==null
        || refreshTokenCreatedAt==''){
      return false;
    }
    DateTime now = DateTime.now();
    DateTime dateTimeRefresh = DateTime.parse(refreshTokenCreatedAt!);
    if(now.difference(dateTimeRefresh).inMinutes>Memory.REFRESH_TOKEN_EXPIRE_MINUTES-120){
      return true;
    }
    if(token==null || token!.isEmpty || tokenCreatedAt==null
        || tokenCreatedAt==''){
      return true;
    }
    DateTime dateTimeToken = DateTime.parse(tokenCreatedAt!);
    if(now.difference(dateTimeToken).inMinutes> Memory.TOKEN_EXPIRE_MINUTES-10){
      return true;
    }
    return false;



  }
  int refreshTokenExpireInMinutes(){

    if(refreshToken==null || refreshToken!.isEmpty || refreshTokenCreatedAt==null
        || refreshTokenCreatedAt==''){
      return -1;
    }
    DateTime now = DateTime.now();
    DateTime dateTimeRefresh = DateTime.parse(refreshTokenCreatedAt!);
    return Memory.REFRESH_TOKEN_EXPIRE_MINUTES - now.difference(dateTimeRefresh).inMinutes;
  }

  int tokenExpireInMinutes(){

    if(token==null || token!.isEmpty || tokenCreatedAt==null
        || tokenCreatedAt==''){
      return -1;
    }
    DateTime now = DateTime.now();
    DateTime dateTime = DateTime.parse(tokenCreatedAt!);
    return Memory.TOKEN_EXPIRE_MINUTES - now.difference(dateTime).inMinutes;
  }


}
