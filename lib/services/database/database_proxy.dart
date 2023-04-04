import 'dart:io';

import 'package:cli_calendar_app/model/todo.dart';
import 'package:cli_calendar_app/services/database/database_strategy.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';

class DatabaseProxy extends DatabaseStrategy {
  DatabaseProxy({required this.database});

  final DatabaseStrategy database;

  //
  //
  //
  //
  List<Todo>? cachedTodos = [];
  File? cachedCalendarFile;
  Config? cachedConfig;

  ///-----proxy functions-----
  void _clearProxyData() {
    cachedTodos = [];
    cachedCalendarFile = null;
  }

  //
  //
  //
  //
  ///-----overridden functions-----
  @override
  Future<bool> autoSetup() {
    ///proxy
    _clearProxyData();
    return database.autoSetup();
  }

  @override
  Future<File?> fetchCalendarFile({required Config config}) async {
    ///proxy calendar file
    return cachedCalendarFile ??=
        await database.fetchCalendarFile(config: config);
  }

  @override
  Future<Config?> getConfig() async {
    ///proxy config
    return cachedConfig ??= await database.getConfig();
  }

  @override
  Future<List<Todo>?> getNumOpenIssues(int num) async {
    ///proxy todos
    return cachedTodos = await database.getNumOpenIssues(num) ?? [];
  }

  @override
  Future<bool> login(String token) {
    ///proxy data should reload on new login -> clearCache
    _clearProxyData();
    return database.login(token);
  }

  @override
  Future<bool> setConfig({required String dbConfigPath}) {
    ///proxy data should reload on new config -> clearCache
    _clearProxyData();
    return database.setConfig(dbConfigPath: dbConfigPath);
  }

  @override
  Future<bool> setRepo({required String repoName}) {
    ///proxy data should reload on new config -> clearCache
    _clearProxyData();
    return database.setRepo(repoName: repoName);
  }

  @override
  Future<bool> solveIssue({required int issueNumber}) async {
    ///issues should only be able to be solved when it got fetched once
    assert(cachedTodos != null);
    final bool success = await database.solveIssue(issueNumber: issueNumber);

    ///remove issue from proxy
    if (success) {
      cachedTodos!.removeWhere((element) => element.issueNumber == issueNumber);
    }
    return success;
  }

  @override
  Future<int?> uploadIssue({required Todo todo, required Config config}) async {
    ///issues should only be able to be added when it got fetched once
    assert(cachedTodos != null);
    final int? id = await database.uploadIssue(todo: todo, config: config);

    ///add issue to proxy
    if (id != null) {
      todo.issueNumber = id;
      cachedTodos!.add(todo);
      return id;
    }
    return null;
  }

  //
  //
  //
  //
  ///-----not changed database functions-----
  @override
  int? getRemainingRateLimit() => database.getRemainingRateLimit();

  @override
  DateTime? getResetOfRateLimit() => database.getResetOfRateLimit();

  @override
  String getUsername() => database.getUsername();

  @override
  Future<bool> init({
    required String token,
    required String repoName,
    required String dbConfigPath,
  }) {
    return database.init(
      token: token,
      repoName: repoName,
      dbConfigPath: dbConfigPath,
    );
  }

  @override
  bool isInitialized() {
    return database.isInitialized();
  }
}
