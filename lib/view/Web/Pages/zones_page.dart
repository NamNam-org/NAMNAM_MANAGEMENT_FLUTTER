import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:namnam/core/Utility/appcolors.dart';
import 'package:namnam/view/Web/widgets/custom_toast.dart';
import 'package:namnam/model/zone.dart';
import 'package:namnam/viewmodel/zones_view_model.dart';
import 'package:provider/provider.dart';

class ZonesPage extends StatefulWidget {
  const ZonesPage({super.key});

  @override
  State<ZonesPage> createState() => _ZonesPageState();
}

class _ZonesPageState extends State<ZonesPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  List<LatLng> _currentPolygonPoints = [];
  bool _isDrawingPolygon = false;
  Zone? _selectedZone;
  bool _isDialogOpen = false;
  bool _isEditingPolygon = false;
  String? _editingPolygonId;
  List<LatLng> _editingPolygonPoints = [];
  bool _isMarkerDialogOpen = false;
  
  // Default center (you can change this to your preferred location)
  static const LatLng _center = LatLng(33.8935, 35.5018); // Beirut, Lebanon

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  void _loadZones() {
    final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);
    zonesViewModel.fetchZones();
  }

  void _updatePolygons() {
    Set<Polygon> polygons = {};
    Set<Marker> markers = {};
    
    final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);
    final zones = zonesViewModel.zones;
    
    for (int i = 0; i < zones.length; i++) {
      final zone = zones[i];
      final isSelected = _selectedZone?.zoneId == zone.zoneId;
      
      // Add all polygons for this zone
      for (int j = 0; j < zone.polygons.length; j++) {
        final polygon = zone.polygons[j];
        final polygonId = 'zone_${zone.zoneId}_polygon_$j';
        final isEditingThis = _isEditingPolygon && _editingPolygonId == polygonId;
        
        if (polygon.length >= 3) {
          polygons.add(
            Polygon(
              polygonId: PolygonId(polygonId),
              points: isEditingThis ? _editingPolygonPoints : polygon,
              strokeWidth: isEditingThis ? 4 : (isSelected ? 3 : 2),
              strokeColor: isEditingThis ? Colors.green : (isSelected ? Colors.orange : Appcolors.appPrimaryColor),
              fillColor: isEditingThis ? Colors.green.withOpacity(0.3) : (isSelected ? Colors.orange.withOpacity(0.3) : Appcolors.appPrimaryColor.withOpacity(0.2)),
              consumeTapEvents: true,
              onTap: () => _onPolygonTap(polygonId, zone, j),
            ),
          );
          
          // Add editing markers if this polygon is being edited
          if (isEditingThis) {
            for (int k = 0; k < _editingPolygonPoints.length; k++) {
              markers.add(
                Marker(
                  markerId: MarkerId('edit_point_$k'),
                  position: _editingPolygonPoints[k],
                  draggable: true,
                  onDragEnd: (LatLng newPosition) => _onMarkerDragEnd(k, newPosition),
                  onTap: () => _onEditMarkerTap(k),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                  infoWindow: InfoWindow(
                    title: 'Point ${k + 1}',
                    snippet: 'Drag to edit • Tap to delete',
                  ),
                ),
              );
            }
          }
        }
      }
    }
    
    // Add current drawing polygon if exists
    if (_currentPolygonPoints.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: const PolygonId('current_polygon'),
          points: _currentPolygonPoints,
          strokeWidth: 3,
          strokeColor: Colors.red,
          fillColor: Colors.red.withOpacity(0.2),
        ),
      );
    }
    
    // Add drawing markers if in drawing mode
    if (_isDrawingPolygon && !_isEditingPolygon) {
      for (int i = 0; i < _currentPolygonPoints.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('point_${i + 1}'),
            position: _currentPolygonPoints[i],
            draggable: true,
            onDragEnd: (LatLng newPosition) => _onDrawingMarkerDragEnd(i, newPosition),
            onTap: () => _onDrawingMarkerTap(i),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Point ${i + 1}',
              snippet: 'Drag to edit • Tap to delete',
            ),
          ),
        );
      }
    }
    
    setState(() {
      _polygons = polygons;
      _markers = markers;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    // Don't add points if any dialog is open
    if (_isMarkerDialogOpen || _isDialogOpen) {
      return;
    }
    
    if (_isDrawingPolygon && !_isEditingPolygon) {
      setState(() {
        _currentPolygonPoints.add(position);
      });
      _updatePolygons();
    } else if (_isEditingPolygon) {
      // Exit edit mode when tapping elsewhere
      _exitEditMode();
    }
  }
  
  void _onPolygonTap(String polygonId, Zone zone, int polygonIndex) {
    if (!_isDrawingPolygon && !_isDialogOpen && !_isMarkerDialogOpen) {
      _enterEditMode(polygonId, zone, polygonIndex);
    }
  }
  
  void _enterEditMode(String polygonId, Zone zone, int polygonIndex) {
    setState(() {
      _isEditingPolygon = true;
      _editingPolygonId = polygonId;
      _editingPolygonPoints = List.from(zone.polygons[polygonIndex]);
    });
    _updatePolygons();
    
    ToastManager.show(
      context: context,
      message: 'Edit mode: Drag green markers to modify polygon points. Tap elsewhere to finish.',
      type: ToastType.success,
    );
  }
  
  void _exitEditMode() {
    if (!_isEditingPolygon) return;
    
    // Save the edited polygon back to the zone
    _saveEditedPolygon();
    
    setState(() {
      _isEditingPolygon = false;
      _editingPolygonId = null;
      _editingPolygonPoints.clear();
    });
    _updatePolygons();
    
    ToastManager.show(
      context: context,
      message: 'Polygon editing completed and saved!',
      type: ToastType.success,
    );
  }
  
  void _saveEditedPolygon() {
    if (_editingPolygonId == null || _editingPolygonPoints.length < 3) return;
    
    final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);
    final zones = zonesViewModel.zones;
    
    // Parse the polygon ID to get zone and polygon indices
    final parts = _editingPolygonId!.split('_');
    if (parts.length >= 4) {
      final zoneId = int.tryParse(parts[1]);
      final polygonIndex = int.tryParse(parts[3]);
      
      if (zoneId != null && polygonIndex != null) {
        final zoneIndex = zones.indexWhere((zone) => zone.zoneId == zoneId);
        if (zoneIndex != -1 && polygonIndex < zones[zoneIndex].polygons.length) {
          final updatedPolygons = List<List<LatLng>>.from(zones[zoneIndex].polygons);
          updatedPolygons[polygonIndex] = List.from(_editingPolygonPoints);
          
          final updatedZone = zones[zoneIndex].copyWith(polygons: updatedPolygons);
          
          setState(() {
            zonesViewModel.updateZone(updatedZone);
            if (_selectedZone?.zoneId == zoneId) {
              _selectedZone = updatedZone;
            }
          });
        }
      }
    }
  }
  
  void _onMarkerDragEnd(int pointIndex, LatLng newPosition) {
    if (_isEditingPolygon && pointIndex < _editingPolygonPoints.length) {
      setState(() {
        _editingPolygonPoints[pointIndex] = newPosition;
      });
      _updatePolygons();
    }
  }
  
  void _onEditMarkerTap(int pointIndex) {
    if (!_isEditingPolygon || _editingPolygonPoints.length <= 3) {
      ToastManager.show(
        context: context,
        message: 'Cannot delete point. Polygon must have at least 3 points.',
        type: ToastType.error,
      );
      return;
    }
    
    setState(() {
      _isMarkerDialogOpen = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PopScope(
          onPopInvoked: (didPop) {
            if (didPop) {
              setState(() {
                _isMarkerDialogOpen = false;
              });
            }
          },
          child: AlertDialog(
            title: Text('Delete Point ${pointIndex + 1}'),
            content: const Text('Are you sure you want to delete this point?'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isMarkerDialogOpen = false;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isMarkerDialogOpen = false;
                  });
                  Navigator.of(context).pop();
                  _deleteEditPoint(pointIndex);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _deleteEditPoint(int pointIndex) {
    if (_isEditingPolygon && 
        pointIndex < _editingPolygonPoints.length && 
        _editingPolygonPoints.length > 3) {
      setState(() {
        _editingPolygonPoints.removeAt(pointIndex);
      });
      _updatePolygons();
      
      ToastManager.show(
        context: context,
        message: 'Point deleted successfully!',
        type: ToastType.success,
      );
    }
  }
  
  void _onDrawingMarkerDragEnd(int pointIndex, LatLng newPosition) {
    if (_isDrawingPolygon && pointIndex < _currentPolygonPoints.length) {
      setState(() {
        _currentPolygonPoints[pointIndex] = newPosition;
      });
      _updatePolygons();
    }
  }
  
  void _onDrawingMarkerTap(int pointIndex) {
    if (!_isDrawingPolygon || _currentPolygonPoints.length <= 3) {
      ToastManager.show(
        context: context,
        message: 'Cannot delete point. Polygon must have at least 3 points.',
        type: ToastType.error,
      );
      return;
    }
    
    setState(() {
      _isMarkerDialogOpen = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PopScope(
          onPopInvoked: (didPop) {
            if (didPop) {
              setState(() {
                _isMarkerDialogOpen = false;
              });
            }
          },
          child: AlertDialog(
            title: Text('Delete Point ${pointIndex + 1}'),
            content: const Text('Are you sure you want to delete this point from the polygon being created?'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isMarkerDialogOpen = false;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isMarkerDialogOpen = false;
                  });
                  Navigator.of(context).pop();
                  _deleteDrawingPoint(pointIndex);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _deleteDrawingPoint(int pointIndex) {
    if (_isDrawingPolygon && 
        pointIndex < _currentPolygonPoints.length && 
        _currentPolygonPoints.length > 3) {
      setState(() {
        _currentPolygonPoints.removeAt(pointIndex);
      });
      _updatePolygons();
      
      ToastManager.show(
        context: context,
        message: 'Point deleted successfully!',
        type: ToastType.success,
      );
    }
  }

  void _startDrawingPolygon() {
    // Exit edit mode if active
    if (_isEditingPolygon) {
      _exitEditMode();
    }
    
    if (_selectedZone == null) {
      _showCreateZoneDialog();
      return;
    }
    
    setState(() {
      _isDrawingPolygon = true;
      _currentPolygonPoints.clear();
    });
    _updatePolygons();
    
    ToastManager.show(
      context: context,
      message: 'Tap on the map to add points. Drag markers to adjust position. Tap markers to delete points.',
      type: ToastType.success,
    );
  }

  void _finishPolygon() {
    if (_currentPolygonPoints.length < 3) {
      ToastManager.show(
        context: context,
        message: 'A polygon needs at least 3 points. Please add more points.',
        type: ToastType.error,
      );
      return;
    }
    
    if (_selectedZone != null) {
      _addPolygonToZone();
    } else {
      _showCreateZoneDialog();
    }
  }

  void _cancelDrawing() {
    setState(() {
      _isDrawingPolygon = false;
      _currentPolygonPoints.clear();
    });
    _updatePolygons();
  }

  void _showCreateZoneDialog({Zone? zone}) {
    final bool isEditMode = zone != null;

    setState(() {
      _isDialogOpen = true;
    });

    final nameController = TextEditingController(text: zone?.zoneName ?? '');
    final descriptionController = TextEditingController(text: zone?.description ?? '');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PopScope(
          onPopInvoked: (didPop) {
            if (didPop) {
              setState(() {
                _isDialogOpen = false;
              });
            }
          },
          child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Appcolors.appPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEditMode ? Icons.edit_location_alt : Icons.add_location,
                  color: Appcolors.appPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditMode ? 'Edit Zone' : 'Create New Zone',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zone Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Zone Name *',
                    hintText: 'Enter zone name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter zone description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    isEditMode
                        ? 'Updating the name and description won\'t affect this zone\'s polygons.'
                        : 'After creating the zone, you can select it and add multiple polygons to define the delivery areas.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isDialogOpen = false;
                });
                Navigator.of(context).pop();
                if (!isEditMode && _selectedZone == null) {
                  _cancelDrawing();
                }
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _isDialogOpen = false;
                  });
                  if (isEditMode) {
                    final zoneId = zone.zoneId;
                    if (zoneId != null) {
                      _editZone(
                        zoneId,
                        nameController.text.trim(),
                        descriptionController.text.trim(),
                      );
                    }
                  } else {
                    _createZone(
                      nameController.text.trim(),
                      descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
                    );
                  }
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Appcolors.appPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(isEditMode ? 'Save Changes' : 'Create Zone'),
            ),
          ],
          ),
        );
      },
    );
  }

  Future<void> _createZone(String zoneName, String? description) async {
    final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);
    
    // Show loading state
    setState(() {
      _isDialogOpen = false;
    });
    
    ToastManager.show(
      context: context,
      message: 'Creating zone...',
      type: ToastType.success,
    );
    
    final success = await zonesViewModel.createZone(
      zoneName, 
      description ?? '',
    );
    
    if (success) {
      // Find the newly created zone and select it
      final newZone = zonesViewModel.zones.lastWhere(
        (zone) => zone.zoneName == zoneName,
        orElse: () => zonesViewModel.zones.last,
      );
      
      // If we have current polygon points, add them to the new zone via API
      if (_currentPolygonPoints.isNotEmpty && newZone.zoneId != null) {
        final polygonsToAdd = [List<LatLng>.from(_currentPolygonPoints)];
        
        final polygonSuccess = await zonesViewModel.addPolygonsToZone(
          newZone.zoneId!,
          polygonsToAdd,
        );
        
        if (polygonSuccess) {
          // Get the updated zone from the view model
          final updatedZone = zonesViewModel.zones.firstWhere(
            (zone) => zone.zoneId == newZone.zoneId,
            orElse: () => newZone,
          );
          
          setState(() {
            _selectedZone = updatedZone;
            _isDrawingPolygon = false;
            _currentPolygonPoints.clear();
          });
        } else {
          setState(() {
            _selectedZone = newZone;
            _isDrawingPolygon = false;
            _currentPolygonPoints.clear();
          });
          
          ToastManager.show(
            context: context,
            message: 'Zone created but failed to add polygon. You can try adding it again.',
            type: ToastType.error,
          );
        }
      } else {
        setState(() {
          _selectedZone = newZone;
          _isDrawingPolygon = false;
          _currentPolygonPoints.clear();
        });
      }
      
      _updatePolygons();
      
      ToastManager.show(
        context: context,
        message: 'Zone "$zoneName" created successfully! You can now add polygons to this zone.',
        type: ToastType.success,
      );
    } else {
      ToastManager.show(
        context: context,
        message: zonesViewModel.errorMessage ?? 'Failed to create zone',
        type: ToastType.error,
      );
    }
  }

  Future<void> _editZone(int zoneId, String zoneName, String description) async {
    final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);

    final success = await zonesViewModel.editZone(zoneId, zoneName, description);

    if (!mounted) return;

    if (success) {
      if (_selectedZone?.zoneId == zoneId) {
        final updatedZone = zonesViewModel.zones.firstWhere(
          (z) => z.zoneId == zoneId,
          orElse: () => _selectedZone!,
        );
        setState(() {
          _selectedZone = updatedZone;
        });
        _updatePolygons();
      }

      ToastManager.show(
        context: context,
        message: 'Zone "$zoneName" updated successfully!',
        type: ToastType.success,
      );
    } else {
      ToastManager.show(
        context: context,
        message: zonesViewModel.errorMessage ?? 'Failed to update zone',
        type: ToastType.error,
      );
    }
  }

  void _showDeleteZoneDialog(Zone zone) {
    setState(() {
      _isDialogOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PopScope(
          onPopInvoked: (didPop) {
            if (didPop) {
              setState(() {
                _isDialogOpen = false;
              });
            }
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete this zone?'),
            content: Text(
              'Are you sure you want to delete "${zone.zoneName}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isDialogOpen = false;
                  });
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isDialogOpen = false;
                  });
                  Navigator.of(context).pop();
                  _deleteZone(zone);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteZone(Zone zone) async {
    if (zone.zoneId == null) return;

    final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);

    final success = await zonesViewModel.deleteZone(zone.zoneId!);

    if (!mounted) return;

    if (success) {
      if (_selectedZone?.zoneId == zone.zoneId) {
        setState(() {
          _selectedZone = null;
        });
        _updatePolygons();
      }

      ToastManager.show(
        context: context,
        message: 'Zone "${zone.zoneName}" deleted successfully!',
        type: ToastType.success,
      );
    } else {
      ToastManager.show(
        context: context,
        message: zonesViewModel.errorMessage ?? 'Failed to delete zone',
        type: ToastType.error,
      );
    }
  }

  Future<void> _addPolygonToZone() async {
    if (_selectedZone == null || _currentPolygonPoints.isEmpty) return;
    
    final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);
    final polygonsToAdd = [List<LatLng>.from(_currentPolygonPoints)];
    
    // Show loading toast
    ToastManager.show(
      context: context,
      message: 'Adding polygon to zone...',
      type: ToastType.success,
    );
    
    try {
      final success = await zonesViewModel.addPolygonsToZone(
        _selectedZone!.zoneId!, 
        polygonsToAdd,
      );
      
      if (success) {
        setState(() {
          // Update the selected zone reference to the updated zone from the view model
          final updatedZone = zonesViewModel.zones.firstWhere(
            (zone) => zone.zoneId == _selectedZone!.zoneId,
            orElse: () => _selectedZone!,
          );
          _selectedZone = updatedZone;
          _isDrawingPolygon = false;
          _currentPolygonPoints.clear();
        });
        
        _updatePolygons();
        
        ToastManager.show(
          context: context,
          message: 'Polygon added to zone "${_selectedZone!.zoneName}" successfully!',
          type: ToastType.success,
        );
      } else {
        ToastManager.show(
          context: context,
          message: zonesViewModel.errorMessage ?? 'Failed to add polygon to zone',
          type: ToastType.error,
        );
      }
    } catch (e) {
      ToastManager.show(
        context: context,
        message: 'Error: $e',
        type: ToastType.error,
      );
    }
  }
  
  void _selectZone(Zone zone) async {
    final wasSelected = _selectedZone?.zoneId == zone.zoneId;
    
    setState(() {
      _selectedZone = wasSelected ? null : zone;
    });
    
    // If zone was just selected (not deselected), fetch its polygons
    if (!wasSelected && zone.zoneId != null) {
      final zonesViewModel = Provider.of<ZonesViewModel>(context, listen: false);
      
      ToastManager.show(
        context: context,
        message: 'Loading polygons for ${zone.zoneName}...',
        type: ToastType.success,
      );
      
      try {
        final polygons = await zonesViewModel.getZonePolygons(zone.zoneId!);
        
        if (polygons != null) {
          // Update the selected zone reference
          final updatedZone = zonesViewModel.zones.firstWhere(
            (z) => z.zoneId == zone.zoneId,
            orElse: () => zone,
          );
          
          setState(() {
            _selectedZone = updatedZone;
          });
          
          _updatePolygons();
          
          ToastManager.show(
            context: context,
            message: 'Loaded ${polygons.length} polygon${polygons.length != 1 ? 's' : ''} for ${zone.zoneName}',
            type: ToastType.success,
          );
        } else {
          ToastManager.show(
            context: context,
            message: zonesViewModel.errorMessage ?? 'Failed to load polygons',
            type: ToastType.error,
          );
        }
      } catch (e) {
        ToastManager.show(
          context: context,
          message: 'Error loading polygons: $e',
          type: ToastType.error,
        );
      }
    } else {
      _updatePolygons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Appcolors.appPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.map,
                    color: Appcolors.appPrimaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Zones',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Appcolors.textPrimaryColor,
                      ),
                    ),
                    Text(
                      'Manage delivery zones and create custom areas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                if (_isDrawingPolygon) ...[
                  ElevatedButton.icon(
                    onPressed: _finishPolygon,
                    icon: const Icon(Icons.check),
                    label: const Text('Finish Polygon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _cancelDrawing,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (_isEditingPolygon) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Editing Polygon',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _exitEditMode,
                    icon: const Icon(Icons.check),
                    label: const Text('Finish Editing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else if (_selectedZone == null) ...[
                  ElevatedButton.icon(
                    onPressed: _startDrawingPolygon,
                    icon: const Icon(Icons.add_location),
                    label: const Text('Create Zone'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Appcolors.appPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Selected: ${_selectedZone!.zoneName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _startDrawingPolygon,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Polygon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedZone = null;
                      });
                      _updatePolygons();
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Deselect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Map Container
        Container(
          height: 600, // Increased height from Expanded to fixed 600px
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                MouseRegion(
                  cursor: (_isDrawingPolygon || _isEditingPolygon) ? SystemMouseCursors.click : SystemMouseCursors.basic,
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    onTap: (_isDialogOpen || _isMarkerDialogOpen) ? null : _onMapTap,
                    initialCameraPosition: const CameraPosition(
                      target: _center,
                      zoom: 13.0,
                    ),
                    markers: _markers,
                    polygons: _polygons,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: !_isDialogOpen,
                    mapToolbarEnabled: false,
                    scrollGesturesEnabled: !_isDrawingPolygon && !_isDialogOpen,
                    zoomGesturesEnabled: !_isDrawingPolygon && !_isDialogOpen,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                ),
                if (_isDialogOpen)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const SizedBox.expand(),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Zones List
        Consumer<ZonesViewModel>(
          builder: (context, zonesViewModel, child) {
            final zones = zonesViewModel.zones;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Zones (${zones.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Appcolors.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            _loadZones();
                            ToastManager.show(
                              context: context,
                              message: 'Refreshing zones...',
                              type: ToastType.success,
                            );
                          },
                          icon: Icon(
                            Icons.refresh,
                            color: Appcolors.appPrimaryColor,
                            size: 20,
                          ),
                          tooltip: 'Refresh zones',
                        ),
                      ],
                    ),
                    if (zones.isEmpty)
                      ElevatedButton.icon(
                        onPressed: _startDrawingPolygon,
                        icon: const Icon(Icons.add_location),
                        label: const Text('Create Your First Zone'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Appcolors.appPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (zonesViewModel.isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else if (zonesViewModel.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            zonesViewModel.errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            zonesViewModel.clearError();
                            _loadZones();
                          },
                          icon: Icon(Icons.refresh, color: Colors.red.shade600),
                          tooltip: 'Retry',
                        ),
                      ],
                    ),
                  ),
                ]
                else if (zones.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: zones.map((zone) {
                          final isSelected = _selectedZone?.zoneId == zone.zoneId;
                          return InkWell(
                            onTap: () => _selectZone(zone),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.orange : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.orange.withOpacity(0.2) : Appcolors.appPrimaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.location_on,
                                      color: isSelected ? Colors.orange : Appcolors.appPrimaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          zone.zoneName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? Colors.orange.shade800 : null,
                                          ),
                                        ),
                                        if (zone.description != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            zone.description!,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              zone.createdAt != null 
                                                ? 'Created: ${_formatDate(zone.createdAt!)}'
                                                : 'Recently created',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.polyline,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${zone.polygons.length} polygon${zone.polygons.length != 1 ? 's' : ''}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showCreateZoneDialog(zone: zone),
                                    icon: Icon(
                                      Icons.edit,
                                      color: Appcolors.appPrimaryColor,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _showDeleteZoneDialog(zone),
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} min ago';
        } else {
          return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        }
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
