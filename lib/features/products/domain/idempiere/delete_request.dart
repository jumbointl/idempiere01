class DeleteRequest {
  final int lineId;
  final int? movementIdToDelete;

  const DeleteRequest({
    required this.lineId,
    this.movementIdToDelete,
  });
}