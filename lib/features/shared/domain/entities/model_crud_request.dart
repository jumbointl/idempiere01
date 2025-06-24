import 'package:monalisa_app_001/features/shared/domain/entities/model_crud.dart';

import 'ad_login_request.dart';

class ModelCrudRequest {
  ModelCrud? modelCrud;
  AdLoginRequest? adLoginRequest;

  ModelCrudRequest({
    this.modelCrud,
    this.adLoginRequest,
  });

  Map<String, dynamic> toJson() => {
        'ModelCRUD': modelCrud?.toJson(),
        'ADLoginRequest': adLoginRequest?.toJson(),
      };

  ModelCrudRequest copyWith({
    ModelCrud? modelCrud,
    AdLoginRequest? adLoginRequest,
  }) =>
      ModelCrudRequest(
        modelCrud: modelCrud ?? this.modelCrud,
        adLoginRequest: adLoginRequest ?? this.adLoginRequest,
      );
}
