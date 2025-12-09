class StandardResponse {
    int? recordId;
    bool? isError;
    String? error;

    StandardResponse({
        this.recordId,
        this.isError,
        this.error,
    });

    factory StandardResponse.fromJson(Map<String, dynamic> json) => StandardResponse(
        recordId: json["@RecordID"],
        isError: json["@IsError"],
        error: json["Error"],
    );

    Map<String, dynamic> toJson() => {
        "@RecordID": recordId,
        "@IsError": isError,
        "Error": error,
    };

}