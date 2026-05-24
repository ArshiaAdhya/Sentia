/// GARDEN SERVICE
/// Manages:
/// - storing planted flowers
/// - fetching garden data
///
/// Thin layer over GardenRepository.
/// plantFlower()   — saves a new flower with its (posX, posY) coordinates to the DB
/// getUserGarden() — retrieves all flowers the user has planted so far
///
/// Queries user_garden_items table directly via SupabaseClient.
library;

import 'package:supabase/supabase.dart';
import 'package:backend/models/garden_model.dart';

class GardenService {

  GardenService(this._client);
  final SupabaseClient _client;

  // ── DB helpers ──────────────────────────────────────────────────────────

  Future<List<PlantedFlower>> _fetchGarden(String userId) async {
    final response = await _client
        .from('user_garden_items')
        .select()
        .eq('user_id', userId)
        .order('planted_at', ascending: false);

    return response.map(PlantedFlower.fromJson).toList();
  }

  Future<PlantedFlower> _insertFlower({
    required String userId,
    required String itemId,
    required double posX,
    required double posY,
  }) async {
    final now = DateTime.now().toUtc();

    final response = await _client
        .from('user_garden_items')
        .insert({
          'user_id': userId,
          'item_id': itemId,
          'pos_x': posX,
          'pos_y': posY,
          'planted_at': now.toIso8601String(),
        })
        .select()
        .single();

    return PlantedFlower.fromJson(response);
  }

  // ── Business logic ───────────────────────────────────────────────────────

  Future<PlantedFlower> plantFlower({
    required String userId,
    required String itemId,
    required double posX,
    required double posY,
  }) {
    return _insertFlower(
      userId: userId,
      itemId: itemId,
      posX: posX,
      posY: posY,
    );
  }

  Future<List<PlantedFlower>> getUserGarden(String userId) {
    return _fetchGarden(userId);
  }
}