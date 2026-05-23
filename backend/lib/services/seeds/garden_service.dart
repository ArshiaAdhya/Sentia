import '../db/db_service.dart';
import '../../models/garden_model.dart';

class GardenService {
  const GardenService(this.dbService);
  
  final DbService dbService;

  /// Fetches all items in a user's garden
  Future<List<GardenModel>> getGarden(String userId) async {
    return dbService.fetchGarden(userId);
  }

  /// Plants a new flower in the garden
  Future<void> plantFlower(GardenModel item) async {
    await dbService.saveGardenItem(item);
  }
}
