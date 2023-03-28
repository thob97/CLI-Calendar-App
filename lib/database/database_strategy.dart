import 'dart:io';

import 'package:cli_calendar_app/database/model/config.dart';
import 'package:cli_calendar_app/model/todo.dart';

abstract class DatabaseStrategy {
  Future<DatabaseStrategy?> init({
    required String token,
    required String repoName,
    required String dbConfigPath,
  });

  Future<bool> autoSetup();

  Future<String?> login(String token);

  Future<bool> setRepo({required String repoName});

  Future<bool> setConfig({required String dbConfigPath});

  Future<File?> fetchCalendarFile();

  Future<List<Todo>?> getNumOpenIssues(int num);

  Future<int?> uploadIssue({required Todo todo});

  Future<bool> solveIssue({required int issueNumber});

  bool isInitialized();

  Config getConfig();

  int? getRemainingRateLimit();

  DateTime? getResetOfRateLimit();
}
