import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscriber.dart';

class HiveHelper {
  static const String boxName = 'subscribers';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SubscriberAdapter());
    await Hive.openBox<Subscriber>(boxName);
  }

  static Future<List<Subscriber>> getSubscribers() async {
    final box = Hive.box<Subscriber>(boxName);
    return box.values.toList();
  }

  static Future<void> insertSubscriber(Subscriber sub) async {
    final box = Hive.box<Subscriber>(boxName);
    await box.add(sub);
  }

  static Future<void> updateSubscriber(Subscriber sub) async {
    await sub.save();
  }

  static Future<void> deleteSubscriber(String name) async {
    final box = Hive.box<Subscriber>(boxName);
    final sub = box.values.firstWhere((s) => s.name == name,
        orElse: () => throw Exception("Subscriber not found"));
    await sub.delete();
  }
}
