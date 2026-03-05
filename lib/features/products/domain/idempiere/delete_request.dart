class DeleteRequest {
  final int lineId;
  final int? headerIdToDelete;

  const DeleteRequest({
    required this.lineId,
    this.headerIdToDelete,
  });
}

