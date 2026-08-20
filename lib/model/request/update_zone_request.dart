class UpdateZoneRequest {
  final int id;
  final String zoneName;
  final String zoneDescription;

  UpdateZoneRequest({
    required this.id,
    required this.zoneName,
    required this.zoneDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zoneName': zoneName,
      'zoneDescription': zoneDescription,
    };
  }
}
