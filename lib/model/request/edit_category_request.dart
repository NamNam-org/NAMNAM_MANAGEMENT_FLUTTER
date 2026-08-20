class EditCategoryRequest {
  final int id;
  final String name;
  final int? parentId;
  final String? imageKey;
  final String status;

  EditCategoryRequest({
    required this.id,
    required this.name,
    this.parentId,
    this.imageKey,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (parentId != null) 'parentId': parentId,
      if (imageKey != null) 'imageKey': imageKey,
      'status': status,
    };
  }
}
