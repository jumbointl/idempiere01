
import 'idempiere_object.dart';

class CupsServer extends IdempiereObject{
  String? ip;
  String? port;
  CupsServer({
    super.id,
    super.name,
    super.active,
    super.propertyLabel,
    super.identifier,
    super.modelName='cups_server',
    this.ip,
    this.port,
  });
  factory CupsServer.fromJson(Map<String, dynamic> json) => CupsServer(
    active: json["active"],
    id: json["id"],
    propertyLabel: json["propertyLabel"],
    identifier: json["identifier"],
    modelName: json["modelName"],
    ip: json["ip"],
    port: json["port"],
  );
  static List<CupsServer> fromJsonList(List<dynamic> list){
    List<CupsServer> newList =[];
    for (var item in list) {
      if(item is CupsServer){
        newList.add(item);
      } else if(item is Map<String, dynamic>){
        CupsServer idempiereAttributeSetInstance = CupsServer.fromJson(item);
        newList.add(idempiereAttributeSetInstance);
      }

    }
    return newList;
  }
  @override
  Map<String, dynamic> toJson() => {
    "active": active,
    "id": id,
    "name": name,
    "propertyLabel": propertyLabel,
    "identifier": identifier,
    "modelName": modelName,
    "ip": ip,
    "port": port,
  };

}