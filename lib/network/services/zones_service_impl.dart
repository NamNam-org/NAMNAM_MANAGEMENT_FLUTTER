import 'package:namnam/model/response/ApiResponse.dart';
import 'package:namnam/model/response/Status.dart';
import 'package:namnam/model/zone.dart';
import 'package:namnam/model/request/create_zone_request.dart';
import 'package:namnam/model/request/update_zone_request.dart';
import 'package:namnam/model/request/add_polygons_request.dart';
import 'package:namnam/model/response/zone_polygons_response.dart';
import 'package:namnam/network/ApiEndPoints.dart';
import 'package:namnam/network/NetworkApiService.dart';
import 'package:namnam/network/services/zones_service.dart';
import 'package:namnam/core/Utility/Preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ZonesServiceImpl implements ZonesService {
  final NetworkApiService _networkApiService = NetworkApiService();

  @override
  Future<ApiResponse<Zone>> createZone(CreateZoneRequest request) async {
    print('ZonesServiceImpl: Starting createZone request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('ZonesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');
      print('ZonesServiceImpl: Request data: ${request.toJson()}');

      final response = await _networkApiService.postResponse(
        ApiEndPoints.zones,
        request.toJson(),
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('ZonesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('ZonesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        if (response.data != null) {
          print('ZonesServiceImpl: Processing successful response...');
          final zone = Zone.fromJson(response.data);
          print('ZonesServiceImpl: Zone created - ID: ${zone.zoneId}, Name: ${zone.zoneName}');
          return ApiResponse(
            Status.COMPLETED,
            zone,
            response.message,
          );
        } else {
          // The API returns {success: true} with no "data" payload on
          // creation, so a null body here still means success.
          print('ZonesServiceImpl: Zone created successfully (no data payload returned)');
          final zone = Zone(
            zoneName: request.zoneName,
            description: request.zoneDescription,
            polygons: const [],
          );
          return ApiResponse(
            Status.COMPLETED,
            zone,
            response.message,
          );
        }
      } else {
        print('ZonesServiceImpl: Response status is not COMPLETED');

        // Check if it's an authentication error
        if (response.message?.toLowerCase().contains('unauthorized') == true) {
          return ApiResponse(
            Status.ERROR,
            null,
            'Authentication failed. Please log in again.',
          );
        }

        return ApiResponse(
          Status.ERROR,
          null,
          response.message ?? 'Failed to create zone',
        );
      }
    } catch (e) {
      print('ZonesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to create zone: $e',
      );
    }
  }

  @override
  Future<ApiResponse<Zone>> updateZone(UpdateZoneRequest request) async {
    print('ZonesServiceImpl: Starting updateZone request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('ZonesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');
      print('ZonesServiceImpl: Request data: ${request.toJson()}');

      final response = await _networkApiService.patchResponse(
        ApiEndPoints.updateZone,
        request.toJson(),
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('ZonesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('ZonesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        if (response.data != null) {
          print('ZonesServiceImpl: Processing successful response...');
          final zone = Zone.fromJson(response.data);
          print('ZonesServiceImpl: Zone updated - ID: ${zone.zoneId}, Name: ${zone.zoneName}');
          return ApiResponse(
            Status.COMPLETED,
            zone,
            response.message,
          );
        } else {
          // The API returns {success: true} with no "data" payload on
          // update, so a null body here still means success.
          print('ZonesServiceImpl: Zone updated successfully (no data payload returned)');
          final zone = Zone(
            zoneId: request.id,
            zoneName: request.zoneName,
            description: request.zoneDescription,
            polygons: const [],
          );
          return ApiResponse(
            Status.COMPLETED,
            zone,
            response.message,
          );
        }
      } else {
        print('ZonesServiceImpl: Response status is not COMPLETED');

        // Check if it's an authentication error
        if (response.message?.toLowerCase().contains('unauthorized') == true) {
          return ApiResponse(
            Status.ERROR,
            null,
            'Authentication failed. Please log in again.',
          );
        }

        return ApiResponse(
          Status.ERROR,
          null,
          response.message ?? 'Failed to update zone',
        );
      }
    } catch (e) {
      print('ZonesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to update zone: $e',
      );
    }
  }

  @override
  Future<ApiResponse<List<Zone>>> getZones() async {
    print('ZonesServiceImpl: Starting getZones request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('ZonesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');

      final response = await _networkApiService.fetchData(
        ApiEndPoints.zones,
        {}, // Empty query parameters for get all zones
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('ZonesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('ZonesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        if (response.data != null) {
          print('ZonesServiceImpl: Processing successful response...');
          final List<dynamic> zoneMaps = response.data;
          final zones = zoneMaps.map((zoneMap) => Zone.fromJson(zoneMap)).toList();
          print('ZonesServiceImpl: Zones loaded - Count: ${zones.length}');
          return ApiResponse(
            Status.COMPLETED,
            zones,
            response.message,
          );
        } else {
          print('ZonesServiceImpl: Response data is null');
          return ApiResponse(
            Status.COMPLETED,
            [],
            'No zones found',
          );
        }
      } else {
        print('ZonesServiceImpl: Response status is not COMPLETED');

        // Check if it's an authentication error
        if (response.message?.toLowerCase().contains('unauthorized') == true) {
          return ApiResponse(
            Status.ERROR,
            null,
            'Authentication failed. Please log in again.',
          );
        }

        return ApiResponse(
          Status.ERROR,
          null,
          response.message ?? 'Failed to get zones',
        );
      }
    } catch (e) {
      print('ZonesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to get zones: $e',
      );
    }
  }

  @override
  Future<ApiResponse<bool>> addPolygonsToZone(AddPolygonsRequest request) async {
    print('ZonesServiceImpl: Starting addPolygonsToZone request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('ZonesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');
      print('ZonesServiceImpl: Request data: ${request.toJson()}');

      final response = await _networkApiService.postResponse(
        ApiEndPoints.zonesPolygonsMultiple,
        request.toJson(),
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('ZonesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('ZonesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        print('ZonesServiceImpl: Polygons added successfully to zone ${request.zoneId}');
        return ApiResponse(
          Status.COMPLETED,
          true,
          response.message ?? 'Polygons added successfully',
        );
      } else {
        print('ZonesServiceImpl: Response status is not COMPLETED');

        // Check if it's an authentication error
        if (response.message?.toLowerCase().contains('unauthorized') == true) {
          return ApiResponse(
            Status.ERROR,
            false,
            'Authentication failed. Please log in again.',
          );
        }

        return ApiResponse(
          Status.ERROR,
          false,
          response.message ?? 'Failed to add polygons to zone',
        );
      }
    } catch (e) {
      print('ZonesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        false,
        'Failed to add polygons to zone: $e',
      );
    }
  }

  @override
  Future<ApiResponse<ZonePolygonsResponse>> getZonePolygons(int zoneId) async {
    print('ZonesServiceImpl: Starting getZonePolygons request for zone $zoneId...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('ZonesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');

      final response = await _networkApiService.fetchData(
        ApiEndPoints.getZonePolygons(zoneId),
        {}, // Empty query parameters
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('ZonesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('ZonesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        if (response.data != null) {
          print('ZonesServiceImpl: Processing successful response...');
          
          // Handle the response data as a list
          final List<dynamic> dataList = response.data is List 
            ? response.data as List<dynamic>
            : [response.data];
          
          final zonePolygons = ZonePolygonsResponse.fromApiResponse(dataList);
          
          print('ZonesServiceImpl: Zone polygons loaded - Zone: ${zonePolygons.zoneName}, Polygons count: ${zonePolygons.polygons.length}');
          return ApiResponse(
            Status.COMPLETED,
            zonePolygons,
            response.message,
          );
        } else {
          print('ZonesServiceImpl: Response data is null');
          return ApiResponse(
            Status.COMPLETED,
            ZonePolygonsResponse(zoneId: zoneId, zoneName: '', polygons: []),
            'No polygons found for this zone',
          );
        }
      } else {
        print('ZonesServiceImpl: Response status is not COMPLETED');

        // Check if it's an authentication error
        if (response.message?.toLowerCase().contains('unauthorized') == true) {
          return ApiResponse(
            Status.ERROR,
            null,
            'Authentication failed. Please log in again.',
          );
        }

        return ApiResponse(
          Status.ERROR,
          null,
          response.message ?? 'Failed to get zone polygons',
        );
      }
    } catch (e) {
      print('ZonesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to get zone polygons: $e',
      );
    }
  }

  @override
  Future<ApiResponse<bool>> deleteZone(int zoneId) async {
    print('ZonesServiceImpl: Starting deleteZone request for zone $zoneId...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('ZonesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');

      final response = await _networkApiService.deleteResponse(
        ApiEndPoints.deleteZone(zoneId),
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('ZonesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');

      if (response.status == Status.COMPLETED) {
        print('ZonesServiceImpl: Zone deleted successfully - ID: $zoneId');
        return ApiResponse(
          Status.COMPLETED,
          true,
          response.message,
        );
      } else {
        print('ZonesServiceImpl: Response status is not COMPLETED');

        // Check if it's an authentication error
        if (response.message?.toLowerCase().contains('unauthorized') == true) {
          return ApiResponse(
            Status.ERROR,
            null,
            'Authentication failed. Please log in again.',
          );
        }

        return ApiResponse(
          Status.ERROR,
          null,
          response.message ?? 'Failed to delete zone',
        );
      }
    } catch (e) {
      print('ZonesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to delete zone: $e',
      );
    }
  }
}
