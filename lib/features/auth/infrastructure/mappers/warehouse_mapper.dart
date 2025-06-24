import '../../domain/entities/warehouse.dart';
import '../../domain/dtos/warehouse_dto.dart';

class WarehouseMapper {
  static WarehouseDto warehouseDtoJsonToEntity(
          Map<String, dynamic> json) =>
      WarehouseDto(
        warehouses: List<Warehouse>.from(
          json['warehouses'].map((warehouseJson) =>
              Warehouse.fromJson(warehouseJson as Map<String, dynamic>)),
        ),
      );
}
