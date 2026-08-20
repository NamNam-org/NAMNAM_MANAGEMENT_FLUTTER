class ApiEndPoints {
  static const String authLogin = "auth/login";
  static const String getCategories = "categories";
  static const String createCategory = "categories";
  static const String updateCategory = "categories/updateCategories";
  static const String uploadPresign = "uploads/presign";
  static const String zones = "zones";
  static const String updateZone = "zones/updateZones";
  static const String zonesPolygonsMultiple = "zones/polygons/multiple";
  static const String merchants = "merchants";

  // Dynamic endpoint for getting zone polygons: zones/{zoneId}/polygons
  static String getZonePolygons(int zoneId) => "zones/$zoneId/polygons";

  // Dynamic endpoint for deleting a category: categories/{categoryId}
  static String deleteCategory(int categoryId) => "categories/$categoryId";

  // Dynamic endpoint for deleting a zone: zones/{zoneId}
  static String deleteZone(int zoneId) => "zones/$zoneId";
}
