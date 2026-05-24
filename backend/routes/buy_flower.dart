/// BUY FLOWER API
/// Handles:
/// - checking if user has enough seeds
/// - deducting seeds
/// - adding flower to garden
library;

import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import 'package:supabase/supabase.dart' show SupabaseClient;
import 'package:backend/services/seeds/garden_service.dart';
import 'package:backend/services/seeds/shop_service.dart';


Future<Response> onRequest(RequestContext context) async {
  try {
    final supabaseClient = context.read<SupabaseClient>();
    final request = context.request;

    // Only allow POST requests
    if (request.method != HttpMethod.post) {
      return Response.json(
        statusCode: 405,
        body: {
          'error': 'Method not allowed',
        },
      );
    }

    // Parse request body
    final body = await request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['user_id'] as String?;
    final flowerId = data['flower_id'] as String?;
    final posX = (data['pos_x'] as num?)?.toDouble();
    final posY = (data['pos_y'] as num?)?.toDouble();

    // Validation
    if (userId == null ||
        flowerId == null ||
        posX == null ||
        posY == null) {
      return Response.json(
        statusCode: 400,
        body: {
          'error': 'Missing required fields',
        },
      );
    }

    // Initialize services
    final shopService = ShopService(supabaseClient);
    final gardenService = GardenService(supabaseClient);

    // Deduct seeds from user
    final remainingSeeds = await shopService.purchaseFlower(
      userId: userId,
      flowerId: flowerId,
    );

    // Add flower to garden
    final plantedFlower = await gardenService.plantFlower(
      userId: userId,
      itemId: flowerId,
      posX: posX,
      posY: posY,
    );

    // Success response
    return Response.json(
      body: {
        'message': 'Flower purchased successfully',
        'remaining_seeds': remainingSeeds,
        'planted_flower': plantedFlower.toJson(),
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