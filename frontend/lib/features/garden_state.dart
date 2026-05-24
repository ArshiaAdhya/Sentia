import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlantedFlowerLocal {
  final String itemId;
  final double posX;
  final double posY;
  final DateTime plantedAt;

  PlantedFlowerLocal({
    required this.itemId,
    required this.posX,
    required this.posY,
    required this.plantedAt,
  });

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'pos_x': posX,
        'pos_y': posY,
        'planted_at': plantedAt.toIso8601String(),
      };

  factory PlantedFlowerLocal.fromJson(Map<String, dynamic> json) {
    return PlantedFlowerLocal(
      itemId: json['item_id'] as String,
      posX: (json['pos_x'] as num).toDouble(),
      posY: (json['pos_y'] as num).toDouble(),
      plantedAt: DateTime.parse(json['planted_at'] as String),
    );
  }
}

class GardenState extends ChangeNotifier {
  static final GardenState _instance = GardenState._internal();
  factory GardenState() => _instance;
  GardenState._internal();

  int _seeds = 50;
  int _streak = 3;
  int _points = 50; // Mocked local points for now
  String _username = '@Player';
  List<PlantedFlowerLocal> _plantedFlowers = [];
  List<DateTime> _journalDates = [];
  String? _selectedFlowerToPlant; 

  int get seeds => _seeds;
  int get streak => _streak;
  int get points => _points;
  String get username => _username;
  List<PlantedFlowerLocal> get plantedFlowers => _plantedFlowers;
  List<DateTime> get journalDates => _journalDates;
  String? get selectedFlowerToPlant => _selectedFlowerToPlant;

  Future<void> init() async {
    final userId = await ApiService.getUserId();
    if (userId.isEmpty) return;
    
    try {
      // 1. Get Home Data
      final homeData = await ApiService.get('/get_home_data?user_id=$userId');
      if (homeData.isNotEmpty) {
         _seeds = homeData['seeds'] as int? ?? 0;
         _streak = homeData['streak'] as int? ?? 0;
      }
      
      // 2. Get Garden 
      final gardenData = await ApiService.get('/get_garden?user_id=$userId');
      if (gardenData['garden'] != null) {
        final List<dynamic> gardenList = gardenData['garden'];
        _plantedFlowers = gardenList
            .map((item) => PlantedFlowerLocal.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // 3. Get Journals
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final journalData = await ApiService.get('/profile/journal?userId=$userId&date=$dateStr');
      if (journalData['journals'] != null) {
        final List<dynamic> jList = journalData['journals'];
        if (jList.isNotEmpty && !_journalDates.any((d) => d.year == now.year && d.month == now.month && d.day == now.day)) {
          _journalDates.add(now);
        }
      }
    } catch (e) {
      debugPrint('Error loading backend state: $e');
    }
    notifyListeners();
  }

  void selectFlowerToPlant(String? itemId) {
    _selectedFlowerToPlant = itemId;
    notifyListeners();
  }

  Future<bool> buyFlower(String itemId, int cost) async {
    if (_seeds >= cost) {
      _seeds -= cost;
      _selectedFlowerToPlant = itemId; 
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> plantQueuedFlower(double posX, double posY) async {
    if (_selectedFlowerToPlant != null) {
      final userId = await ApiService.getUserId();
      final flowerId = _selectedFlowerToPlant!;
      _selectedFlowerToPlant = null;

      try {
        final res = await ApiService.post('/buy_flower', {
          'user_id': userId,
          'flower_id': flowerId,
          'pos_x': posX,
          'pos_y': posY,
        });

        if (res['planted_flower'] != null) {
          _plantedFlowers.add(PlantedFlowerLocal.fromJson(res['planted_flower']));
          if (res['remaining_seeds'] != null) {
             _seeds = res['remaining_seeds'] as int;
          }
          _points += 10;
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Planting failed: $e');
      }
    }
  }

  Future<void> addDiaryEntry(String content) async {
    final now = DateTime.now();
    bool alreadyJournaledToday = _journalDates.any((date) => 
        date.year == now.year && date.month == now.month && date.day == now.day);

    try {
      final userId = await ApiService.getUserId();
      await ApiService.post('/profile/journal', {
        'userId': userId,
        'text': content,
      });

      if (!alreadyJournaledToday) {
        _journalDates.add(now);
        _seeds += 20; 
        _points += 15; 
        _streak += 1;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Journal push failed: $e');
    }
  }

  void resetState() {
    _seeds = 50;
    _streak = 3;
    _points = 50;
    _plantedFlowers.clear();
    _journalDates.clear();
    _selectedFlowerToPlant = null;
    notifyListeners();
  }
}

