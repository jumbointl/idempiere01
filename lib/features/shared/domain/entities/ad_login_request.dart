class AdLoginRequest {
    String? user;
    String? pass;
    String? lang;
    int? clientId;
    int? roleId;
    int? orgId;
    int? warehouseId;
    int? stage;

    AdLoginRequest({
        this.user,
        this.pass,
        this.lang,
        this.clientId,
        this.roleId,
        this.orgId,
        this.warehouseId,
        this.stage,
    });

    Map<String, dynamic> toJson() => {
        'user': user,
        'pass': pass,
        'lang': lang,
        'ClientID': clientId,
        'RoleID': roleId,
        'OrgID': orgId,
        'WarehouseID': warehouseId,
        'stage': stage,
    };

    AdLoginRequest copyWith({
        String? user,
        String? pass,
        String? lang,
        int? clientId,
        int? roleId,
        int? orgId,
        int? warehouseId,
        int? stage,
    }) => 
        AdLoginRequest(
            user: user ?? this.user,
            pass: pass ?? this.pass,
            lang: lang ?? this.lang,
            clientId: clientId ?? this.clientId,
            roleId: roleId ?? this.roleId,
            orgId: orgId ?? this.orgId,
            warehouseId: warehouseId ?? this.warehouseId,
            stage: stage ?? this.stage,
        );
}