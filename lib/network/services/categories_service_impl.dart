import 'package:namnam/model/category.dart';
import 'package:namnam/model/response/ApiResponse.dart';
import 'package:namnam/model/response/Status.dart';
import 'package:namnam/network/ApiEndPoints.dart';
import 'package:namnam/network/NetworkApiService.dart';
import 'package:namnam/network/services/categories_service.dart';
import 'package:namnam/model/request/create_category_request.dart';
import 'package:namnam/model/request/edit_category_request.dart';
import 'package:namnam/core/Utility/Preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoriesServiceImpl implements CategoriesService {
  final NetworkApiService _networkApiService = NetworkApiService();

  @override
  Future<ApiResponse<List<Category>>> getCategories({int? parentId}) async {
    print('CategoriesServiceImpl: Starting getCategories request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();
      
      print('CategoriesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');
      
      // Build query parameters
      Map<String, dynamic> queryParams = {};
      // Always pass parentId parameter - empty string if null, otherwise the value
      queryParams['parentId'] = parentId?.toString() ?? '';
      
      print('CategoriesServiceImpl: Query parameters: $queryParams');

      final response = await _networkApiService.fetchData(
        ApiEndPoints.getCategories,
        queryParams,
        accessToken.isNotEmpty ? accessToken : null, // Use Bearer token if available
      );

      print('CategoriesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('CategoriesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        if (response.data != null) {
          print('CategoriesServiceImpl: Processing successful response...');
          
          // Parse the data as a List
          if (response.data is List) {
            final List rawList = response.data as List;
            // The API sometimes double-wraps results in an extra array
            // level (e.g. [[{...}, {...}]] instead of [{...}, {...}]).
            final List flatList = rawList.isNotEmpty && rawList.first is List
                ? rawList.expand((e) => e as List).toList()
                : rawList;
            final List<Category> categories = flatList
                .map((item) => Category.fromJson(item))
                .toList();
            
            print('CategoriesServiceImpl: Categories parsed - Count: ${categories.length}');
            return ApiResponse(
              Status.COMPLETED,
              categories,
              response.message,
            );
          } else {
            print('CategoriesServiceImpl: Response data is not a List');
            return ApiResponse(
              Status.ERROR,
              null,
              'Invalid response format: Expected List',
            );
          }
        } else {
          print('CategoriesServiceImpl: Response data is null');
          return ApiResponse(
            Status.ERROR,
            null,
            'No categories data received',
          );
        }
      } else {
        print('CategoriesServiceImpl: Response status is not COMPLETED');
        
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
          response.message ?? 'Failed to fetch categories',
        );
      }
    } catch (e) {
      print('CategoriesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to fetch categories: $e',
      );
    }
  }

  @override
  Future<ApiResponse<Category>> createCategory(CreateCategoryRequest request) async {
    print('CategoriesServiceImpl: Starting createCategory request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();
      
      print('CategoriesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');
      print('CategoriesServiceImpl: Request data: ${request.toJson()}');

      final response = await _networkApiService.postResponse(
        ApiEndPoints.createCategory,
        request.toJson(),
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('CategoriesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('CategoriesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        if (response.data != null) {
          print('CategoriesServiceImpl: Processing successful response...');
          final category = Category.fromJson(response.data);
          print('CategoriesServiceImpl: Category created - ID: ${category.categoryId}');
          return ApiResponse(
            Status.COMPLETED,
            category,
            response.message,
          );
        } else {
          // The API returns {success: true} with no "data" payload on
          // creation, so a null body here still means success.
          print('CategoriesServiceImpl: Category created successfully (no data payload returned)');
          final category = Category(
            createdAt: DateTime.now().toIso8601String(),
            categoryId: 0,
            categoryName: request.name,
            parentId: request.parentId,
            imageUrl: request.imageKey,
            status: request.status,
          );
          return ApiResponse(
            Status.COMPLETED,
            category,
            response.message,
          );
        }
      } else {
        print('CategoriesServiceImpl: Response status is not COMPLETED');
        
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
          response.message ?? 'Failed to create category',
        );
      }
    } catch (e) {
      print('CategoriesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to create category: $e',
      );
    }
  }

  @override
  Future<ApiResponse<Category>> editCategory(EditCategoryRequest request) async {
    print('CategoriesServiceImpl: Starting editCategory request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('CategoriesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');
      print('CategoriesServiceImpl: Request data: ${request.toJson()}');

      final response = await _networkApiService.patchResponse(
        ApiEndPoints.updateCategory,
        request.toJson(),
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('CategoriesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');
      print('CategoriesServiceImpl: Response data: ${response.data}');

      if (response.status == Status.COMPLETED) {
        if (response.data != null) {
          print('CategoriesServiceImpl: Processing successful response...');
          final category = Category.fromJson(response.data);
          print('CategoriesServiceImpl: Category updated - ID: ${category.categoryId}');
          return ApiResponse(
            Status.COMPLETED,
            category,
            response.message,
          );
        } else {
          // The API returns {success: true} with no "data" payload on
          // update, so a null body here still means success.
          print('CategoriesServiceImpl: Category updated successfully (no data payload returned)');
          final category = Category(
            createdAt: DateTime.now().toIso8601String(),
            categoryId: request.id,
            categoryName: request.name,
            parentId: request.parentId,
            imageUrl: request.imageKey,
            status: request.status,
          );
          return ApiResponse(
            Status.COMPLETED,
            category,
            response.message,
          );
        }
      } else {
        print('CategoriesServiceImpl: Response status is not COMPLETED');

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
          response.message ?? 'Failed to update category',
        );
      }
    } catch (e) {
      print('CategoriesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to update category: $e',
      );
    }
  }

  @override
  Future<ApiResponse<bool>> deleteCategory(int categoryId) async {
    print('CategoriesServiceImpl: Starting deleteCategory request...');
    try {
      // Get access token from preferences
      final prefs = await SharedPreferences.getInstance();
      final prefProvider = PrefProvider(prefs);
      final accessToken = prefProvider.getAccessToken();

      print('CategoriesServiceImpl: Access token retrieved: ${accessToken.isNotEmpty ? 'Present' : 'Not found'}');

      final response = await _networkApiService.deleteResponse(
        ApiEndPoints.deleteCategory(categoryId),
        accessToken.isNotEmpty ? accessToken : null,
      );

      print('CategoriesServiceImpl: Network response - Status: ${response.status}, Message: ${response.message}');

      if (response.status == Status.COMPLETED) {
        print('CategoriesServiceImpl: Category deleted successfully!');
        return ApiResponse(
          Status.COMPLETED,
          true,
          response.message,
        );
      } else {
        print('CategoriesServiceImpl: Response status is not COMPLETED');

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
          response.message ?? 'Failed to delete category',
        );
      }
    } catch (e) {
      print('CategoriesServiceImpl: Exception occurred: $e');
      return ApiResponse(
        Status.ERROR,
        null,
        'Failed to delete category: $e',
      );
    }
  }
}
