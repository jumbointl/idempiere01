class RunProcessResponse {
    bool? isError;
    dynamic error;
    dynamic summary;
    String? logInfo;


    RunProcessResponse({
        this.isError,
        this.error,
        this.summary,
        this.logInfo,
    });

    factory RunProcessResponse.fromJson(Map<String, dynamic> json) => RunProcessResponse(
        isError: json["@IsError"],
        error: json["Error"],
        summary: json["Summary"],
        logInfo: json["LogInfo"],
    );

    Map<String, dynamic> toJson() => {
        "@IsError": isError,
        "Error": error,
        "Summary": summary,
        "LogInfo": logInfo,
    };
    static String get runProcessResponseFieldNameInJson => 'RunProcessResponse';
}