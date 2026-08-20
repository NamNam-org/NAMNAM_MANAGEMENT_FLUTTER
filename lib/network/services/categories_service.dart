import 'package:namnam/model/category.dart';
import 'package:namnam/model/response/ApiResponse.dart';
import 'package:namnam/model/request/create_category_request.dart';
import 'package:namnam/model/request/edit_category_request.dart';

abstract class CategoriesService {
  Future<ApiResponse<List<Category>>> getCategories({int? parentId});
  Future<ApiResponse<Category>> createCategory(CreateCategoryRequest request);
  Future<ApiResponse<Category>> editCategory(EditCategoryRequest request);
  Future<ApiResponse<bool>> deleteCategory(int categoryId);
}
