

class MOPrinter{
  String? name;
  String? ip;
  String? port;
  String? type;
  MOPrinter({this.name,this.ip,this.port,this.type});

  factory MOPrinter.fromJson(Map<String, dynamic> json) {
    return MOPrinter(
      name: json['name'],
      ip: json['ip'],
      port: json['port'],
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'ip': ip, 'port': port, 'type': type};
  }
}