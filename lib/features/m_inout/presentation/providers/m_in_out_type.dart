// lib/features/m_inout/presentation/providers/m_in_out_type.dart

enum MInOutType {
  shipment,
  shipmentConfirm,
  shipmentPrepare,
  receipt,
  receiptConfirm,
  pickConfirm,
  qaConfirm,
  move,
  moveConfirm,
}

bool isMInOutConfirmType(MInOutType t) {
  return t == MInOutType.shipmentConfirm ||
      t == MInOutType.receiptConfirm ||
      t == MInOutType.pickConfirm ||
      t == MInOutType.qaConfirm;
}

bool isShipmentPrepareType(MInOutType t) => t == MInOutType.shipmentPrepare;

bool isMoveConfirmType(MInOutType t) => t == MInOutType.moveConfirm;

bool isMoveType(MInOutType t) => t == MInOutType.move;

MInOutType? parseMInOutTypeFromWidget(String type) {
  switch (type.toLowerCase()) {
    case 'shipment':
      return MInOutType.shipment;
    case 'shipmentconfirm':
      return MInOutType.shipmentConfirm;
    case 'shipmentprepare':
      return MInOutType.shipmentPrepare;
    case 'receipt':
      return MInOutType.receipt;
    case 'receiptconfirm':
      return MInOutType.receiptConfirm;
    case 'pickconfirm':
      return MInOutType.pickConfirm;
    case 'qaconfirm':
      return MInOutType.qaConfirm;
    case 'move':
      return MInOutType.move;
    case 'moveconfirm':
      return MInOutType.moveConfirm;
    default:
      return null;
  }
}