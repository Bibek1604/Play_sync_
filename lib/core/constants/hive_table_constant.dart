/// Central location for all Hive-related constants
///
/// Type IDs must be unique within the range 0-223 for Hive adapters
/// Follow sequential numbering when adding new types
class HiveTableConstant {
  HiveTableConstant._();

  // Database name
  static const String dbName = "play_sync_db";

  // ===== TYPE IDs (0-223) =====
  // These must be unique for each Hive model
  static const int itemTypeId = 0;
  static const int categoryTypeId = 1;
  static const int batchTypeId = 2;
  static const int userTypeId = 3;
  static const int authTypeId = 4;
  static const int productTypeId = 5;

  // ===== TABLE NAMES =====
  static const String itemTable = "item_table";
  static const String categoryTable = "category_table";
  static const String batchTable = "batch_table";
  static const String userTable = "user_table";
  static const String authTable = "auth_table";
  static const String productTable = "product_table";

  // ===== BOX NAMES (for complex data structures) =====
  static const String preferencesBox = "preferences";
  static const String cacheBox = "cache";
  static const String syncBox = "sync_queue";

  // ===== HELPER METHODS =====

  /// Get all type IDs for validation
  static List<int> getAllTypeIds() {
    return [
      itemTypeId,
      categoryTypeId,
      batchTypeId,
      userTypeId,
      authTypeId,
      productTypeId,
    ];
  }

  /// Get all table names
  static List<String> getAllTableNames() {
    return [
      itemTable,
      categoryTable,
      batchTable,
      userTable,
      authTable,
      productTable,
    ];
  }
}
