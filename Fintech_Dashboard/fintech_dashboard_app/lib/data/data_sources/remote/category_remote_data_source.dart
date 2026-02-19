import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';

abstract class CategoryRemoteDataSource {
  Future<void> addCategory(CategoryModel category);
  Future<List<CategoryModel>> getCategories(String userId);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String userId, String categoryId);
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
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = int.tryParse(doc.id); // Lấy ID từ document và gán vào map
      return CategoryModel.fromMap(data);
    }).toList();
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    if (category.userId == null) return;
    await firestore
        .collection('users')
        .doc(category.userId)
        .collection('categories')
        .doc(category.id.toString())
        .update(category.toMap());
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }
}
