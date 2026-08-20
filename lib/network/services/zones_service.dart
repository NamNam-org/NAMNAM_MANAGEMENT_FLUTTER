import 'package:namnam/model/response/ApiResponse.dart';
import 'package:namnam/model/zone.dart';
import 'package:namnam/model/request/create_zone_request.dart';
import 'package:namnam/model/request/add_polygons_request.dart';
import 'package:namnam/model/response/zone_polygons_response.dart';

abstract class ZonesService {
  Future<ApiResponse<Zone>> createZone(CreateZoneRequest request);
  Future<ApiResponse<List<Zone>>> getZones();
  Future<ApiResponse<bool>> addPolygonsToZone(AddPolygonsRequest request);
  Future<ApiResponse<ZonePolygonsResponse>> getZonePolygons(int zoneId);
  Future<ApiResponse<bool>> deleteZone(int zoneId);
}
