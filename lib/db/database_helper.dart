import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('moto_pos_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE products (
  id $idType,
  name $textType,
  barcode $textType,
  price $realType,
  stock_quantity $integerType,
  category $textNullable,
  description $textNullable,
  purchase_price $realType,
  image_path $textNullable,
  brand $textNullable,
  low_stock_limit $integerType
)
''');

    await db.execute('''
CREATE TABLE sales (
  id $idType,
  date $textType,
  total_amount $realType
)
''');

    await db.execute('''
CREATE TABLE sale_items (
  id $idType,
  sale_id $integerType,
  product_id $integerType,
  quantity $integerType,
  price_at_sale $realType,
  discount $realType,
  discount_type $textType,
  FOREIGN KEY (sale_id) REFERENCES sales (id),
  FOREIGN KEY (product_id) REFERENCES products (id)
)
''');
  }

  // Product CRUD
  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert('products', product.toMap());
    return Product(
      id: id,
      name: product.name,
      barcode: product.barcode,
      price: product.price,
      stockQuantity: product.stockQuantity,
      category: product.category,
      description: product.description,
      purchasePrice: product.purchasePrice,
      imagePath: product.imagePath,
      brand: product.brand,
      lowStockLimit: product.lowStockLimit,
    );
  }

  Future<Product?> readProduct(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      columns: ['id', 'name', 'barcode', 'price', 'stock_quantity', 'category', 'description', 'purchase_price', 'image_path', 'brand', 'low_stock_limit'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Product>> readAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sales
  Future<int> createSale(Sale sale) async {
    final db = await instance.database;
    return await db.insert('sales', sale.toMap());
  }

  Future<int> createSaleItem(SaleItem saleItem) async {
    final db = await instance.database;
    return await db.insert('sale_items', saleItem.toMap());
  }
  
  Future<List<Sale>> readAllSales() async {
    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'date DESC');
    return result.map((json) => Sale.fromMap(json)).toList();
  }
  
  Future<List<SaleItem>> readSaleItems(int saleId) async {
    final db = await instance.database;
    final result = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
    );
    return result.map((json) => SaleItem.fromMap(json)).toList();
  }

  // Dashboard Stats with Time Range
  Future<Map<String, dynamic>> getDashboardStats(String timeRange) async {
    final db = await instance.database;
    
    String dateFilter = '';
    DateTime now = DateTime.now();
    
    if (timeRange == 'day') {
      String today = now.toIso8601String().substring(0, 10);
      dateFilter = "WHERE date LIKE '$today%'";
    } else if (timeRange == 'week') {
      DateTime weekAgo = now.subtract(const Duration(days: 7));
      dateFilter = "WHERE date >= '${weekAgo.toIso8601String()}'";
    } else if (timeRange == 'month') {
      String month = now.toIso8601String().substring(0, 7);
      dateFilter = "WHERE date LIKE '$month%'";
    } else if (timeRange == 'year') {
      String year = now.toIso8601String().substring(0, 4);
      dateFilter = "WHERE date LIKE '$year%'";
    }

    // Total Sales
    final salesResult = await db.rawQuery('SELECT SUM(total_amount) as total FROM sales $dateFilter');
    final totalSales = salesResult.first['total'] as double? ?? 0.0;

    // Total Orders
    final ordersResult = await db.rawQuery('SELECT COUNT(*) as count FROM sales $dateFilter');
    final totalOrders = ordersResult.first['count'] as int? ?? 0;

    // Total Profit
    // We need to filter sale_items based on the sale date
    final profitResult = await db.rawQuery('''
      SELECT SUM(
        CASE
          WHEN si.discount_type = 'percent' THEN
            ((si.price_at_sale * (1 - si.discount / 100.0)) - p.purchase_price) * si.quantity
          ELSE
            ((si.price_at_sale - p.purchase_price) * si.quantity) - si.discount
        END
      ) as profit
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      JOIN sales s ON si.sale_id = s.id
      $dateFilter
    ''');
    final totalProfit = profitResult.first['profit'] as double? ?? 0.0;

    return {
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'totalProfit': totalProfit,
    };
  }

  // Chart Data: Sales & Profit over time
  Future<List<Map<String, dynamic>>> getSalesAndProfitOverTime(String timeRange) async {
    final db = await instance.database;
    
    String groupBy = '';
    String dateFormat = '';
    String dateFilter = '';
    DateTime now = DateTime.now();

    if (timeRange == 'day') {
      // Group by Hour
      String today = now.toIso8601String().substring(0, 10);
      dateFilter = "WHERE s.date LIKE '$today%'";
      // SQLite doesn't have great date formatting, assuming ISO8601 string
      // substr(date, 12, 2) extracts the hour HH from YYYY-MM-DDTHH:MM:SS
      groupBy = 'substr(s.date, 12, 2)'; 
    } else if (timeRange == 'week') {
      // Group by Day
      DateTime weekAgo = now.subtract(const Duration(days: 7));
      dateFilter = "WHERE s.date >= '${weekAgo.toIso8601String()}'";
      groupBy = 'substr(s.date, 1, 10)'; // YYYY-MM-DD
    } else if (timeRange == 'month') {
      // Group by Day
      String month = now.toIso8601String().substring(0, 7);
      dateFilter = "WHERE s.date LIKE '$month%'";
      groupBy = 'substr(s.date, 1, 10)';
    } else if (timeRange == 'year') {
      // Group by Month
      String year = now.toIso8601String().substring(0, 4);
      dateFilter = "WHERE s.date LIKE '$year%'";
      groupBy = 'substr(s.date, 1, 7)'; // YYYY-MM
    }

    final result = await db.rawQuery('''
      SELECT 
        $groupBy as time_group,
        SUM(s.total_amount) as sales,
        SUM(
          CASE
            WHEN si.discount_type = 'percent' THEN
              ((si.price_at_sale * (1 - si.discount / 100.0)) - p.purchase_price) * si.quantity
            ELSE
              ((si.price_at_sale - p.purchase_price) * si.quantity) - si.discount
          END
        ) as profit
      FROM sales s
      JOIN sale_items si ON s.id = si.sale_id
      JOIN products p ON si.product_id = p.id
      $dateFilter
      GROUP BY time_group
      ORDER BY time_group ASC
    ''');

    return result;
  }

  // Get Sale Items with Product Name for Dialog
  Future<List<Map<String, dynamic>>> getSaleItemsWithProduct(int saleId) async {
    final db = await instance.database;
    return await db.rawQuery('''
      SELECT 
        si.*,
        p.name as product_name
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
    ''', [saleId]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
