import '../entities/warehouse.dart';

class WarehouseDto {
  final List<Warehouse> warehouses;

  WarehouseDto({
    required this.warehouses,
  });

  factory WarehouseDto.fromJson(Map<String, dynamic> json) {
    return WarehouseDto(
      warehouses: (json['warehouses'] as List<dynamic>)
          .map((warehouse) =>
              Warehouse.fromJson(warehouse as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'warehouses': warehouses.map((warehouse) => warehouse.toJson()).toList(),
    };
  }
}
