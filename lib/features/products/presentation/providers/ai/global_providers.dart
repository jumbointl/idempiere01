import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:monalisa_app_001/features/products/presentation/providers/ai/upload_service.dart';

import '../common_provider.dart';

// 1. PROVIDER FOR ERROR MESSAGES (ALL CAPS)
// Este provider maneja los mensajes de error globales.
// Cuando su valor no es null, el ErrorDialogHandler mostrará el mensaje.
final errorProvider = StateProvider<String?>((ref) => null);

// 2. PROVIDER FOR GLOBAL LOADING STATE
class LoadingState {
  final bool isLoading;
  final String message;
  LoadingState({this.isLoading = false, this.message = ''});
}

class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(LoadingState());

  // Muestra el overlay con un mensaje en MAYÚSCULAS
  void show(String msg) {
    state = LoadingState(isLoading: true, message: msg.toUpperCase());
  }

  // Oculta el overlay
  void hide() {
    state = LoadingState(isLoading: false, message: '');
  }
}

final aiLoadingProvider = StateNotifierProvider<LoadingNotifier, LoadingState>((ref) {
  return LoadingNotifier();
});

// 3. PROVIDER FOR UPLOAD SERVICE (SWITCH BETWEEN FTP AND AWS)
// Lee la variable de entorno 'ENV' definida en Android Studio
final uploadServiceProvider = Provider<UploadService>((ref) {
  final config = ref.watch(ftpConfigProvider); // Lee la config de Memory

  if (APP_ENV == 'PROD') {
    return S3UploadService(); // AWS no usa esta config de FTP
  } else {
    return FtpUploadService(config); // Inyectamos la config de Memory
  }
});


// 4. HELPER FUNCTION TO DISMISS ERROR
extension ErrorX on WidgetRef {
  void clearError() {
    read(errorProvider.notifier).state = null;
  }

  void setError(String message) {
    read(errorProvider.notifier).state = message.toUpperCase();
  }
}
