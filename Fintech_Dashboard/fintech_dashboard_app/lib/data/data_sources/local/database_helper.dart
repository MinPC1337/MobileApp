import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(
      'finance_app.db',
    ); // Đổi tên để tạo DB mới, tránh lỗi cấu trúc cũ
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // SQLite dùng 0 hoặc 1 cho boolean
    const numType = 'REAL NOT NULL';

    // 1. Tạo bảng User
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY, 
        email $textType,
        display_name $textType,
        currency $textType,
        created_at $textType
      )
    ''');

    // 2. Tạo bảng Category
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        type $textType, -- 'income' hoặc 'expense'
        icon $textType,
        user_id TEXT, -- Null nếu là danh mục mặc định
        updated_at $textType,
        is_synced $boolType DEFAULT 0
      )
    ''');

    // 3. Tạo bảng Transaction
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        amount $numType,
        note TEXT,
        date $textType,
        category_id INTEGER,
        user_id $textType,
        is_synced $boolType DEFAULT 0,
        updated_at $textType,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 4. Tạo bảng Budget
    await db.execute('''
      CREATE TABLE budgets (
        id $idType,
        amount $numType,
        category_id INTEGER,
        user_id $textType,
        created_at $textType,
        is_synced $boolType DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Chèn một số danh mục mặc định
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon, updated_at, is_synced) VALUES("Ăn uống", "expense", "fastfood", "${DateTime.now().toIso8601String()}", 1)',
    );
    await db.rawInsert(
      'INSERT INTO categories(name, type, icon, updated_at, is_synced) VALUES("Lương", "income", "payments", "${DateTime.now().toIso8601String()}", 1)',
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
