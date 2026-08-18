import 'package:flutter/material.dart';
import 'package:namnam/core/Utility/appcolors.dart';
import 'package:namnam/view/Web/widgets/custom_toast.dart';
import 'package:namnam/view/Web/widgets/proceedBtn.dart';
import 'package:namnam/view/Web/widgets/expandable_categories_table.dart';
import 'package:namnam/view/Web/widgets/reusable_data_table.dart';
import 'package:provider/provider.dart';
import 'package:namnam/viewmodel/categories_view_model.dart';
import 'package:namnam/model/request/create_category_request.dart';
import 'package:namnam/model/response/Status.dart';
import 'package:namnam/model/category.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:namnam/viewmodel/upload_view_model.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categoriesViewModel = Provider.of<CategoriesViewModel>(context, listen: false);
      categoriesViewModel.fetchCategories(parentId: null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriesViewModel>(
      builder: (context, categoriesViewModel, child) {
        if (categoriesViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (categoriesViewModel.status == Status.ERROR) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categoriesViewModel.isAuthenticationError 
                    ? Icons.lock_outline 
                    : Icons.error_outline,
                  size: 64,
                  color: categoriesViewModel.isAuthenticationError 
                    ? Colors.orange.shade400 
                    : Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  categoriesViewModel.isAuthenticationError 
                    ? 'Authentication Required'
                    : 'Error loading categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: categoriesViewModel.isAuthenticationError 
                      ? Colors.orange.shade400 
                      : Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  categoriesViewModel.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (categoriesViewModel.isAuthenticationError) ...[
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to login page
                      ToastManager.show(
                        context: context,
                        message: 'Please log in again to continue',
                        type: ToastType.error,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade400,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Go to Login'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () {
                      categoriesViewModel.refreshCategories();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Appcolors.appPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                                        child: Image.asset(
                    "assets/logo/namnam_white_logo.png",
                    height: 32,
                    width: 32,
                  ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categories Management',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Appcolors.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Manage your product categories and subcategories',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ProceedBtn(
                      text: 'Add Category',
                      color: Appcolors.appPrimaryColor,
                      onPressed: () {
                        _showAddCategoryDialog();
                      },
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Reusable Table
              _buildReusableCategoriesTable(categoriesViewModel.categories),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReusableCategoriesTable(List<Category> categories) {
    // Define table columns
    final columns = [
      TableColumn<Category>(
        title: 'ID',
        key: 'categoryId',
        width: 60,
        sortable: true,
        sortKey: (category) => category.categoryId.toString(),
      ),
      TableColumn<Category>(
        title: 'Image',
        key: 'imageUrl',
        width: 80,
        customBuilder: (category) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(category.displayImageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      TableColumn<Category>(
        title: 'Name',
        key: 'categoryName',
        width: 200,
        sortable: true,
        sortKey: (category) => category.categoryName,
      ),
      TableColumn<Category>(
        title: 'Parent',
        key: 'parentName',
        width: 150,
        customBuilder: (category) => Text(
          category.parentName,
          style: TextStyle(
            color: category.parentId == null || category.parentId == 0 ? Colors.grey.shade500 : Appcolors.textPrimaryColor,
            fontStyle: category.parentId == null || category.parentId == 0 ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
      TableColumn<Category>(
        title: 'Status',
        key: 'status',
        width: 140,
        customBuilder: (category) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
                    color: (category.status ?? 'inactive') == 'active' 
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (category.status ?? 'inactive') == 'active' ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          category.status ?? 'inactive',
          style: TextStyle(
            color: (category.status ?? 'inactive') == 'active' ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ];

    // Define table actions
    final actions = [
      TableAction<Category>(
        label: 'Edit',
        icon: Icons.edit,
        color: Appcolors.appPrimaryColor,
        onPressed: (category) {
          // TODO: Implement edit functionality
          ToastManager.show(
            context: context,
            message: 'Edit ${category.categoryName}',
            type: ToastType.success,
          );
        },
      ),
      TableAction<Category>(
        label: 'Toggle Status',
        icon: Icons.block,
        color: Colors.red,
        onPressed: (category) {
          // TODO: Implement status toggle
          ToastManager.show(
            context: context,
            message: 'Toggle ${category.categoryName} status',
            type: ToastType.success,
          );
        },
        isVisible: (category) => (category.status ?? 'inactive') == 'active',
      ),
      TableAction<Category>(
        label: 'Activate',
        icon: Icons.check_circle,
        color: Colors.green,
        onPressed: (category) {
          // TODO: Implement activate functionality
          ToastManager.show(
            context: context,
            message: 'Activate ${category.categoryName}',
            type: ToastType.success,
          );
        },
        isVisible: (category) => (category.status ?? 'inactive') == 'inactive',
      ),
    ];

    return ExpandableCategoriesTable(
      categories: categories,
      actions: actions,
      itemsPerPage: 10,
      showRowNumbers: true,
      tableHeight: 600,
      onItemsPerPageChanged: (newItemsPerPage) {
        // Handle items per page change if needed
        // For example, you could save this preference or make an API call
        print('Items per page changed to: $newItemsPerPage');
      },
    );
  }

  void _showAddCategoryDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    String? selectedImagePath;
    Uint8List? selectedImageBytes;
    int? selectedParentId;
    String selectedStatus = 'active';
    List<Category> parentCategories = [];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Image.asset(
                "assets/logo/namnam_white_logo.png",
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 8),
              Text('Add New Category'),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Category name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Parent Category Dropdown
                    Consumer<CategoriesViewModel>(
                      builder: (context, categoriesViewModel, child) {
                        // Load parent categories if not loaded
                        if (parentCategories.isEmpty && categoriesViewModel.categories.isNotEmpty) {
                          // Filter to get only root categories (parentId is null or 0)
                          parentCategories = categoriesViewModel.categories
                              .where((cat) => cat.parentId == null || cat.parentId == 0)
                              .toList();
                        }
                        
                        return DropdownButtonFormField<int>(
                          value: selectedParentId,
                          decoration: InputDecoration(
                            labelText: 'Parent Category (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: [
                            DropdownMenuItem<int>(
                              value: null,
                              child: Text('No Parent'),
                            ),
                            ...parentCategories.map((category) => DropdownMenuItem<int>(
                              value: category.categoryId,
                              child: Text(category.categoryName),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedParentId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value ?? 'active';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            print('Opening file picker...');
                            
                            // Web file picking
                            FilePickerResult? result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowMultiple: false,
                              allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
                              withData: true, // Important for web
                            );
                            
                            print('File picker result: $result');
                            
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.first;
                              print('Selected file: ${file.name}, size: ${file.size}');
                              
                              setState(() {
                                selectedImagePath = file.name;
                                selectedImageBytes = file.bytes;
                              });
                              print('Image selected successfully: $selectedImagePath');
                              
                              ToastManager.show(
                                context: context,
                                message: 'Image selected: ${file.name}',
                                type: ToastType.success,
                              );
                            }
                          } catch (e) {
                            print('Error picking file: $e');
                            
                            // Show more specific error message
                            String errorMessage = 'Error selecting image';
                            if (e.toString().contains('LateInitializationError')) {
                              errorMessage = 'File picker not initialized. Please try again.';
                            } else if (e.toString().contains('Permission')) {
                              errorMessage = 'Permission denied. Please allow file access.';
                            } else {
                              errorMessage = 'Error selecting image: ${e.toString()}';
                            }
                            
                            ToastManager.show(
                              context: context,
                              message: errorMessage,
                              type: ToastType.error,
                            );
                          }
                        },
                        icon: Icon(Icons.upload_file),
                        label: Text('Select Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Appcolors.textPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (selectedImagePath != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Image selected: ${selectedImagePath!.split('/').last}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Image preview
                            if (selectedImageBytes != null) ...[
                              // Show actual image preview
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Show placeholder when no image selected
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'No Image',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (selectedImagePath != null) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      selectedImagePath = null;
                                      selectedImageBytes = null;
                                    });
                                  },
                                  icon: Icon(Icons.delete, size: 16),
                                  label: Text('Remove Image'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final categoriesViewModel = Provider.of<CategoriesViewModel>(context, listen: false);
                  final uploadViewModel = Provider.of<UploadViewModel>(context, listen: false);
                  
                  String? imageKey;
                  
                  // Upload file if image is selected
                  if (selectedImageBytes != null) {
                    // Create a PlatformFile from the selected bytes
                    final file = PlatformFile(
                      name: selectedImagePath!.split('/').last,
                      size: selectedImageBytes!.length,
                      bytes: selectedImageBytes,
                    );
                    
                    // Upload the file and get the image key
                    imageKey = await uploadViewModel.uploadFile(file);
                    
                    if (imageKey == null) {
                      ToastManager.show(
                        context: context,
                        message: 'Failed to upload image. Please try again.',
                        type: ToastType.error,
                      );
                      return;
                    }
                  }
                  
                  final request = CreateCategoryRequest(
                    name: nameController.text.trim(),
                    parentId: selectedParentId, // Use selected parent ID (null if no parent selected)
                    imageKey: imageKey, // Use the uploaded image key
                    status: selectedStatus,
                  );

                  final success = await categoriesViewModel.createCategory(request);
                  if (success && context.mounted) {
                    Navigator.of(context).pop();
                    ToastManager.show(
                      context: context,
                      message: 'Category created successfully!',
                      type: ToastType.success,
                    );
                    // Refresh the categories list
                    categoriesViewModel.refreshCategories();
                  } else if (context.mounted) {
                    ToastManager.show(
                      context: context,
                      message: categoriesViewModel.message.isNotEmpty 
                          ? categoriesViewModel.message 
                          : 'Failed to create category',
                      type: ToastType.error,
                    );
                  }
                }
              },
              child: Text('Create Category'),
            ),
          ],
        );
      },
    );
  }
} 