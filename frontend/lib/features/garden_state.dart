import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _points = 50;
  String _username = '@Saloni';
  List<PlantedFlowerLocal> _plantedFlowers = [];
  List<DateTime> _journalDates = [];
  String? _selectedFlowerToPlant; // Flower waiting to be planted on next tap

  // Getters
  int get seeds => _seeds;
  int get streak => _streak;
  int get points => _points;
  String get username => _username;
  List<PlantedFlowerLocal> get plantedFlowers => _plantedFlowers;
  List<DateTime> get journalDates => _journalDates;
  String? get selectedFlowerToPlant => _selectedFlowerToPlant;

  // Initialize and load from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _seeds = prefs.getInt('sentia_seeds') ?? 50;
      _streak = prefs.getInt('sentia_streak') ?? 3;
      _points = prefs.getInt('sentia_points') ?? 50;
      _username = prefs.getString('sentia_username') ?? '@Saloni';

      // Load planted flowers
      final flowersJson = prefs.getString('sentia_planted_flowers');
      if (flowersJson != null) {
        final List<dynamic> decoded = jsonDecode(flowersJson);
        _plantedFlowers = decoded
            .map((item) => PlantedFlowerLocal.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      // Load journal entries
      final journalJson = prefs.getStringList('sentia_journal_dates');
      if (journalJson != null) {
        _journalDates = journalJson.map((d) => DateTime.parse(d)).toList();
      }
    } catch (e) {
      debugPrint('Error loading local state: $e');
    }
    notifyListeners();
  }

  // Save methods
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('sentia_seeds', _seeds);
      await prefs.setInt('sentia_streak', _streak);
      await prefs.setInt('sentia_points', _points);
      await prefs.setString('sentia_username', _username);

      final flowersJson = jsonEncode(_plantedFlowers.map((f) => f.toJson()).toList());
      await prefs.setString('sentia_planted_flowers', flowersJson);

      final journalStrings = _journalDates.map((d) => d.toIso8601String()).toList();
      await prefs.setStringList('sentia_journal_dates', journalStrings);
    } catch (e) {
      debugPrint('Error saving local state: $e');
    }
  }

  // Set selected flower to plant
  void selectFlowerToPlant(String? itemId) {
    _selectedFlowerToPlant = itemId;
    notifyListeners();
  }

  // Buy a flower from the shop
  bool buyFlower(String itemId, int cost) {
    if (_seeds >= cost) {
      _seeds -= cost;
      _selectedFlowerToPlant = itemId; // Queue it for planting
      _saveState();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Plant the queued flower at coordinates
  void plantQueuedFlower(double posX, double posY) {
    if (_selectedFlowerToPlant != null) {
      _plantedFlowers.add(PlantedFlowerLocal(
        itemId: _selectedFlowerToPlant!,
        posX: posX,
        posY: posY,
        plantedAt: DateTime.now(),
      ));
      _selectedFlowerToPlant = null;
      _points += 10; // Plant rewards points!
      _saveState();
      notifyListeners();
    }
  }

  // Complete a diary entry
  void addDiaryEntry(String content) {
    final now = DateTime.now();
    
    // Check if there is already an entry for today to avoid multiple streak bumps
    bool alreadyJournaledToday = false;
    for (var date in _journalDates) {
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        alreadyJournaledToday = true;
        break;
      }
    }

    _journalDates.add(now);
    _seeds += 20; // Journal reward
    _points += 15; // Journal points
    
    if (!alreadyJournaledToday) {
      _streak += 1;
    }

    _saveState();
    notifyListeners();
  }

  // Reset garden helper
  void resetState() {
    _seeds = 50;
    _streak = 3;
    _points = 50;
    _plantedFlowers.clear();
    _journalDates.clear();
    _selectedFlowerToPlant = null;
    _saveState();
    notifyListeners();
  }
}
