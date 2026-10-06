import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedTrain {
  const SavedTrain(this.number, this.name);

  final String number;
  final String name;
}

/// Trains the user bookmarked, kept on the phone between launches.
class SavedTrainsStore extends ChangeNotifier {
  SavedTrainsStore._();

  static final SavedTrainsStore instance = SavedTrainsStore._();

  static const String _key = 'saved_trains';

  final List<SavedTrain> _items = <SavedTrain>[];

  List<SavedTrain> get items => List<SavedTrain>.unmodifiable(_items);

  bool isSaved(String number) =>
      _items.any((SavedTrain t) => t.number == number);

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> raw =
          prefs.getStringList(_key) ?? const <String>[];
      _items.clear();
      for (final String entry in raw) {
        final int split = entry.indexOf('|');
        if (split > 0) {
          _items.add(SavedTrain(
            entry.substring(0, split),
            entry.substring(split + 1),
          ));
        }
      }
      notifyListeners();
    } catch (_) {
      // Saved trains are a convenience. The app still works without them.
    }
  }

  Future<void> toggle(String number, String name) async {
    if (isSaved(number)) {
      _items.removeWhere((SavedTrain t) => t.number == number);
    } else {
      _items.insert(0, SavedTrain(number, name));
    }
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _key,
        _items.map((SavedTrain t) => '${t.number}|${t.name}').toList(),
      );
    } catch (_) {
      // Keep the in-memory list even if saving to disk fails.
    }
  }
}
