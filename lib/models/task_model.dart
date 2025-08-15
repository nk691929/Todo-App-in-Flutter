import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? description;

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  DateTime? date; // new field

  TaskModel({
    required this.title,
    this.description,
    this.isDone = false,
    required this.date,
  });
}
