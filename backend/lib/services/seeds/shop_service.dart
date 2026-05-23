import '../db/db_service.dart';

class ShopService {
  const ShopService(this.dbService);

  final DbService dbService;

  /// Buys a flower for the given user, handles specific seed logic deduction.
  Future<bool> buyFlower(String userId, String flowerId, int cost) async {
    // Check balance
    final seedModel = await dbService.getSeeds(userId);
    if (seedModel.seeds < cost) {
      return false; // Not enough seeds
    }

    // Deduct seeds
    final newBalance = seedModel.seeds - cost;
    await dbService.updateSeeds(userId, newBalance);
    
    return true; // Transaction successful
  }
  
  /// Fetches all active items from the shop catalog
  Future<List<Map<String, dynamic>>> getCatalog() async {
    final response = await dbService.supabase
        .from('shop_catalog')
        .select()
        .eq('is_active', true);
        
    return List<Map<String, dynamic>>.from(response);
  }
}
