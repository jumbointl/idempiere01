// Copyright (c) 2023, devCoffee Business Solutions. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


import 'package:idempiere_rest/idempiere_rest.dart';

import 'idempiere_user.dart';

/// Class that abstracts the response of [IdempiereClient.initSession] and [IdempiereClient.oneStepLogin]
/// This class holds all session information
class IdempiereSession extends ModelBase {
  late String token, userName, password;
  late int clientId, roleId;
  String? language;
  int? userId, organizationId, warehouseId;
  String? refreshToken;
  bool _isOneStepLogin = false;
  static const String className = "SessionModel";

  IdempiereSession(this.token, this.clientId, this.roleId,
      {this.organizationId, this.warehouseId, this.language,this.refreshToken,this.userId})
      : super({});

  IdempiereSession.oneStepLogin(this.userName, this.password, this.clientId, this.roleId,
      {this.organizationId, this.warehouseId, this.language})
      : super({}) {
    token ='';
    _isOneStepLogin = true;
  }

  IdempiereSession.refresh(IdempiereUser user)
      : super({}) {
    token = user.token ?? '';
    refreshToken = user.refreshToken ?? '';
    userName = user.userName ?? '';
    password = user.password ?? '';
    clientId = user.clientId ?? -1;
    roleId = user.roleId ?? -1;
    organizationId = user.organizationId;
    warehouseId = user.warehouseId;
    language = user.language;
    userId = user.userId;
    _isOneStepLogin = false;
  }
  IdempiereSession.idempiereUser(IdempiereUser user)
      : super({}) {
    token = user.token ?? '';
    refreshToken = user.refreshToken ?? '';
    userName = user.userName ?? '';
    password = user.password ?? '';
    clientId = user.clientId ?? -1;
    roleId = user.roleId ?? -1;
    organizationId = user.organizationId;
    warehouseId = user.warehouseId;
    language = user.language;
    userId = user.userId;
    _isOneStepLogin = false;
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> parameters = {'clientId': clientId, 'roleId': roleId};

    if(userId != null){
      parameters['userId'] = userId!;
    }

    if (organizationId != null) {
      parameters['organizationId'] = organizationId;
    }

    if (warehouseId != null) {
      parameters['warehouseId'] = warehouseId;
    }

    if (language != null) {
      parameters['language'] = language;
    }

    if (_isOneStepLogin) {
      return {
        'userName': userName,
        'password': password,
        'parameters': parameters
      };
    } else {
      return parameters;
    }
  }
  Map<String, dynamic> toJsonRefresh() {
    Map<String, dynamic> parameters = {'refresh_token': refreshToken};
      return parameters;
  }
  Map<String, dynamic> toJsonLogOut() {
    Map<String, dynamic> parameters = {'token': token};
    return parameters;
  }

  @override
  ModelBase fromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  factory IdempiereSession.fromJson(Map<String, dynamic> json) => IdempiereSession(
        json["token"],
        json["clientId"],
        json["roleId"],
        organizationId: json["organizationId"],
        warehouseId: json["warehouseId"],
        language: json["language"],
        userId: json["userId"],
        refreshToken: json["refresh_token"],
      )
        ..userId = json["userId"]
        ..refreshToken = json["refresh_token"];
  static List<IdempiereSession> fromJsonList(List<dynamic> list){
    List<IdempiereSession> newList =[];
    for (var item in list) {
      if(item is IdempiereSession){
        newList.add(item);
      } else {
        IdempiereSession idempiereSession = IdempiereSession.fromJson(item);
        newList.add(idempiereSession);
      }

    }
    return newList;
  }





}





























