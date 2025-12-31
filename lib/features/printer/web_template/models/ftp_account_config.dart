/// Storage keys for FTP configuration
const String kFtpUrlKey = 'ftp_url';
const String kFtpUserKey = 'ftp_user';
const String kFtpPassKey = 'ftp_pass';
const String kFtpPortKey = 'ftp_port';

class FtpAccountConfig {
  final String url;
  final String user;
  final String pass;
  final int port;

  const FtpAccountConfig({
    required this.url,
    required this.user,
    required this.pass,
    required this.port,
  });
}
