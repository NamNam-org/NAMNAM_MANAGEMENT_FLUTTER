/// A row from `GET merchants/merchant-requests`.
///
/// The endpoint returns `data` as a bare list, each entry pairing the request
/// itself with a full snapshot of the merchant that raised it. Unrecognised
/// keys are kept in `extras` on both levels so fields added to the API later
/// still reach the UI instead of being dropped.
class MerchantRequest {
  final int? requestId;
  final String? status;
  final DateTime? createdAt;
  final RequestedMerchant? merchant;
  final Map<String, dynamic> extras;

  MerchantRequest({
    this.requestId,
    this.status,
    this.createdAt,
    this.merchant,
    this.extras = const {},
  });

  /// Convenience accessor: the request payload carries the merchant id nested
  /// inside `merchant`, never at the top level.
  int? get merchantId => merchant?.merchantId;

  factory MerchantRequest.fromJson(Map<String, dynamic> json) {
    const consumed = {'requestId', 'status', 'requestCreatedAt', 'merchant'};

    return MerchantRequest(
      requestId: asInt(json['requestId']),
      status: asString(json['status']),
      createdAt: asDate(json['requestCreatedAt']),
      merchant: json['merchant'] is Map
          ? RequestedMerchant.fromJson(
              Map<String, dynamic>.from(json['merchant'] as Map))
          : null,
      extras: collectExtras(json, consumed),
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'status': status,
        'requestCreatedAt': createdAt?.toIso8601String(),
        'merchant': merchant?.toJson(),
        ...extras,
      };
}

/// The merchant snapshot attached to a request.
class RequestedMerchant {
  final int? merchantId;
  final String? name;
  final String? description;
  final bool? isOwnedByApp;
  final DateTime? createdAt;
  final String? notes;
  final int? zoneId;
  final RequestedMerchantCategory? category;

  /// From `media.logoKey` / `media.coverKey`, which this endpoint returns as
  /// ready-to-use presigned URLs rather than bare object keys.
  final String? logoUrl;
  final String? coverUrl;

  /// From `contact.hotlineNumber`.
  final String? hotlineNumber;

  final RequestedMerchantLocation? location;
  final Map<String, dynamic> extras;

  RequestedMerchant({
    this.merchantId,
    this.name,
    this.description,
    this.isOwnedByApp,
    this.createdAt,
    this.notes,
    this.zoneId,
    this.category,
    this.logoUrl,
    this.coverUrl,
    this.hotlineNumber,
    this.location,
    this.extras = const {},
  });

  factory RequestedMerchant.fromJson(Map<String, dynamic> json) {
    const consumed = {
      'merchantId',
      'name',
      'description',
      'isOwnedByApp',
      'merchantCreatedAt',
      'notes',
      'zoneId',
      'category',
      'media',
      'contact',
      'location',
    };

    final media = asMap(json['media']);
    final contact = asMap(json['contact']);

    return RequestedMerchant(
      merchantId: asInt(json['merchantId']),
      name: asString(json['name']),
      description: asString(json['description']),
      isOwnedByApp: json['isOwnedByApp'] is bool ? json['isOwnedByApp'] as bool : null,
      createdAt: asDate(json['merchantCreatedAt']),
      notes: asString(json['notes']),
      zoneId: asInt(json['zoneId']),
      category: json['category'] is Map
          ? RequestedMerchantCategory.fromJson(
              Map<String, dynamic>.from(json['category'] as Map))
          : null,
      logoUrl: media != null ? asString(media['logoKey']) : null,
      coverUrl: media != null ? asString(media['coverKey']) : null,
      hotlineNumber: contact != null ? asString(contact['hotlineNumber']) : null,
      location: json['location'] is Map
          ? RequestedMerchantLocation.fromJson(
              Map<String, dynamic>.from(json['location'] as Map))
          : null,
      extras: collectExtras(json, consumed),
    );
  }

  Map<String, dynamic> toJson() => {
        'merchantId': merchantId,
        'name': name,
        'description': description,
        'isOwnedByApp': isOwnedByApp,
        'merchantCreatedAt': createdAt?.toIso8601String(),
        'notes': notes,
        'zoneId': zoneId,
        'category': category?.toJson(),
        'media': {'logoKey': logoUrl, 'coverKey': coverUrl},
        'contact': {'hotlineNumber': hotlineNumber},
        'location': location?.toJson(),
        ...extras,
      };
}

class RequestedMerchantCategory {
  final int? categoryId;
  final String? categoryName;

  /// The plain S3 object URL.
  final String? iconKey;

  /// The presigned variant. Kept separate from [iconKey] because the two can
  /// disagree, so the UI can try one and fall back to the other.
  final String? iconUrl;

  RequestedMerchantCategory({
    this.categoryId,
    this.categoryName,
    this.iconKey,
    this.iconUrl,
  });

  /// Image URLs to try, in order, skipping blanks and duplicates.
  List<String> get iconCandidates {
    final candidates = <String>[];
    for (final url in [iconUrl, iconKey]) {
      if (url != null && url.isNotEmpty && !candidates.contains(url)) {
        candidates.add(url);
      }
    }
    return candidates;
  }

  factory RequestedMerchantCategory.fromJson(Map<String, dynamic> json) {
    return RequestedMerchantCategory(
      categoryId: asInt(json['categoryId']),
      categoryName: asString(json['categoryName']),
      iconKey: asString(json['categoryIcon']),
      iconUrl: asString(json['categoryIconUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryIcon': iconKey,
        'categoryIconUrl': iconUrl,
      };
}

class RequestedMerchantLocation {
  final double? latitude;
  final double? longitude;
  final String? street;
  final String? building;

  RequestedMerchantLocation({
    this.latitude,
    this.longitude,
    this.street,
    this.building,
  });

  /// `building, street` — whichever parts are present.
  String? get formattedAddress {
    final parts = [building, street].where((p) => p != null && p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(', ');
  }

  String? get formattedCoordinates {
    if (latitude == null || longitude == null) return null;
    return '$latitude, $longitude';
  }

  factory RequestedMerchantLocation.fromJson(Map<String, dynamic> json) {
    return RequestedMerchantLocation(
      // The API sends these as strings ("33.8935").
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      street: asString(json['street']),
      building: asString(json['building']),
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude?.toString(),
        'longitude': longitude?.toString(),
        'street': street,
        'building': building,
      };
}

// --- shared coercion helpers -------------------------------------------------

/// Every key not in [consumed], so unexpected API fields survive parsing.
Map<String, dynamic> collectExtras(
  Map<String, dynamic> json,
  Set<String> consumed,
) {
  return {
    for (final entry in json.entries)
      if (!consumed.contains(entry.key) && entry.value != null)
        entry.key: entry.value,
  };
}

Map<String, dynamic>? asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

int? asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? asString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  if (value is Map || value is List) return null;
  return value.toString();
}

DateTime? asDate(dynamic value) {
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}
