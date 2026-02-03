import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<void> addCategory(CategoryModel category);
  Future<List<CategoryModel>> getCategories(String userId);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirebaseFirestore firestore;

  CategoryRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> addCategory(CategoryModel category) async {
    // Lưu category vào sub-collection của user hoặc collection chung tùy thiết kế
    // Ở đây lưu vào sub-collection 'categories' của user
    await firestore
        .collection('users')
        .doc(category.userId)
        .collection('categories')
        .doc(category.id.toString())
        .set(category.toMap());
  }

  @override
  Future<List<CategoryModel>> getCategories(String userId) async {
    // Hàm này có thể dùng để sync về sau
    return [];
  }
}
