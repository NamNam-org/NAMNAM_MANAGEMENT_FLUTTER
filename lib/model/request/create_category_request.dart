class CreateCategoryRequest {
  final String name;
  final int? parentId;
  final String? imageKey;
  final String status;

  CreateCategoryRequest({
    required this.name,
    this.parentId,
    this.imageKey,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (parentId != null) 'parentId': parentId,
      if (imageKey != null) 'imageKey': imageKey,
      'status': status,
    };
  }
}

