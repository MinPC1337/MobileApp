import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    super.id,
    required super.amount,
    required super.note,
    required super.date,
    required super.categoryId,
    required super.userId,
    super.isSynced,
    required super.updatedAt,
  });

  // Chuyển từ Map (Dữ liệu từ SQLite) sang Model
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      amount: map['amount'],
      note: map['note'],
      date: DateTime.parse(map['date']),
      categoryId: map['category_id'],
      userId: map['user_id'],
      isSynced: map['is_synced'] == 1, // Chuyển Integer 0/1 sang Boolean
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Chuyển từ Model sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'user_id': userId,
      'is_synced': isSynced ? 1 : 0, // Chuyển Boolean sang Integer
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Phương thức hỗ trợ tạo Model từ Entity (Dùng trong Repository)
  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      amount: entity.amount,
      note: entity.note,
      date: entity.date,
      categoryId: entity.categoryId,
      userId: entity.userId,
      isSynced: entity.isSynced,
      updatedAt: entity.updatedAt,
    );
  }
}
