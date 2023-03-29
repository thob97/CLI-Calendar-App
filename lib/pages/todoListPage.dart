import 'package:cli_calendar_app/services/database/database_strategy.dart';
import 'package:flutter/material.dart';

class TodoListPage extends StatelessWidget {
  const TodoListPage({super.key, required this.database});

  final DatabaseStrategy database;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Todolist'),
    );
  }
}
