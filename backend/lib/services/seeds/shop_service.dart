/// SHOP SERVICE
/// Handles:
/// - buying flowers
/// - checking seed balance
/// - deducting seeds
///
/// getCatalogForUser() — returns all active flowers with a canBuy flag per user
/// purchaseFlower()    — validates balance and deducts seeds directly in the DB
///
/// Queries shop_catalog and users tables directly via SupabaseClient.
library;

import 'package:supabase/supabase.dart';
import 'package:backend/models/flower_model.dart';
import 'package:backend/models/user_model.dart';

class ShopService {

  ShopService(this._client);
  final SupabaseClient _client;

  // ── DB helpers ──────────────────────────────────────────────────────────

  Future<AppUser?> _getUser(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return AppUser.fromJson(response);
  }

  Future<List<Flower>> _getActiveFlowers() async {
    final response = await _client
        .from('shop_catalog')
        .select()
        .eq('is_active', true);

    return response.map(Flower.fromJson).toList();
  }

  Future<Flower?> _getFlowerById(String flowerId) async {
    final response = await _client
        .from('shop_catalog')
        .select()
        .eq('flower_id', flowerId)
        .maybeSingle();

    if (response == null) return null;
    return Flower.fromJson(response);
  }

  Future<AppUser> _deductSeeds(String userId, int amount) async {
    final current = await _getUser(userId);
    if (current == null) throw Exception('User not found: $userId');
    if (current.seeds < amount) {
      throw Exception('Insufficient seeds: has ${current.seeds}, needs $amount');
    }

    final response = await _client
        .from('users')
        .update({'seeds': current.seeds - amount})
        .eq('id', userId)
        .select()
        .single();

    return AppUser.fromJson(response);
  }

  // ── Business logic ───────────────────────────────────────────────────────

  Future<List<Flower>> getCatalog() => _getActiveFlowers();

  // Returns all active flowers. If the user has enough seeds for a flower,
  // canBuy is true. The frontend uses this to enable/disable the Buy button.
  Future<List<Map<String, dynamic>>> getCatalogForUser(String userId) async {
    final user = await _getUser(userId);
    final userSeeds = user?.seeds ?? 0;
    final flowers = await _getActiveFlowers();

    return flowers.map((flower) => {
          ...flower.toJson(),
          'canBuy': userSeeds >= flower.seedCost,
          'userSeeds': userSeeds,
        },).toList();
  }

  Future<Flower?> getFlowerById(String flowerId) => _getFlowerById(flowerId);

  // Deducts seeds from the user. Throws if flower not found or seeds insufficient.
  Future<int> purchaseFlower({
    required String userId,
    required String flowerId,
  }) async {
    final flower = await _getFlowerById(flowerId);
    if (flower == null) throw Exception('Flower not found: $flowerId');
    if (!flower.isActive) throw Exception('Flower is not available: $flowerId');

    final updated = await _deductSeeds(userId, flower.seedCost);
    return updated.seeds;
  }
}