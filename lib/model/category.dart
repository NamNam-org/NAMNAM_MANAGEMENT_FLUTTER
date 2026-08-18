class Category {
  final String? type;
  final String? status;
  final String? imageUrl;
  final int? parentId;
  final String createdAt;
  final int categoryId;
  final String categoryName;

  Category({
    this.type,
    this.status,
    this.imageUrl,
    this.parentId,
    required this.createdAt,
    required this.categoryId,
    required this.categoryName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      type: json['type'],
      status: json['status'],
      imageUrl: json['imageUrl'] ?? json['imageKey'],
      parentId: json['parentId'],
      createdAt: json['createdAt'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'imageUrl': imageUrl,
      'parentId': parentId,
      'createdAt': createdAt,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }

  String get parentName {
    if (parentId == null || parentId == 0) {
      return 'Root';
    }
    return 'Parent Category'; // This would need to be resolved from actual parent data
  }



  String get displayImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return imageUrl!;
    }
    return 'https://via.placeholder.com/50x50?text=No+Image';
  }
}

