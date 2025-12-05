

class MOPrinter{
  String? name;
  String? ip;
  String? port;
  String? type;
  String? serverIp;
  String? serverPort;

  MOPrinter({this.name,this.ip,this.port,this.type,this.serverIp,this.serverPort});

  factory MOPrinter.fromJson(Map<String, dynamic> json) {
    return MOPrinter(
      name: json['name'],
      ip: json['ip'],
      port: json['port'],
      type: json['type'],
      serverIp: json['serverIp'],
      serverPort: json['serverPort'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'ip': ip, 'port': port, 'type': type ,
      'serverIp': serverIp, 'serverPort': serverPort};
  }
}