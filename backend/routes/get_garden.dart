/// GARDEN API
/// Fetches planted flowers for user
/// Returns garden state
library;

import 'package:backend/models/garden_model.dart';
import 'package:backend/services/seeds/garden_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

Future<Map<String, Map<String, dynamic>>> _catalogById(
  SupabaseClient client,
) async {
  final response = await client
      .from('shop_catalog')
      .select('flower_id, display_name, asset_url');

  return {
    for (final row in response)
      row['flower_id'].toString(): Map<String, dynamic>.from(row),
  };
}

List<Map<String, dynamic>> _withCatalog(
  List<PlantedFlower> flowers,
  Map<String, Map<String, dynamic>> catalogById,
) {
  return flowers.map((flower) {
    final row = flower.toJson();
    final catalog = catalogById[flower.itemId];
    if (catalog != null) {
      row['display_name'] = catalog['display_name'];
      row['asset_url'] = catalog['asset_url'];
    }
    return row;
  }).toList();
}

Future<Response> onRequest(RequestContext context) async {
  try {
    final supabaseClient = context.read<SupabaseClient>();

    final request = context.request;

    if (request.method != HttpMethod.get) {
      return Response.json(
        statusCode: 405,
        body: {
          'error': 'Method not allowed',
        },
      );
    }

    final userId = request.uri.queryParameters['user_id'];

    if (userId == null || userId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'user_id is required',
        },
      );
    }

    final gardenService = GardenService(supabaseClient);
    final catalog = await _catalogById(supabaseClient);
    final gardenItems = await gardenService.getUserGarden(userId);
    final pendingFlowers = await gardenService.getPendingFlowers(userId);

    return Response.json(
      body: {
        'garden': _withCatalog(gardenItems, catalog),
        'pending_flowers': _withCatalog(pendingFlowers, catalog),
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'error': e.toString(),
      },
    );
  }
}
