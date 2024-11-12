// lib/models/task.dart
// models/task.dart
// task.dart

class Task {
  String id;
  String name;
  String urgency;
  bool isCompleted;
  List<SubTask> subTasks;

  // Default constructor
  Task({
    required this.id,
    required this.name,
    required this.urgency,
    required this.isCompleted,
    required this.subTasks,
  });

  // fromMap constructor to initialize a Task object from Firestore data
  Task.fromMap(Map<String, dynamic> data, String id)
      : id = id,
        name = data['name'] ?? 'Unnamed Task',
        urgency = data['urgency'] ?? 'Low',
        isCompleted = data['isCompleted'] ?? false,
        subTasks = (data['subTasks'] as List<dynamic>?)
                ?.map((item) => SubTask.fromMap(item as Map<String, dynamic>))
                .toList() ??
            [];

  // Convert a Task object to a map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'urgency': urgency,
      'isCompleted': isCompleted,
      'subTasks': subTasks.map((subTask) => subTask.toMap()).toList(),
    };
  }
}

class SubTask {
  String name;
  String timeSlot;
  bool isCompleted;

  SubTask({
    required this.name,
    required this.timeSlot,
    required this.isCompleted,
  });

  // fromMap constructor for SubTask
  SubTask.fromMap(Map<String, dynamic> data)
      : name = data['name'] ?? 'Unnamed Subtask',
        timeSlot = data['timeSlot'] ?? 'No time slot',
        isCompleted = data['isCompleted'] ?? false;

  // Convert a SubTask object to a map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'timeSlot': timeSlot,
      'isCompleted': isCompleted,
    };
  }
}
