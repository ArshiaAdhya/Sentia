import 'package:flutter/material.dart';

import '../services/api_service.dart';

class PlantedFlowerLocal {
  final String? id;
  final String itemId;
  final String? displayName;
  final String? assetUrl;
  final double posX;
  final double posY;
  final DateTime plantedAt;

  PlantedFlowerLocal({
    this.id,
    required this.itemId,
    this.displayName,
    this.assetUrl,
    required this.posX,
    required this.posY,
    required this.plantedAt,
  });

  factory PlantedFlowerLocal.fromJson(Map<String, dynamic> json) {
    return PlantedFlowerLocal(
      id: json['id']?.toString(),
      itemId: json['item_id'] as String,
      displayName: json['display_name']?.toString(),
      assetUrl: json['asset_url']?.toString(),
      posX: (json['pos_x'] as num).toDouble(),
      posY: (json['pos_y'] as num).toDouble(),
      plantedAt: DateTime.parse(json['planted_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'item_id': itemId,
        if (displayName != null) 'display_name': displayName,
        if (assetUrl != null) 'asset_url': assetUrl,
        'pos_x': posX,
        'pos_y': posY,
        'planted_at': plantedAt.toIso8601String(),
      };
}

class DiarySaveResult {
  const DiarySaveResult({
    required this.rewardAwarded,
    required this.earnedSeeds,
    required this.oldSeeds,
    required this.newSeeds,
  });

  factory DiarySaveResult.fromJson(Map<String, dynamic> json) {
    final reward = json['reward'] is Map<String, dynamic>
        ? json['reward'] as Map<String, dynamic>
        : <String, dynamic>{};

    return DiarySaveResult(
      rewardAwarded: reward['awarded'] == true,
      earnedSeeds: reward['earnedSeeds'] as int? ?? 0,
      oldSeeds: reward['oldSeeds'] as int? ?? 0,
      newSeeds: reward['newSeeds'] as int? ?? 0,
    );
  }

  final bool rewardAwarded;
  final int earnedSeeds;
  final int oldSeeds;
  final int newSeeds;
}

class GardenState extends ChangeNotifier {
  static final GardenState _instance = GardenState._internal();
  factory GardenState() => _instance;
  GardenState._internal();

  int _seeds = 0;
  int _streak = 0;
  int _joinedYear = 2026;
  String _username = '@Player';
  List<PlantedFlowerLocal> _plantedFlowers = [];
  List<DateTime> _journalDates = [];
  String? _selectedFlowerToPlant;
  String? _selectedGardenItemIdToPlant;
  String? _selectedFlowerDisplayName;

  int get seeds => _seeds;
  int get streak => _streak;
  int get joinedYear => _joinedYear;
  String get username => _username;
  List<PlantedFlowerLocal> get plantedFlowers => _plantedFlowers;
  List<DateTime> get journalDates => _journalDates;
  String? get selectedFlowerToPlant => _selectedFlowerToPlant;
  String? get selectedFlowerDisplayName =>
      _selectedFlowerDisplayName ?? _selectedFlowerToPlant;

  Future<void> refreshHomeData() async {
    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return;

    try {
      final homeData = await ApiService.get('/get_home_data?user_id=$userId');
      if (homeData['error'] != null) {
        throw Exception(homeData['error']);
      }

      _seeds = homeData['seeds'] as int? ?? _seeds;
      _streak = homeData['streak'] as int? ?? _streak;
      _joinedYear = homeData['joined_year'] as int? ?? _joinedYear;

      final username = homeData['username']?.toString();
      if (username != null && username.trim().isNotEmpty) {
        _username = username.startsWith('@') ? username : '@$username';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing home data: $e');
    }
  }

  Future<void> init() async {
    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return;

    try {
      await refreshHomeData();
      await refreshGardenData();
      await loadJournalDates();

      debugPrint(
        '[PERSISTENCE CHECK] user=$userId '
        'loadedSeeds=$_seeds '
        'loadedFlowers=${_plantedFlowers.length + (_selectedFlowerToPlant == null ? 0 : 1)} '
        'loadedEntries=${_journalDates.length}',
      );
    } catch (e) {
      debugPrint('Error loading backend state: $e');
    }

    notifyListeners();
  }

  Future<void> refreshGardenData() async {
    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return;

    try {
      final gardenData = await ApiService.get('/get_garden?user_id=$userId');
      if (gardenData['garden'] is List) {
        final gardenList = gardenData['garden'] as List;
        _plantedFlowers = gardenList
            .map(
              (item) => PlantedFlowerLocal.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      if (gardenData['pending_flowers'] is List) {
        final pendingList = gardenData['pending_flowers'] as List;
        if (pendingList.isNotEmpty) {
          final pending = PlantedFlowerLocal.fromJson(
            pendingList.first as Map<String, dynamic>,
          );
          _selectedFlowerToPlant = pending.itemId;
          _selectedGardenItemIdToPlant = pending.id;
          _selectedFlowerDisplayName = pending.displayName;
        } else if (_selectedGardenItemIdToPlant == null) {
          _selectedFlowerToPlant = null;
          _selectedFlowerDisplayName = null;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[GARDEN ERROR] route=/get_garden?user_id=$userId error=$e');
    }
  }

  Future<void> loadJournalDates() async {
    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return;

    try {
      final journalData =
          await ApiService.get('/profile/journal?userId=$userId');
      if (journalData['dates'] is List) {
        final dates = journalData['dates'] as List;
        _journalDates = dates
            .map((date) => _parseDateString(date.toString()))
            .whereType<DateTime>()
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        '[DIARY ERROR] route=/profile/journal?userId=$userId error=$e',
      );
    }
  }

  void selectFlowerToPlant(String? itemId) {
    _selectedFlowerToPlant = itemId;
    if (itemId == null) {
      _selectedGardenItemIdToPlant = null;
      _selectedFlowerDisplayName = null;
    }
    notifyListeners();
  }

  Future<bool> buyFlower(String itemId, int cost) async {
    if (_seeds < cost) return false;

    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return false;

    try {
      final res = await ApiService.post('/buy_flower', {
        'user_id': userId,
        'flower_id': itemId,
      });

      if (res['error'] != null) {
        throw Exception(res['error']);
      }

      if (res['remaining_seeds'] != null) {
        _seeds = res['remaining_seeds'] as int;
      }

      final pendingFlower = res['pending_flower'] is Map<String, dynamic>
          ? res['pending_flower'] as Map<String, dynamic>
          : null;
      _selectedFlowerToPlant =
          pendingFlower?['item_id']?.toString() ?? res['flower_id']?.toString();
      _selectedGardenItemIdToPlant = pendingFlower?['id']?.toString();
      _selectedFlowerDisplayName =
          pendingFlower?['display_name']?.toString() ?? itemId;

      notifyListeners();
      return _selectedFlowerToPlant != null;
    } catch (e) {
      debugPrint('[BUY FLOWER ERROR] flower=$itemId user=$userId error=$e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> plantQueuedFlower(double posX, double posY) async {
    if (_selectedFlowerToPlant == null) return false;

    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return false;

    final flowerId = _selectedFlowerToPlant!;
    final gardenItemId = _selectedGardenItemIdToPlant;

    debugPrint('[PLANT] flower=$flowerId x=$posX y=$posY user=$userId');

    try {
      final res = await ApiService.post('/plant_flower', {
        'user_id': userId,
        'flower_id': flowerId,
        if (gardenItemId != null) 'garden_item_id': gardenItemId,
        'pos_x': posX,
        'pos_y': posY,
      });

      if (res['error'] != null) {
        throw Exception(res['error']);
      }

      if (res['planted_flower'] != null) {
        final plantedFlower = PlantedFlowerLocal.fromJson(
          res['planted_flower'] as Map<String, dynamic>,
        );
        _upsertPlantedFlower(plantedFlower);
        _selectedFlowerToPlant = null;
        _selectedGardenItemIdToPlant = null;
        _selectedFlowerDisplayName = null;
        debugPrint('[PLANT SAVED] itemId=${plantedFlower.id ?? flowerId}');
        notifyListeners();
        return true;
      }
    } catch (e) {
      _selectedFlowerToPlant = flowerId;
      _selectedGardenItemIdToPlant = gardenItemId;
      debugPrint('Planting failed: $e');
      notifyListeners();
    }

    return false;
  }

  void syncProgress({int? seeds, int? streak}) {
    var changed = false;
    if (seeds != null && seeds != _seeds) {
      _seeds = seeds;
      changed = true;
    }
    if (streak != null && streak != _streak) {
      _streak = streak;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<String> getDiaryEntry(DateTime date) async {
    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return '';

    final route = '/profile/journal?userId=$userId&date=${_dateString(date)}';

    try {
      final journalData = await ApiService.get(route);

      if (journalData['journals'] is List) {
        final journals = journalData['journals'] as List;
        if (journals.isNotEmpty) {
          final journal = journals.first as Map<String, dynamic>;
          return journal['summary_text']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('[DIARY ERROR] route=$route error=$e');
    }

    return '';
  }

  Future<DiarySaveResult> addDiaryEntry(DateTime date, String content) async {
    final userId = await ApiService.getUserId();
    if (userId.isEmpty) {
      throw Exception('Session expired. Please login again.');
    }

    const route = '/profile/journal';

    try {
      final res = await ApiService.post(route, {
        'userId': userId,
        'text': content,
        'date': _dateString(date),
      });

      if (res['error'] != null) {
        throw Exception(res['error']);
      }

      final result = DiarySaveResult.fromJson(res);
      _rememberJournalDate(date);
      await refreshHomeData();
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('[DIARY ERROR] route=$route error=$e');
      rethrow;
    }
  }

  void resetState() {
    _seeds = 0;
    _streak = 0;
    _joinedYear = 2026;
    _username = '@Player';
    _plantedFlowers.clear();
    _journalDates.clear();
    _selectedFlowerToPlant = null;
    _selectedGardenItemIdToPlant = null;
    _selectedFlowerDisplayName = null;
    notifyListeners();
  }

  void _upsertPlantedFlower(PlantedFlowerLocal plantedFlower) {
    final existingIndex = _plantedFlowers.indexWhere(
      (flower) =>
          (plantedFlower.id != null && flower.id == plantedFlower.id) ||
          (plantedFlower.id == null &&
              flower.itemId == plantedFlower.itemId &&
              flower.plantedAt == plantedFlower.plantedAt),
    );

    if (existingIndex >= 0) {
      _plantedFlowers[existingIndex] = plantedFlower;
    } else {
      _plantedFlowers.add(plantedFlower);
    }
  }

  void _rememberJournalDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final alreadySaved = _journalDates.any(
      (saved) =>
          saved.year == normalized.year &&
          saved.month == normalized.month &&
          saved.day == normalized.day,
    );

    if (!alreadySaved) {
      _journalDates.add(normalized);
    }
  }

  DateTime? _parseDateString(String value) {
    try {
      final parts = value.split('-').map(int.parse).toList();
      if (parts.length != 3) return null;
      return DateTime(parts[0], parts[1], parts[2]);
    } catch (_) {
      return null;
    }
  }

  String _dateString(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
