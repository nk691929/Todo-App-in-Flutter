import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box<TaskModel> taskBox = Hive.box<TaskModel>('tasks');

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  DateTime? selectedDate;

  TaskModel? _recentlyDeletedTask;
  int? _recentlyDeletedIndex;

  void _showTaskDialog({TaskModel? task, int? index}) {
    if (task != null) {
      titleController.text = task.title;
      descController.text = task.description ?? '';
      selectedDate = task.date;
    } else {
      titleController.clear();
      descController.clear();
      selectedDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(task == null ? 'Add Task' : 'Edit Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    selectedDate == null
                        ? 'No date chosen'
                        : _formatDate(selectedDate!),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today,
                        color: Colors.deepPurple),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: () {
                if (titleController.text.trim().isEmpty || selectedDate == null)
                  return;

                if (task == null) {
                  taskBox.add(TaskModel(
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    date: selectedDate!,
                  ));
                } else {
                  task.title = titleController.text.trim();
                  task.description = descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim();
                  task.date = selectedDate!;
                  task.save();
                }

                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate() async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _toggleTask(int index) {
    final task = taskBox.getAt(index);
    if (task != null) {
      task.isDone = !task.isDone;
      task.save();
    }
  }

  void _deleteTask(int index) {
  final key = taskBox.keyAt(index);
  _recentlyDeletedTask = taskBox.getAt(index);
  _recentlyDeletedIndex = index;

  taskBox.deleteAt(index);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Task deleted'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          if (_recentlyDeletedTask != null) {
            if (key is int) {
              taskBox.put(key, _recentlyDeletedTask!);
            } else {
              taskBox.add(_recentlyDeletedTask!);
            }
          }
        },
      ),
    ),
  );
}

Map<String, List<TaskModel>> _groupTasksByDate(List<TaskModel> tasks) {
  Map<String, List<TaskModel>> groupedTasks = {};

  // Sort while handling null dates safely
  tasks.sort((a, b) {
    if (a.date == null && b.date == null) return 0;
    if (a.date == null) return 1; // put null dates at bottom
    if (b.date == null) return -1;
    return a.date!.compareTo(b.date!);
  });

  for (var task in tasks) {
    if (task.date == null) {
      groupedTasks.putIfAbsent("No Date", () => []).add(task);
      continue;
    }

    String dateLabel;
    DateTime today = DateTime.now();
    DateTime taskDate = DateTime(task.date!.year, task.date!.month, task.date!.day);

    if (taskDate == DateTime(today.year, today.month, today.day)) {
      dateLabel = "Today";
    } else if (taskDate ==
        DateTime(today.year, today.month, today.day + 1)) {
      dateLabel = "Tomorrow";
    } else {
      dateLabel = _formatDate(task.date!);
    }

    groupedTasks.putIfAbsent(dateLabel, () => []).add(task);
  }
  return groupedTasks;
}

  String _formatDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return "${date.day} ${months[date.month]} ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'To-Do App',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<TaskModel> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No tasks yet! Add one.'),
            );
          }

          final grouped = _groupTasksByDate(box.values.toList());

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  ...entry.value.map((task) {
                    final index = box.values.toList().indexOf(task);
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: TaskTile(
                        task: task,
                        onToggle: () => _toggleTask(index),
                        onDelete: () => _deleteTask(index),
                        onEdit: () => _showTaskDialog(task: task, index: index),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _showTaskDialog(),
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
}
