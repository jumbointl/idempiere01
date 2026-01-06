import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:get_storage/get_storage.dart';

const kSockTimeoutSecondsKey = 'pos_sock_timeout_seconds';

final sockTimeOutInSecoundsProvider = StateProvider<int>((ref) {
  final box = GetStorage();
  final v = box.read(kSockTimeoutSecondsKey);
  final int seconds = (v is int) ? v : int.tryParse('$v') ?? 6; // default 6s
  return seconds.clamp(1, 60);
});

Future<void> saveSockTimeoutSeconds(WidgetRef ref, int seconds) async {
  final box = GetStorage();
  final v = seconds.clamp(1, 60);
  await box.write(kSockTimeoutSecondsKey, v);
  ref.read(sockTimeOutInSecoundsProvider.notifier).state = v;
}
