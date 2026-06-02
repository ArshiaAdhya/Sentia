/// PLANT FLOWER API
/// Updates a previously purchased garden item with the user's tap coordinates.
library;

import 'dart:convert';
import 'dart:io';

import 'package:backend/services/seeds/garden_service.dart';
import 'package:backend/services/seeds/shop_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' show SupabaseClient;

Future<Response> onRequest(RequestContext context) async {
  try {
    final request = context.request;
    if (request.method != HttpMethod.post) {
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
    }

    final body = await request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final userId = data['user_id'] as String?;
    final flowerReference = data['flower_id'] as String?;
    final gardenItemId = data['garden_item_id']?.toString();
    final posX = (data['pos_x'] as num?)?.toDouble();
    final posY = (data['pos_y'] as num?)?.toDouble();

    if (userId == null ||
        posX == null ||
        posY == null ||
        ((flowerReference == null || flowerReference.trim().isEmpty) &&
            (gardenItemId == null || gardenItemId.isEmpty))) {
      return Response.json(
        statusCode: 400,
        body: {
          'error':
              'user_id, pos_x, pos_y, and flower_id or garden_item_id are required',
        },
      );
    }

    final supabaseClient = context.read<SupabaseClient>();
    final shopService = ShopService(supabaseClient);
    final gardenService = GardenService(supabaseClient);

    var canonicalFlowerId = flowerReference ?? '';
    String? displayName;
    String? assetUrl;
    if (flowerReference != null && flowerReference.trim().isNotEmpty) {
      final flower = await shopService.getFlowerById(flowerReference);
      if (flower == null) {
        return Response.json(
          statusCode: 404,
          body: {'error': 'Flower not found: $flowerReference'},
        );
      }
      canonicalFlowerId = flower.id;
      displayName = flower.displayName;
      assetUrl = flower.assetUrl;
    }

    stdout.writeln(
      '[PLANT] flower=$canonicalFlowerId x=$posX y=$posY user=$userId',
    );

    final plantedFlower = await gardenService.plantReservedFlower(
      userId: userId,
      itemId: canonicalFlowerId,
      posX: posX,
      posY: posY,
      gardenItemId: gardenItemId,
    );

    stdout.writeln(
      '[PLANT SAVED] itemId=${plantedFlower.id ?? plantedFlower.itemId}',
    );

    return Response.json(
      body: {
        'message': 'Flower planted successfully',
        'planted_flower': plantedFlower.toJson()
          ..['display_name'] = displayName
          ..['asset_url'] = assetUrl,
      },
    );
  } catch (e) {
    final message = e.toString();
    final statusCode = message.contains('No purchased flower') ? 400 : 500;
    return Response.json(
      statusCode: statusCode,
      body: {'error': message},
    );
  }
}
