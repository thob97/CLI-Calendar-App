import 'dart:io';
import 'dart:math';

import 'package:cli_calendar_app/model/todo.dart';
import 'package:cli_calendar_app/services/database/database_strategy.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';
import 'package:cli_calendar_app/services/parser/regex.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MockedDatabase implements DatabaseStrategy {
  ///-----INITIAL-----
  String? _configPath;
  bool _isLoggedIn = false;
  bool _repoPathValid = false;
  String? _username;
  List<Todo>? _issues;

  @override
  bool isInitialized() {
    return _isLoggedIn && _repoPathValid && _configPath != null;
  }

  @override
  Future<bool> login(String token) {
    if (token == 'password') {
      _isLoggedIn = true;
      _username = 'MockedUsername';
      return Future.delayed(const Duration(seconds: 1)).then((_) => true);
    } else {
      _isLoggedIn = false;
      _username = null;
      return Future.delayed(const Duration(seconds: 1)).then((_) => false);
    }
  }

  @override
  Future<bool> setConfig({required String dbConfigPath}) {
    if (dbConfigPath == 'config.json') {
      _configPath = 'path';
      return Future.delayed(const Duration(seconds: 1)).then((_) => true);
    } else {
      _configPath = null;
      return Future.delayed(const Duration(seconds: 1)).then((_) => false);
    }
  }

  @override
  Future<bool> setRepo({required String repoName}) {
    if (repoName == 'repo') {
      _repoPathValid = true;
      return Future.delayed(const Duration(seconds: 1)).then((_) => true);
    } else {
      _repoPathValid = false;
      return Future.delayed(const Duration(seconds: 1)).then((_) => false);
    }
  }

  ///-----:-----
  @override
  Future<bool> init({
    required String token,
    required String repoName,
    required String dbConfigPath,
  }) async {
    ///login -> setRepo -> setConfig  -> on any error return null
    late bool onError;
    onError = !(await login(token));
    if (onError) {
      return false;
    }
    onError = !(await setRepo(repoName: repoName));
    if (onError) {
      return false;
    }
    onError = !(await setConfig(dbConfigPath: dbConfigPath));
    if (onError) {
      return false;
    }
    return true;
  }

  @override
  String getUsername() {
    assert(_isLoggedIn);
    return _username!;
  }

  //purpose: const values for autoSetup
  @override
  String get autoSetupRepoName => 'repo';

  @override
  String get autoSetupConfigPath => 'config.json';

  @override
  Future<bool> autoSetup() {
    return Future.delayed(const Duration(seconds: 2)).then((_) => true);
  }

  @override
  Future<File?> fetchCalendarFile({required Config config}) {
    assert(isInitialized());
    return Future.delayed(const Duration(seconds: 1)).then(
      (_) => _getFileFromAssets(
        'assets/autoSetup/when_showcase_calendar_file.txt',
      ),
    );
  }

  ///-----ISSUES-----
  @override
  Future<List<Todo>?> getNumOpenIssues(int num) async {
    ///has issues not been initialized -> init issues
    if (_issues == null) {
      final List<TodoFile> issueFiles = [
        TodoFile(
          content: await _getFileFromAssets('assets/autoSetup/audio.mp3'),
        ),
        TodoFile(
          content: await _getFileFromAssets('assets/autoSetup/picture.jpg'),
        ),
        TodoFile(
          content: await _getFileFromAssets('assets/autoSetup/video.mp4'),
        )
      ];
      final List<TodoFile> issueFiles2 = [
        TodoFile(
          content: await _getFileFromAssets('assets/autoSetup/picture.jpg'),
        ),
      ];
      _issues = [
        Todo(
          issueNumber: 1,
          title: 'Mocked Entry1',
          body: 'mMocked Body Entry1',
          files: issueFiles,
        ),
        Todo(
          issueNumber: 2,
          title: 'Mocked Entry2',
          body:
              "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum",
          files: issueFiles2,
        ),
        Todo(issueNumber: 3, title: 'Mocked Entry3', body: '', files: []),
      ];
    }
    return Future.delayed(const Duration(seconds: 1)).then(
      (_) => [
        ..._issues ?? []
      ], //copy of list, else will add and remove twice in TodoPage
    );
  }

  @override
  Future<bool> solveIssue({required int issueNumber}) {
    assert(isInitialized());
    assert(_issues != null);
    _issues!.removeWhere((todo) => todo.issueNumber == issueNumber);
    return Future.delayed(const Duration(seconds: 1)).then((_) => true);
  }

  @override
  Future<int?> uploadIssue({required Todo todo, required Config config}) {
    assert(isInitialized());
    assert(_issues != null);

    ///if new issue
    if (todo.issueNumber == null) {
      todo.issueNumber = Random().nextInt(100000) + 1;
      _issues!.add(todo);
    }

    ///if issue to edit
    else {
      final Todo editTodo = _issues!
          .firstWhere((element) => element.issueNumber == todo.issueNumber);
      editTodo.title = todo.title;
      editTodo.body = todo.body;
      editTodo.files = todo.files;
    }

    return Future.delayed(const Duration(seconds: 1))
        .then((_) => todo.issueNumber);
  }

  @override
  Future<Config?> getConfig() {
    assert(isInitialized());
    assert(_configPath != null);
    return Future.delayed(const Duration(seconds: 1)).then(
      (_) => Config.defaultSettings(calendarFilePath: 'calendarFilePath'),
    );
  }

  ///-----OTHER-----
  //(settings / user / information)
  @override
  int? getRemainingRateLimit() {
    assert(_isLoggedIn);
    return Random().nextInt(5000);
  }

  @override
  DateTime? getResetOfRateLimit() {
    assert(_isLoggedIn);
    return DateTime.now().add(const Duration(hours: 1));
  }

  ///-----HELPER-FUNCTIONS-----
  Future<File> _getFileFromAssets(String path) async {
    final content = await rootBundle.load(path);
    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/${_getFilenameFromPath(path)}');
    await file.writeAsBytes(content.buffer.asUint8List());
    return file;
  }

  String _getFilenameFromPath(String filePath) {
    assert(filePath.isNotEmpty);
    //get everything that is not a '/' from the end of the string
    //example: test/assets/test_image.jpg -> test_image.jpg
    return getFirstRegexMatch(filePath, r'([^/]+)$');
  }
}
