import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _subTaskController = TextEditingController();
  final TextEditingController _timeSlotController = TextEditingController();
  String _selectedUrgency = "Low";

  @override
  void initState() {
    super.initState();
    checkUserAuthentication();
  }

  // Method to check if the user is authenticated
  void checkUserAuthentication() {
    final user = _auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }
  }

  // Method to get the color based on urgency level
  Color getUrgencyColor(String urgency) {
    switch (urgency) {
      case "High":
        return Colors.redAccent;
      case "Medium":
        return Colors.orangeAccent;
      case "Low":
        return Colors.greenAccent;
      default:
        return Colors.blueGrey;
    }
  }

  // Method to add a new task
  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty) {
      await _firestore.collection('tasks').add({
        'name': _taskController.text,
        'urgency': _selectedUrgency,
        'isCompleted': false,
        'subTasks': [],
      });
      _taskController.clear();
    }
  }

  // Method to add a new sub-task
  Future<void> _addSubTask(Task task) async {
    if (_subTaskController.text.isNotEmpty && _timeSlotController.text.isNotEmpty) {
      final subTask = SubTask(
        name: _subTaskController.text,
        timeSlot: _timeSlotController.text,
        isCompleted: false,
      );

      await _firestore.collection('tasks').doc(task.id).update({
        'subTasks': FieldValue.arrayUnion([subTask.toMap()]),
      });
      _subTaskController.clear();
      _timeSlotController.clear();
    }
  }

  // Method to toggle task completion
  Future<void> _toggleCompletion(Task task) async {
    await _firestore.collection('tasks').doc(task.id).update({
      'isCompleted': !task.isCompleted,
    });
  }

  // Method to toggle sub-task completion
  Future<void> _toggleSubTaskCompletion(Task task, SubTask subTask) async {
    final updatedSubTasks = task.subTasks.map((st) {
      if (st.name == subTask.name && st.timeSlot == subTask.timeSlot) {
        return SubTask(
          name: st.name,
          timeSlot: st.timeSlot,
          isCompleted: !st.isCompleted,
        );
      }
      return st;
    }).toList();

    await _firestore.collection('tasks').doc(task.id).update({
      'subTasks': updatedSubTasks.map((st) => st.toMap()).toList(),
    });
  }

  // Method to delete a task
  Future<void> _deleteTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).delete();
  }

  // Dialog to add a new task
  void _showAddTaskDialog() {
    _selectedUrgency = "Low"; // Reset urgency to default each time dialog is shown
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Task", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField(
              value: _selectedUrgency,
              items: ["High", "Medium", "Low"]
                  .map((urgency) => DropdownMenuItem(
                        value: urgency,
                        child: Text(urgency),
                      ))
                  .toList(),
              onChanged: (value) {
                _selectedUrgency = value as String;
              },
              decoration: InputDecoration(
                labelText: 'Urgency Level',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text("Add Task"),
            onPressed: () {
              _addTask();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: getUrgencyColor(_selectedUrgency),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("Your Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.collection('tasks').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading tasks.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No tasks available.'));
          }

          final tasks = snapshot.data!.docs.map((doc) {
            return Task.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: getUrgencyColor(task.urgency).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    task.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => _toggleCompletion(task),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteTask(task),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: task.subTasks.map((subTask) {
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            title: Text(
                              '${subTask.timeSlot}: ${subTask.name}',
                              style: TextStyle(
                                decoration: subTask.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            leading: Checkbox(
                              value: subTask.isCompleted,
                              onChanged: (_) =>
                                  _toggleSubTaskCompletion(task, subTask),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _subTaskController,
                            decoration: InputDecoration(
                              labelText: 'Sub-task name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _timeSlotController,
                            decoration: InputDecoration(
                              labelText: 'Time Slot (e.g., 9 am - 10 am)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _addSubTask(task),
                            child: Text("Add Sub-task"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: getUrgencyColor(task.urgency),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add),
      ),
    );
  }
}
