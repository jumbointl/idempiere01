import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monalisa_app_001/features/printer/print_ticket_by_socket_action.dart';

final printTicketBySocketActionProvider =
Provider.autoDispose<PrintTicketBySocketAction>((ref) {
  return PrintTicketBySocketAction(ref: ref);
});