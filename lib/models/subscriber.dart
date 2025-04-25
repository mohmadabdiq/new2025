import 'package:hive/hive.dart';

part 'subscriber.g.dart';

@HiveType(typeId: 0)
class Subscriber extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  DateTime endDate;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String status;

  @HiveField(4)
  String notes;

  Subscriber({
    required this.name,
    required this.endDate,
    required this.amount,
    required this.status,
    required this.notes,
  });

  int get remainingDays => endDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'endDate': endDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'notes': notes,
    };
  }

  factory Subscriber.fromJson(Map<String, dynamic> json) => Subscriber(
        name: json['name'],
        endDate: DateTime.parse(json['endDate']),
        amount: json['amount'],
        status: json['status'],
        notes: json['notes'],
      );
}
