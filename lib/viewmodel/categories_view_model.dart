import 'package:flutter/material.dart';
import 'package:namnam/model/category.dart';
import 'package:namnam/model/response/Status.dart';
import 'package:namnam/network/services/categories_service.dart';
import 'package:namnam/network/services/categories_service_impl.dart';
import 'package:namnam/model/request/create_category_request.dart';
import 'package:namnam/model/request/edit_category_request.dart';

class CategoriesViewModel extends ChangeNotifier {
  final CategoriesService _categoriesService = CategoriesServiceImpl();
  
  Status _status = Status.COMPLETED;
  String _message = '';
  List<Category> _categories = [];
  bool _isLoading = false;
  int? _currentParentId;

  Status get status => _status;
  String get message => _message;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  int? get currentParentId => _currentParentId;
  bool get isAuthenticationError => _message.toLowerCase().contains('authentication failed');

  Future<bool> fetchCategories({int? parentId}) async {
    print('CategoriesViewModel: Starting fetchCategories...');
    _setLoading(true);
    _setStatus(Status.LOADING);

    try {
      _currentParentId = parentId;
      print('CategoriesViewModel: Fetching categories with parentId: $parentId');
      
      final response = await _categoriesService.getCategories(parentId: parentId);

      print('CategoriesViewModel: Response received - Status: ${response.status}, Message: ${response.message}');
      _setStatus(response.status!);
      _setMessage(response.message ?? '');

      if (response.status == Status.COMPLETED) {
        print('CategoriesViewModel: Categories fetched successfully!');
        _categories = response.data ?? [];
        print('CategoriesViewModel: Categories count: ${_categories.length}');
        _setLoading(false);
        return true;
      } else {
        print('CategoriesViewModel: Failed to fetch categories - Status: ${response.status}');
        _categories = [];
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('CategoriesViewModel: Exception occurred: $e');
      _setStatus(Status.ERROR);
      _setMessage('Failed to fetch categories: $e');
      _categories = [];
      _setLoading(false);
      return false;
    }
  }

  Future<List<Category>> fetchSubcategories(int parentId) async {
    print('CategoriesViewModel: Starting fetchSubcategories for parentId: $parentId');
    
    try {
      final response = await _categoriesService.getCategories(parentId: parentId);

      if (response.status == Status.COMPLETED) {
        print('CategoriesViewModel: Subcategories fetched successfully!');
        final subcategories = response.data ?? [];
        print('CategoriesViewModel: Subcategories count: ${subcategories.length}');
        return subcategories;
      } else {
        print('CategoriesViewModel: Failed to fetch subcategories - Status: ${response.status}');
        return [];
      }
    } catch (e) {
      print('CategoriesViewModel: Exception occurred while fetching subcategories: $e');
      return [];
    }
  }

  void refreshCategories() {
    fetchCategories(parentId: _currentParentId);
  }

  Future<bool> createCategory(CreateCategoryRequest request) async {
    print('CategoriesViewModel: Starting createCategory...');
    _setLoading(true);
    _setStatus(Status.LOADING);

    try {
      print('CategoriesViewModel: Creating category with data: ${request.toJson()}');
      
      final response = await _categoriesService.createCategory(request);

      print('CategoriesViewModel: Response received - Status: ${response.status}, Message: ${response.message}');
      _setStatus(response.status!);
      _setMessage(response.message ?? '');

      if (response.status == Status.COMPLETED) {
        print('CategoriesViewModel: Category created successfully!');
        _setLoading(false);
        return true;
      } else {
        print('CategoriesViewModel: Failed to create category - Status: ${response.status}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('CategoriesViewModel: Exception occurred: $e');
      _setStatus(Status.ERROR);
      _setMessage('Failed to create category: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> editCategory(EditCategoryRequest request) async {
    print('CategoriesViewModel: Starting editCategory...');
    _setLoading(true);
    _setStatus(Status.LOADING);

    try {
      print('CategoriesViewModel: Updating category with data: ${request.toJson()}');

      final response = await _categoriesService.editCategory(request);

      print('CategoriesViewModel: Response received - Status: ${response.status}, Message: ${response.message}');
      _setStatus(response.status!);
      _setMessage(response.message ?? '');

      if (response.status == Status.COMPLETED) {
        print('CategoriesViewModel: Category updated successfully!');
        _setLoading(false);
        return true;
      } else {
        print('CategoriesViewModel: Failed to update category - Status: ${response.status}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('CategoriesViewModel: Exception occurred: $e');
      _setStatus(Status.ERROR);
      _setMessage('Failed to update category: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    print('CategoriesViewModel: Starting deleteCategory...');
    _setLoading(true);
    _setStatus(Status.LOADING);

    try {
      print('CategoriesViewModel: Deleting category with ID: $categoryId');

      final response = await _categoriesService.deleteCategory(categoryId);

      print('CategoriesViewModel: Response received - Status: ${response.status}, Message: ${response.message}');
      _setStatus(response.status!);
      _setMessage(response.message ?? '');

      if (response.status == Status.COMPLETED) {
        print('CategoriesViewModel: Category deleted successfully!');
        _setLoading(false);
        return true;
      } else {
        print('CategoriesViewModel: Failed to delete category - Status: ${response.status}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('CategoriesViewModel: Exception occurred: $e');
      _setStatus(Status.ERROR);
      _setMessage('Failed to delete category: $e');
      _setLoading(false);
      return false;
    }
  }

  void reset() {
    _status = Status.COMPLETED;
    _message = '';
    _categories = [];
    _isLoading = false;
    _currentParentId = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setStatus(Status status) {
    _status = status;
    notifyListeners();
  }

  void _setMessage(String message) {
    _message = message;
    notifyListeners();
  }
}
