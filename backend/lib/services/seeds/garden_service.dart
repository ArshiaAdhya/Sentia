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

const _pendingFlowerPosition = -1.0;

class GardenService {
  GardenService(this._client);
  final SupabaseClient _client;

  // ── DB helpers ──────────────────────────────────────────────────────────

  Future<List<PlantedFlower>> _fetchGarden(String userId) async {
    final response = await _client
        .from('user_garden_items')
        .select()
        .eq('user_id', userId)
        .gte('pos_x', 0)
        .gte('pos_y', 0)
        .order('planted_at', ascending: false);

    return response.map(PlantedFlower.fromJson).toList();
  }

  Future<List<PlantedFlower>> _fetchPendingFlowers(String userId) async {
    final response = await _client
        .from('user_garden_items')
        .select()
        .eq('user_id', userId)
        .lt('pos_x', 0)
        .lt('pos_y', 0)
        .order('planted_at', ascending: true);

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

  Future<PlantedFlower?> _findPendingFlower({
    required String userId,
    required String itemId,
  }) async {
    final response = await _client
        .from('user_garden_items')
        .select()
        .eq('user_id', userId)
        .eq('item_id', itemId)
        .lt('pos_x', 0)
        .lt('pos_y', 0)
        .order('planted_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return PlantedFlower.fromJson(response);
  }

  Future<PlantedFlower> _updateFlowerPosition({
    required String userId,
    required String gardenItemId,
    required double posX,
    required double posY,
  }) async {
    final response = await _client
        .from('user_garden_items')
        .update({
          'pos_x': posX,
          'pos_y': posY,
          'planted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', gardenItemId)
        .eq('user_id', userId)
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
  }) async {
    final pending = await _findPendingFlower(userId: userId, itemId: itemId);
    if (pending?.id != null) {
      return _updateFlowerPosition(
        userId: userId,
        gardenItemId: pending!.id!,
        posX: posX,
        posY: posY,
      );
    }

    return _insertFlower(
      userId: userId,
      itemId: itemId,
      posX: posX,
      posY: posY,
    );
  }

  Future<PlantedFlower> reserveFlower({
    required String userId,
    required String itemId,
  }) {
    return _insertFlower(
      userId: userId,
      itemId: itemId,
      posX: _pendingFlowerPosition,
      posY: _pendingFlowerPosition,
    );
  }

  Future<PlantedFlower> plantReservedFlower({
    required String userId,
    required String itemId,
    required double posX,
    required double posY,
    String? gardenItemId,
  }) async {
    final resolvedGardenItemId = gardenItemId ??
        (await _findPendingFlower(userId: userId, itemId: itemId))?.id;

    if (resolvedGardenItemId == null) {
      throw Exception('No purchased flower is waiting to be planted.');
    }

    return _updateFlowerPosition(
      userId: userId,
      gardenItemId: resolvedGardenItemId,
      posX: posX,
      posY: posY,
    );
  }

  Future<List<PlantedFlower>> getUserGarden(String userId) {
    return _fetchGarden(userId);
  }

  Future<List<PlantedFlower>> getPendingFlowers(String userId) {
    return _fetchPendingFlowers(userId);
  }
}
