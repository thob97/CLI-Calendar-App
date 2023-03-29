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
  Config? _config;
  bool isLoggedIn = false;
  bool repoPathValid = false;

  @override
  bool isInitialized() {
    return isLoggedIn && repoPathValid && _config != null;
  }

  @override
  Future<String?> login(String token) {
    if (token == 'password') {
      isLoggedIn = true;
      return Future.delayed(const Duration(seconds: 1))
          .then((_) => 'MockedUsername');
    } else {
      isLoggedIn = false;
      return Future.delayed(const Duration(seconds: 1)).then((_) => null);
    }
  }

  @override
  Future<bool> setConfig({required String dbConfigPath}) {
    if (dbConfigPath == 'config.json') {
      _config = Config.defaultSettings(calendarFilePath: 'calendarFilePath');
      return Future.delayed(const Duration(seconds: 1)).then((_) => true);
    } else {
      _config = null;
      return Future.delayed(const Duration(seconds: 1)).then((_) => false);
    }
  }

  @override
  Future<bool> setRepo({required String repoName}) {
    if (repoName == 'repo') {
      repoPathValid = true;
      return Future.delayed(const Duration(seconds: 1)).then((_) => true);
    } else {
      repoPathValid = false;
      return Future.delayed(const Duration(seconds: 1)).then((_) => false);
    }
  }

  ///-----:-----
  @override
  Future<DatabaseStrategy?> init({
    required String token,
    required String repoName,
    required String dbConfigPath,
  }) async {
    ///login -> setRepo -> setConfig  -> on any error return null
    late bool onError;
    onError = !(await login(token) != null);
    if (onError) {
      return null;
    }
    onError = !(await setRepo(repoName: repoName));
    if (onError) {
      return null;
    }
    onError = !(await setConfig(dbConfigPath: dbConfigPath));
    if (onError) {
      return null;
    }
    return this;
  }

  @override
  Future<bool> autoSetup() {
    return Future.delayed(const Duration(seconds: 2)).then((_) => true);
  }

  @override
  Future<File?> fetchCalendarFile() {
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
    final List<TodoFile> issueFiles = [
      TodoFile(content: await _getFileFromAssets('assets/autoSetup/audio.mp3')),
      TodoFile(
        content: await _getFileFromAssets('assets/autoSetup/picture.jpg'),
      ),
      TodoFile(content: await _getFileFromAssets('assets/autoSetup/video.mp4'))
    ];
    final List<TodoFile> issueFiles2 = [
      TodoFile(
        content: await _getFileFromAssets('assets/autoSetup/picture.jpg'),
      ),
    ];
    return Future.delayed(const Duration(seconds: 1)).then(
      (_) => [
        Todo(
            title: 'Mocked Entry1',
            body: 'Mocked Body Entry1',
            files: issueFiles),
        Todo(
            title: 'Mocked Entry2',
            body:
                "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum",
            files: issueFiles2),
        Todo(title: 'Mocked Entry3', body: '', files: []),
      ],
    );
  }

  @override
  Future<bool> solveIssue({required int issueNumber}) {
    assert(isInitialized());
    return Future.delayed(const Duration(seconds: 1)).then((_) => true);
  }

  @override
  Future<int?> uploadIssue({required Todo todo}) {
    assert(isInitialized());
    return Future.delayed(const Duration(seconds: 1)).then((_) => 1);
  }

  @override
  Config getConfig() {
    assert(isInitialized());
    assert(_config != null);
    return _config!;
  }

  ///-----OTHER-----
  //(settings / user / information)
  @override
  int? getRemainingRateLimit() {
    assert(isLoggedIn);
    return Random().nextInt(5000);
  }

  @override
  DateTime? getResetOfRateLimit() {
    assert(isLoggedIn);
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
