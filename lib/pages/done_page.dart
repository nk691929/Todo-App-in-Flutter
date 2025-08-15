import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../widgets/task_tile.dart';

class DonePage extends StatelessWidget {
  const DonePage({super.key});

  @override
  Widget build(BuildContext context) {
    final doneTaskBox = Hive.box<TaskModel>('done_tasks');
    final taskBox = Hive.box<TaskModel>('tasks');

    return Scaffold(
      appBar: AppBar(title: const Text("Completed Tasks")),
      body: ValueListenableBuilder(
        valueListenable: doneTaskBox.listenable(),
        builder: (_, Box<TaskModel> box, __) {
          if (box.isEmpty) {
            return const Center(child: Text("No completed tasks yet"));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (_, index) {
              final task = box.getAt(index);

              if (task == null) return const SizedBox();

              return TaskTile(
                task: task,
                onToggle: () {
                  // Mark as not done & move back to active list
                  task.isDone = false;
                  taskBox.add(task);
                  doneTaskBox.deleteAt(index);
                },
                onDelete: () {
                  doneTaskBox.deleteAt(index);
                },
                onEdit: () {
                  // Optional: implement editing for completed tasks
                },
              );
            },
          );
        },
      ),
    );
  }
}
