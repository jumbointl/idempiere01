

class MOPrinter{
  static const String ZPL_TEMPLATE_3_NAME = 'PR3_10X4.ZPL';
  static const String ZPL_TEMPLATE_6_NAME = 'PR6_10X4.ZPL';
  String? name;
  String? ip;
  String? port;
  String? type;
  String? serverIp;
  String? serverPort;
  bool? noDelete;

  MOPrinter({this.name,this.ip,this.port,this.type,this.serverIp,
    this.serverPort,this.noDelete=false});

  factory MOPrinter.fromJson(Map<String, dynamic> json) {
    return MOPrinter(
      name: json['name'],
      ip: json['ip'],
      port: json['port'],
      type: json['type'],
      serverIp: json['serverIp'],
      serverPort: json['serverPort'],
      noDelete: json['noDelete'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'ip': ip, 'port': port, 'type': type ,
      'serverIp': serverIp, 'serverPort': serverPort,'noDelete': noDelete};
  }
  String get zplQrData {
    if(!is3FieldComplete) {
      return '';
    }
    if(is6FieldComplete){
      return '$ip:$port:$type:$name:$serverIp:$serverPort';
    }
    return '$ip:$port:$type';


  }
  bool get is3FieldComplete {
    return ip != null && port != null && type != null && ip!.isNotEmpty && port!.isNotEmpty && type!.isNotEmpty;
  }
  bool get is6FieldComplete {
    return ip != null && port != null && type != null && ip!.isNotEmpty
        && port!.isNotEmpty && type!.isNotEmpty && name!=null && name!.isNotEmpty
        && serverIp!=null && serverPort!=null && serverPort!.isNotEmpty;
  }
  static String get zplTemplate6FieldName {
    return 'PR610X4.ZPL';
  }
  static String get zplTemplate3FieldName {
    return 'PR310X4.ZPL';
  }

  String get zplTemplateNameAutoSelect {
    if(is6FieldComplete) {
      return zplTemplate6FieldName;
    }
    if(is3FieldComplete) {
      return zplTemplate3FieldName;
    }
    return '';

  }
  String get zplLabelPrintSentenceAutoSelect {
    if(zplQrData.isNotEmpty) {
     final sentence = '''
      ^XA
      ^CI28
      ^XF$zplTemplateNameAutoSelect^FS
      ^FN1^FD$zplQrData^FS
      ^XZ
      ''';
      return sentence;
    }

    return '';

  }
  String get zplLabelPrintSentencDirect{
    if(zplQrData.isNotEmpty) {
     final sentence = '''
      ^XA
^CI28
^MD15
^PW800
^LL320
^LH0,0

^FO30,30
^A0N,25,25
^FD$zplQrData^FS

^FO30,90
^BQN,2,6
^FDLA,$zplQrData^FS

^FO300,90
^BQN,2,6
^FDLA,$zplQrData^FS

^FO570,90
^BQN,2,6
^FDLA,$zplQrData^FS

^PQ1
^XZ
      ''';
      return sentence;
    }

    return '';

  }
  static String get zplTemplate6FieldsCreateTemplateSentence {
    String defaultSentence = '''
^XA
^CI28
^MD15
^PW800
^LL320
^LH0,0
^DFR:$zplTemplate6FieldName^FS
^FO30,30^A0N,25,25^FN1^FS
^FO30,80^BQN,2,6^FN1^FS
^FO300,80^BQN,2,6^FN1^FS
^FO570,80^BQN,2,6^FN1^FS
^PQ1
^XZ
''';
return defaultSentence;

  }
  static String get zplTemplate3FieldsCreateTemplateSentence {
    String defaultSentence = '''
^XA
^CI28
^MD15
^PW800
^LL320
^LH0,0
^DFR:$zplTemplate3FieldName^FS
^FO30,30^A0N,25,25^FN1^FS
^FO30,80^BQN,2,8^FN1^FS
^FO300,80^BQN,2,8^FN1^FS
^FO570,80^BQN,2,8^FN1^FS
^PQ1
^XZ

''';
    return defaultSentence;

  }
}