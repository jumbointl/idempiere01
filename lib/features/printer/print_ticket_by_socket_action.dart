
import 'package:monalisapy_features/printer/pos/PosTicket.dart';
import 'package:monalisapy_features/printer/pos/print_ticket_by_socket_action_provider.dart';

import '../products/presentation/providers/common/set_and_fire_action_notifier.dart';

class PrintTicketBySocketAction extends SetAndFireActionNotifier<PosTicket> {
  PrintTicketBySocketAction({required super.ref})
      : super(
    payloadProvider: posTickerProvider,
    fireCounterProvider: fireSendCommandBySocketProvider,

  );
}
