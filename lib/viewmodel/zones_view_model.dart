import 'package:flutter/material.dart';
import 'package:namnam/model/response/Status.dart';
import 'package:namnam/model/zone.dart';
import 'package:namnam/model/request/create_zone_request.dart';
import 'package:namnam/model/request/add_polygons_request.dart';

import 'package:namnam/network/services/zones_service.dart';
import 'package:namnam/network/services/zones_service_impl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ZonesViewModel extends ChangeNotifier {
  final ZonesService _zonesService = ZonesServiceImpl();

  List<Zone> _zones = [];
  bool _isLoading = false;
  bool _isCreatingZone = false;
  bool _isLoadingPolygons = false;
  String? _errorMessage;

  List<Zone> get zones => _zones;
  bool get isLoading => _isLoading;
  bool get isCreatingZone => _isCreatingZone;
  bool get isLoadingPolygons => _isLoadingPolygons;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreatingZone(bool creating) {
    _isCreatingZone = creating;
    notifyListeners();
  }

  void _setLoadingPolygons(bool loading) {
    _isLoadingPolygons = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> fetchZones() async {
    print('ZonesViewModel: Starting fetchZones...');
    _setLoading(true);
    _setError(null);

    try {
      final response = await _zonesService.getZones();
      print('ZonesViewModel: fetchZones response - Status: ${response.status}');

      if (response.status == Status.COMPLETED) {
        _zones = response.data ?? [];
        print('ZonesViewModel: Zones loaded successfully - Count: ${_zones.length}');
        _setError(null);
      } else {
        final errorMsg = response.message ?? 'Failed to fetch zones';
        print('ZonesViewModel: fetchZones failed - Error: $errorMsg');
        _setError(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Error fetching zones: $e';
      print('ZonesViewModel: fetchZones exception - $errorMsg');
      _setError(errorMsg);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createZone(String zoneName, String zoneDescription) async {
    print('ZonesViewModel: Starting createZone - Name: $zoneName, Description: $zoneDescription');
    _setCreatingZone(true);
    _setError(null);

    try {
      final request = CreateZoneRequest(
        zoneName: zoneName,
        zoneDescription: zoneDescription,
      );

      final response = await _zonesService.createZone(request);
      print('ZonesViewModel: createZone response - Status: ${response.status}');

      if (response.status == Status.COMPLETED && response.data != null) {
        print('ZonesViewModel: Zone created successfully - ID: ${response.data!.zoneId}');
        _setError(null);
        // Refresh from the server so the list reflects the authoritative
        // zone (real zoneId, timestamps, etc.) rather than guessing it.
        await fetchZones();
        return true;
      } else {
        final errorMsg = response.message ?? 'Failed to create zone';
        print('ZonesViewModel: createZone failed - Error: $errorMsg');
        _setError(errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = 'Error creating zone: $e';
      print('ZonesViewModel: createZone exception - $errorMsg');
      _setError(errorMsg);
      return false;
    } finally {
      _setCreatingZone(false);
    }
  }

  void updateZone(Zone updatedZone) {
    final index = _zones.indexWhere((zone) => zone.zoneId == updatedZone.zoneId);
    if (index != -1) {
      _zones[index] = updatedZone;
      notifyListeners();
    }
  }

  void addZone(Zone zone) {
    _zones.add(zone);
    notifyListeners();
  }

  void removeZone(int zoneId) {
    _zones.removeWhere((zone) => zone.zoneId == zoneId);
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  Future<bool> addPolygonsToZone(int zoneId, List<List<LatLng>> polygons) async {
    print('ZonesViewModel: Starting addPolygonsToZone - ZoneId: $zoneId, Polygons count: ${polygons.length}');
    _setError(null);

    try {
      // Convert polygons to the required format
      final polygonCoordinates = polygons.map((polygon) => 
        PolygonCoordinates.fromLatLngList(polygon)
      ).toList();

      final request = AddPolygonsRequest(
        zoneId: zoneId,
        polygons: polygonCoordinates,
      );

      final response = await _zonesService.addPolygonsToZone(request);
      print('ZonesViewModel: addPolygonsToZone response - Status: ${response.status}');

      if (response.status == Status.COMPLETED && response.data == true) {
        print('ZonesViewModel: Polygons added successfully to zone $zoneId');
        
        // Update the local zone with the new polygons
        final zoneIndex = _zones.indexWhere((zone) => zone.zoneId == zoneId);
        if (zoneIndex != -1) {
          final existingZone = _zones[zoneIndex];
          final updatedPolygons = List<List<LatLng>>.from(existingZone.polygons);
          updatedPolygons.addAll(polygons);
          
          final updatedZone = existingZone.copyWith(polygons: updatedPolygons);
          _zones[zoneIndex] = updatedZone;
          notifyListeners();
        }
        
        _setError(null);
        return true;
      } else {
        final errorMsg = response.message ?? 'Failed to add polygons to zone';
        print('ZonesViewModel: addPolygonsToZone failed - Error: $errorMsg');
        _setError(errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = 'Error adding polygons to zone: $e';
      print('ZonesViewModel: addPolygonsToZone exception - $errorMsg');
      _setError(errorMsg);
      return false;
    }
  }

  Future<bool> deleteZone(int zoneId) async {
    print('ZonesViewModel: Starting deleteZone - ZoneId: $zoneId');
    _setError(null);

    try {
      final response = await _zonesService.deleteZone(zoneId);
      print('ZonesViewModel: deleteZone response - Status: ${response.status}');

      if (response.status == Status.COMPLETED) {
        print('ZonesViewModel: Zone deleted successfully - ID: $zoneId');
        removeZone(zoneId);
        _setError(null);
        return true;
      } else {
        final errorMsg = response.message ?? 'Failed to delete zone';
        print('ZonesViewModel: deleteZone failed - Error: $errorMsg');
        _setError(errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = 'Error deleting zone: $e';
      print('ZonesViewModel: deleteZone exception - $errorMsg');
      _setError(errorMsg);
      return false;
    }
  }

  Future<List<List<LatLng>>?> getZonePolygons(int zoneId) async {
    print('ZonesViewModel: Starting getZonePolygons - ZoneId: $zoneId');
    _setLoadingPolygons(true);
    _setError(null);

    try {
      final response = await _zonesService.getZonePolygons(zoneId);
      print('ZonesViewModel: getZonePolygons response - Status: ${response.status}');

      if (response.status == Status.COMPLETED && response.data != null) {
        final polygons = response.data!.toLatLngPolygons();
        print('ZonesViewModel: Zone polygons loaded successfully - Polygons count: ${polygons.length}');
        
        // Update the local zone with the fetched polygons
        final zoneIndex = _zones.indexWhere((zone) => zone.zoneId == zoneId);
        if (zoneIndex != -1) {
          final existingZone = _zones[zoneIndex];
          final updatedZone = existingZone.copyWith(polygons: polygons);
          _zones[zoneIndex] = updatedZone;
          notifyListeners();
        }
        
        _setError(null);
        return polygons;
      } else {
        final errorMsg = response.message ?? 'Failed to get zone polygons';
        print('ZonesViewModel: getZonePolygons failed - Error: $errorMsg');
        _setError(errorMsg);
        return null;
      }
    } catch (e) {
      final errorMsg = 'Error getting zone polygons: $e';
      print('ZonesViewModel: getZonePolygons exception - $errorMsg');
      _setError(errorMsg);
      return null;
    } finally {
      _setLoadingPolygons(false);
    }
  }
}
