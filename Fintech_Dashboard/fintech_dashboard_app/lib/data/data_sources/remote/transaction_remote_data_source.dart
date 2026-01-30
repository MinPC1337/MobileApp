import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String userId, String transactionId);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final FirebaseFirestore firestore;

  TransactionRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('transactions')
        .doc(transaction.id.toString())
        .set(transaction.toMap());
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('transactions')
        .doc(transaction.id.toString())
        .update(transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }
}
