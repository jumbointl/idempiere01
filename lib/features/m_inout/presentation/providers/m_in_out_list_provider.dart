import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/m_in_out.dart';
import '../../domain/repositories/m_in_out_repositiry.dart';
import '../../infrastructure/repositories/m_in_out_repository_impl.dart';

// Si también filtras "movement", tu repo ya tiene:
// getMovementListByDateRange(ref, dates:..., inOut:...)
// según tu archivo. :contentReference[oaicite:1]{index=1}

/// ===============================
/// STATE (solo lo necesario para la LISTA)
/// ===============================
@immutable
class MInOutListStatus {
  final bool isLoading;
  final List<MInOut> list;
  final String errorMessage;

  const MInOutListStatus({
    this.isLoading = false,
    this.list = const [],
    this.errorMessage = '',
  });

  MInOutListStatus copyWith({
    bool? isLoading,
    List<MInOut>? list,
    String? errorMessage,
  }) {
    return MInOutListStatus(
      isLoading: isLoading ?? this.isLoading,
      list: list ?? this.list,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// ===============================
/// NOTIFIER (solo lógica de LISTA)
/// ===============================
class MInOutListNotifier extends StateNotifier<MInOutListStatus> {
  final MInOutRepository repo;

  MInOutListNotifier({required this.repo}) : super(const MInOutListStatus());

  /// Cargar lista por rango. Por defecto usa InOut.
  /// Si quieres también movimientos, usa [isMovement=true].
  Future<void> findBetweenDates({
    required WidgetRef ref,
    required DateTimeRange dates,
    required String inOut,
    bool isMovement = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final List<MInOut> result = isMovement
          ? await repo.getMovementListByDateRange(ref, dates: dates, inOut: inOut)
          : await repo.getMInOutListByDateRange(ref: ref, dates: dates, inOut: inOut);

      state = state.copyWith(
        isLoading: false,
        list: result,
      );
    } catch (e) {
      print('Error: $e');
      state = state.copyWith(
        isLoading: false,
        list: const [],
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void clear() => state = const MInOutListStatus();
}

/// ===============================
/// PROVIDER (independiente del detalle)
/// ===============================
final mInOutListProvider =
StateNotifierProvider<MInOutListNotifier, MInOutListStatus>((ref) {
  return MInOutListNotifier(
    repo: MInOutRepositoryImpl(),
  );
});


enum mInOutJobs {
  createPickConfirm,
  createShipConfirm,
  createReceiveConfirm,
}

extension mInOutJobsX on mInOutJobs {
  String get label {
    switch (this) {
      case mInOutJobs.createPickConfirm:
        return 'createPickConfirm';
      case mInOutJobs.createShipConfirm:
        return 'createShipConfirm';
      case mInOutJobs.createReceiveConfirm:
        return 'createReceiveConfirm';
    }
  }
}

// Selección por id (int)
final selectedMInOutIdsProvider =
StateProvider<Set<int>>((ref) => <int>{});

final selectedMInOutJobsProvider =
StateProvider<Set<mInOutJobs>>((ref) => <mInOutJobs>{});

final showConfirmationSliderProvider = Provider<bool>((ref) {
  return ref.watch(selectedMInOutJobsProvider).isNotEmpty;
});