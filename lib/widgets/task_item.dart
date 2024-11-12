import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final Function(Task) onToggleCompletion;
  final Function(Task) onDelete;
  final Function(Task, SubTask) onToggleSubTaskCompletion; // For toggling subtask completion

  TaskItem({
    required this.task,
    required this.onToggleCompletion,
    required this.onDelete,
    required this.onToggleSubTaskCompletion,
  });

  @override
  _TaskItemState createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ExpansionTile(
        title: Text(
          widget.task.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            decoration: widget.task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        leading: Checkbox(
          value: widget.task.isCompleted,
          onChanged: (_) => widget.onToggleCompletion(widget.task),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => widget.onDelete(widget.task),
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          ...widget.task.subTasks.map((subTask) => ListTile(
                title: Text(
                  '${subTask.timeSlot}: ${subTask.name}',
                  style: TextStyle(
                    decoration: subTask.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                leading: Checkbox(
                  value: subTask.isCompleted,
                  onChanged: (_) => widget.onToggleSubTaskCompletion(widget.task, subTask),
                ),
              )),
        ],
      ),
    );
  }
}
