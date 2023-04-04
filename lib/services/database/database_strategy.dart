import 'dart:io';

import 'package:cli_calendar_app/model/todo.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';

abstract class DatabaseStrategy {
  Future<bool> init({
    required String token,
    required String repoName,
    required String dbConfigPath,
  });

  //todo maybe add methods isLoggedIn, repoIsSet, configIsSet?
  Future<bool> autoSetup();

  Future<bool> login(String token);

  Future<bool> setRepo({required String repoName});

  Future<bool> setConfig({required String dbConfigPath});

  Future<File?> fetchCalendarFile({required Config config});

  Future<List<Todo>?> getNumOpenIssues(int num);

  Future<int?> uploadIssue({required Todo todo, required Config config});

  Future<bool> solveIssue({required int issueNumber});

  bool isInitialized();

  Future<Config?> getConfig();

  int? getRemainingRateLimit();

  DateTime? getResetOfRateLimit();

  String getUsername();
}
