/// BUY FLOWER API
/// Handles:
/// - checking if user has enough seeds
/// - deducting seeds
/// - saving the purchased flower as a pending garden item
library;

import 'dart:convert';
import 'dart:io';

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
    if (userId == null || flowerId == null) {
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
    final purchase = await shopService.purchaseFlower(
      userId: userId,
      flowerId: flowerId,
    );
    final canonicalFlowerId = purchase.flower.id;

    // Save the purchase immediately so it survives restart/logout before tap.
    final pendingFlower = await gardenService.reserveFlower(
      userId: userId,
      itemId: canonicalFlowerId,
    );
    final pendingFlowerJson = pendingFlower.toJson()
      ..['display_name'] = purchase.flower.displayName
      ..['asset_url'] = purchase.flower.assetUrl;

    Map<String, dynamic>? plantedFlowerJson;
    if (posX != null && posY != null) {
      stdout.writeln(
        '[PLANT] flower=$canonicalFlowerId x=$posX y=$posY user=$userId',
      );
      final plantedFlower = await gardenService.plantReservedFlower(
        userId: userId,
        itemId: canonicalFlowerId,
        posX: posX,
        posY: posY,
        gardenItemId: pendingFlower.id,
      );
      stdout.writeln(
        '[PLANT SAVED] itemId=${plantedFlower.id ?? plantedFlower.itemId}',
      );
      plantedFlowerJson = plantedFlower.toJson()
        ..['display_name'] = purchase.flower.displayName
        ..['asset_url'] = purchase.flower.assetUrl;
    }

    // Success response
    return Response.json(
      body: {
        'message': 'Flower purchased successfully',
        'remaining_seeds': purchase.remainingSeeds,
        'flower_id': canonicalFlowerId,
        'pending_flower': pendingFlowerJson,
        if (plantedFlowerJson != null) 'planted_flower': plantedFlowerJson,
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
