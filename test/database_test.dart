// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cli_calendar_app/model/todo.dart';
import 'package:cli_calendar_app/services/database/github_connection.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github/github.dart';

//required so that http functions are usa able in tests
class CustomBindings extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get overrideHttpClient => false;
}

void main() {
  ///setup
  //required so that http functions are usa able in tests
  CustomBindings();
  //required so that path functions are use able in tests
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/path_provider');
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    return 'test/assets/temp_phone_dir';
  });

  ///variables
  //dirs
  const String staticFileDir = 'test/assets/static_files_for_tests';
  const String dbDir = 'testUploads';
  //tokens
  //'repo', 'workflow'
  const String tokenOnlyRequiredScopes = '';
  const String tokenNoneScopes = '';
  const String tokenAllScopes = '';
  const String tokenOnlyOneScope = '';

  ///tests
  group('standalone tests', () {
    group('parsing', skip: false, () {
      group('filename from path', () {
        test('expected input', () {
          const String testFilename = 'filename.test';
          const String testPath = 'assert/test/$testFilename';
          final String parsedFilename =
              Database().getFilenameFromPath(testPath);
          expect(parsedFilename, testFilename);
        });
        test('not expected input', () {
          const String testFilename = 'filename.test';
          const String testPath = testFilename;
          final String parsedFilename =
              Database().getFilenameFromPath(testPath);
          expect(parsedFilename, testFilename);
        });
      });
      group('text from issue content', () {
        test('empty input', () {
          const String issueContent = '';
          final String parsedIssueText =
              Database().getTextFromIssueContent(issueContent);
          expect(parsedIssueText, '');
        });
        test('not expected input', () {
          const String issueText = 'test text';
          const String issueContent = '$issueText\nnrtiegnr\ntierngtie';
          final String parsedIssueText =
              Database().getTextFromIssueContent(issueContent);
          expect(parsedIssueText, issueText);
        });
        test('expected input', () {
          const String issueText = 'test text';
          // ignore: leading_newlines_in_multiline_strings
          const String issueContent = '''$issueText
        ![assets/issue_3/test_image.jpg](https://raw.githubusercontent.com/thob97/FlutterTestRepo--2023-03-20T16_10_52.628239/main/assets/issue_3/test_image.jpg)
        [assets/issue_3/test_video.mp4](https://raw.githubusercontent.com/thob97/FlutterTestRepo--2023-03-20T16_10_52.628239/main/assets/issue_3/test_video.mp4)''';
          final String parsedIssueText =
              Database().getTextFromIssueContent(issueContent);
          expect(parsedIssueText, issueText);
        });
      });
      group('file paths from issue content', () {
        test('expected input with files', () {
          final List<String> filePaths = [
            'assets/issue_3/test_image.jpg',
            'assets/issue_3/test_video.mp4'
          ];
          // ignore: leading_newlines_in_multiline_strings
          final String issueContent = '''testBody
        ![${filePaths[0]}](https://raw.githubusercontent.com/thob97/FlutterTestRepo--2023-03-20T16_10_52.628239/main/assets/issue_3/test_image.jpg)
        [${filePaths[1]}](https://raw.githubusercontent.com/thob97/FlutterTestRepo--2023-03-20T16_10_52.628239/main/assets/issue_3/test_video.mp4)''';
          final List<String> parsedFilePaths =
              Database().getFilePathsFromIssueContent(issueContent);
          expect(parsedFilePaths, filePaths);
        });
        test('expected input without files', () {
          final List<String> parsedFilePaths =
              Database().getFilePathsFromIssueContent('test Issue Body');
          expect(parsedFilePaths, []);
        });
        test('unexpected input', () {
          final List<String> parsedFilePaths =
              Database().getFilePathsFromIssueContent(
            'test Issue Body\n rntsiesnr\nienrs',
          );
          expect(parsedFilePaths, []);
        });
        test('empty input', () {
          final List<String> parsedFilePaths =
              Database().getFilePathsFromIssueContent('');
          expect(parsedFilePaths, []);
        });
      });
    });

    group('Test TokenScope', skip: false, () {
      test('only required scopes', () async {
        final Database tempDb = Database();
        final String? loginId = await tempDb.login(tokenOnlyRequiredScopes);
        expect(
          loginId != null,
          true,
          reason: 'database should connect, as token is valid',
        );
        expect(
          await tempDb.tokenScopeIsValid(),
          true,
          reason: 'scope check should pass as scope is sufficient',
        );
      });
      test('no scopes', () async {
        final Database tempDb = Database();
        final String? loginId = await tempDb.login(tokenNoneScopes);
        expect(
          loginId != null,
          true,
          reason:
              'database should connect, as token is valid (only scopes are insufficient)',
        );
        expect(
          await tempDb.tokenScopeIsValid(),
          false,
          reason: 'scope check should return false as scope is insufficient',
        );
      });
      test('all scopes', () async {
        final Database tempDb = Database();
        final String? loginId = await tempDb.login(tokenAllScopes);
        expect(
          loginId != null,
          true,
          reason: 'database should connect, as token is valid',
        );
        expect(
          await tempDb.tokenScopeIsValid(),
          true,
          reason: 'scope check should pass as scope is sufficient',
        );
      });
      test('one not needed scope', () async {
        final Database tempDb = Database();
        final String? loginId = await tempDb.login(tokenOnlyOneScope);
        expect(
          loginId != null,
          true,
          reason:
              'database should connect, as token is valid (only scopes are insufficient)',
        );
        expect(
          await tempDb.tokenScopeIsValid(),
          false,
          reason: 'scope check should return false as scope is insufficient',
        );
      });
    });
  });

  group('integration test?: (test from small to big)', () {
    late final Database db;
    group('init tests: required for following tests', skip: false, () {
      group('login', () {
        test('login: invalid token', () async {
          final Database tempDb = Database();
          final String? loginId = await tempDb.login('token');
          expect(
            loginId == null,
            true,
            reason:
                'database should not return a connection, as token is invalid',
          );
        });
        test('login: valid token', () async {
          final Database tempDb = Database();
          final String? loginId = await tempDb.login(tokenOnlyRequiredScopes);
          expect(
            loginId != null,
            true,
            reason: 'database should return a connection, as token is valid',
          );
          db = tempDb;
        });
      });

      group('repo', () {
        ///variables
        String randomGitName() =>
            'FlutterTestRepo--${DateTime.now().toIso8601String().replaceAll(':', '_')}';
        final String repoName = randomGitName();
        const String repoDesc = 'description';

        ///
        group('createRepo', () {
          test('new repo', () async {
            ///tests for function
            final bool res =
                await db.createRepo(title: repoName, description: repoDesc);
            expect(
              res,
              true,
              reason:
                  'repo should be created, as the repo name is valid & not used',
            );

            ///additional tests for api
            //fetch repo
            final tempRepo = RepositorySlug(
              (await db.gitHub.users.getCurrentUser()).login!,
              repoName,
            ); //Error possibility: github changes some name chars into different once. E.g.: ' ' to '-'
            final Repository fetchedRepo =
                await db.gitHub.repositories.getRepository(tempRepo);

            //tests if repo really got uploaded
            expect(
              fetchedRepo.name,
              repoName,
              reason: 'should pass - titles should be equal',
            );
            expect(
              fetchedRepo.description,
              repoDesc,
              reason: 'should pass = description should be equal',
            );
          });
          test('duplicate repo', () async {
            final bool res =
                await db.createRepo(title: repoName, description: repoDesc);
            expect(
              res,
              false,
              reason:
                  'repo should not be created, as the repo name already used',
            );
          });
          test('invalid title repo', () async {
            final bool res =
                await db.createRepo(title: '', description: repoDesc);
            expect(
              res,
              false,
              reason: 'repo should not be created, as the repo name is invalid',
            );
          });
        });

        ///
        group('setRepo', () {
          test('invalid repo name', () async {
            final bool res = await db.setRepo(repoName: '.');
            expect(
              res,
              false,
              reason:
                  'should fail - repo name is not possible and thus repo does not exist',
            );
          });
          test('not existing repo name', () async {
            final bool res = await db.setRepo(repoName: randomGitName());
            expect(res, false, reason: 'should fail, as repo does not exist');
          });
          test('valid repo ', () async {
            final bool res = await db.setRepo(repoName: repoName);
            expect(
              res,
              true,
              reason: 'should pass - as just created repo exists',
            );
          });
        });
      });
    });

    group('file', skip: false, () {
      ///variables
      final File textFile = File('$staticFileDir/test_text.txt');
      final File picFile = File('$staticFileDir/test_image.jpg');
      final File videoFile = File('$staticFileDir/test_video.mp4');
      final File mediumFile = File('$staticFileDir/test_medium_file_50MB.zip');
      final File tooLargeFile =
          File('$staticFileDir/test_too_large_file_200MB.zip');

      ///tests
      group('normal text', () {
        const String githubPath = '$dbDir/test_text.txt';
        test('upload text', () async {
          final String? res = await db.uploadFile(
            filePath: githubPath,
            uploadFile: textFile,
            commitMsg: 'test-upload commit',
          );
          expect(
            res != null,
            true,
            reason:
                'file should be uploaded - as there is no duplicate in this new repo',
          );
        });
        test('upload duplicate file', () async {
          final String? res = await db.uploadFile(
            filePath: githubPath,
            uploadFile: textFile,
            commitMsg: 'test-upload commit',
          );
          expect(
            res != null,
            false,
            reason:
                'file should not be uploaded - as there is a duplicate in this new repo',
          );
        });
        test('fetch text', () async {
          ///function testing
          final File? fetchedFile = await db.fetchFile(dbFilePath: githubPath);
          expect(
            fetchedFile != null,
            true,
            reason:
                'file should be fetch-able, as file just got uploaded in previous text',
          );

          ///additional api testing
          //test has the same name and path
          expect(
            listEquals(
              fetchedFile!.readAsBytesSync(),
              textFile.readAsBytesSync(),
            ),
            true,
            reason:
                'the data of the local file which got uploaded should be the same when it got fetched',
          );
        });
      });

      ///
      test('fetch non existing file', () async {
        final res = await db.fetchFile(dbFilePath: 'notExisting');
        expect(
          res == null,
          true,
          reason:
              'file should not be fetch-able - as there is no such file in this repo',
        );
      });

      ///
      group('picture', () {
        const String githubPath = '$dbDir/test_pic.jpg';

        test('upload picture', () async {
          //upload
          final String? res = await db.uploadFile(
            filePath: githubPath,
            uploadFile: picFile,
            commitMsg: 'test-upload commit',
          );
          expect(
            res != null,
            true,
            reason:
                'file should be uploaded - as there is no duplicate in this new repo',
          );
        });
        test('fetch picture file', () async {
          ///function testing
          final fetchedFile = await db.fetchFile(dbFilePath: githubPath);
          expect(
            fetchedFile != null,
            true,
            reason:
                'file should be fetch-able, as file just got uploaded in previous text',
          );

          ///additional api testing
          //test if content is equal
          expect(
            listEquals(
              fetchedFile!.readAsBytesSync(),
              picFile.readAsBytesSync(),
            ),
            true,
            reason:
                'the data of the local file which got uploaded should be the same when it got fetched',
          );
        });
      });

      ///
      group('audio / video', () {
        const String githubPath = '$dbDir/test_video.mp4';

        test('upload video', () async {
          //upload
          final String? res = await db.uploadFile(
            filePath: githubPath,
            uploadFile: videoFile,
            commitMsg: 'test-upload commit',
          );
          expect(
            res != null,
            true,
            reason:
                'file should be uploaded - as there is no duplicate in this new repo',
          );
        });
        test('fetch video file', () async {
          ///function testing
          final fetchedFile = await db.fetchFile(
            dbFilePath: githubPath,
          );
          expect(
            fetchedFile != null,
            true,
            reason:
                'file should be fetch-able, as file just got uploaded in previous text',
          );

          ///additional api testing
          //test if content is equal
          expect(
            listEquals(
              fetchedFile!.readAsBytesSync(),
              videoFile.readAsBytesSync(),
            ),
            true,
            reason:
                'the data of the local file which got uploaded should be the same when it got fetched',
          );
        });
      });

      ///
      group('file size', skip: true, () {
        group('medium file 50mb', () {
          const String githubPath = '$dbDir/test_medium_file_50MB.zip';
          test('upload', () async {
            //upload
            final String? res = await db.uploadFile(
              filePath: githubPath,
              uploadFile: mediumFile,
              commitMsg: 'test-upload commit',
            );
            expect(
              res != null,
              true,
              reason:
                  'file should be uploaded - as 50mb is lower than the maximum of 100mb & there is no duplicate file',
            );
          });
          test('fetch', () async {
            ///function testing
            final fetchedFile = await db.fetchFile(
              dbFilePath: githubPath,
            );
            expect(
              fetchedFile != null,
              true,
              reason:
                  'file should be fetch-able - as there is this file in this repo + 50mb is lower than the maximum of 100mb',
            );

            ///additional api testing
            //test if content is equal
            expect(
              listEquals(
                fetchedFile!.readAsBytesSync(),
                mediumFile.readAsBytesSync(),
              ),
              true,
              reason:
                  'the data of the local file which got uploaded should be the same when it got fetched',
            );
          });
        });

        group('too large file 200mb', () {
          const String githubPath = '$dbDir/test_too_large_file_200MB.zip';
          test('upload', () async {
            final String? res = await db.uploadFile(
              filePath: githubPath,
              uploadFile: tooLargeFile,
              commitMsg: 'test-upload commit',
            );
            expect(
              res != null,
              false,
              reason:
                  'file should not be uploaded - as 200mb is higher than the maximum of 100mb',
            );
          });
          test('fetch', () async {
            final fetchedFile = await db.fetchFile(
              dbFilePath: githubPath,
            );
            expect(
              fetchedFile != null,
              false,
              reason:
                  'file should not be fetch-able - as the file should not exist (becaus of previous upload test) + 200mb is higher than the maximum of 100mb',
            );
          });
        });
      });
    });

    group('config: required for issues tests', skip: false, () {
      const config = Config(
        customCommitMsg: 'custom commit msg',
        issueFileUploadDirPath: 'customFileDir',
        issueLabelOfTodoEntries: 'customLabel',
        calendarFilePath: 'calendar.filepath.notNeeded.inThis.test',
      );
      const String dbFilePath = 'config.json';

      test('upload config', () async {
        final bool res = await db.uploadConfig(
          config: config,
          dbFilePath: dbFilePath,
        );
        expect(
          res,
          true,
          reason: 'config should be uploaded, as file does not already exist',
        );
      });
      test('fetch config', () async {
        final Config? res = await db.fetchConfig(dbConfigPath: dbFilePath);

        ///function testing
        expect(
          res != null,
          true,
          reason: 'file should be fetch-able, as config exists',
        );

        ///api testing
        expect(
          res == config,
          false,
          reason:
              'the data of the local file which got uploaded should be the same when it got fetched',
        );
      });
      group('set config', () {
        test('not existing', () async {
          final bool res = await db.setConfig(dbConfigPath: '.');
          expect(
            res,
            false,
            reason:
                'config should not be set-able, as the given config file path does not exists on repo',
          );
        });
        test('existing', () async {
          final bool res = await db.setConfig(dbConfigPath: dbFilePath);
          expect(
            res,
            true,
            reason:
                'config should be set-able, as the given config file path does exists on repo',
          );
        });
      });
    });

    group('Issues', skip: false, () {
      ///variables
      final File picFile = File('$staticFileDir/test_image.jpg');
      final File videoFile = File('$staticFileDir/test_video.mp4');
      final Todo todoDummy =
          Todo(title: 'dummy', body: '', files: []); //will be used for: update
      final Todo todoText =
          Todo(title: 'test:issue with text', body: 'test body', files: []);
      final Todo todoWithFiles = Todo(
        title: 'test:issue with files',
        body: 'test body',
        files: [TodoFile(content: picFile), TodoFile(content: videoFile)],
      );
      final Todo todoUpdated = Todo(
        title: 'test:updated',
        body: 'was updated',
        files: [TodoFile(content: picFile), TodoFile(content: videoFile)],
      );
      final Todo todoSolved = Todo(
        title: 'test:solved',
        body: 'should be solved',
        files: [TodoFile(content: picFile), TodoFile(content: videoFile)],
      );

      ///
      group('uploadIssue', () {
        test('new issue', () async {
          final int? id = await db.uploadIssue(todo: todoText);
          expect(id != null, true);
          todoText.issueNumber = id;
        });
        test('new issue with files', () async {
          final int? id = await db.uploadIssue(todo: todoWithFiles);
          expect(id != null, true);
          todoWithFiles.issueNumber = id;
        });
        test('update issue', () async {
          final int? toUpdateId = await db.uploadIssue(todo: todoDummy);
          todoUpdated.issueNumber = toUpdateId;
          final int? id = await db.uploadIssue(todo: todoUpdated);
          expect(id != null, true);
          todoUpdated.issueNumber = id;
        });
      });

      ///
      test('solve issue', () async {
        final int? toUSolveId = await db.uploadIssue(todo: todoSolved);
        final bool id = await db.solveIssue(issueNumber: toUSolveId!);
        expect(id, true);
      });

      ///
      group('getNumOpenIssues: comparison depends on previous uploaded issues',
          () {
        test('get issues', () async {
          //
          final List<Todo>? todos = await db.getNumOpenIssues(10);
          expect(todos != null, true);

          //compare just uploaded issues
          final List<Todo> compare = [todoText, todoWithFiles, todoUpdated];
          for (int i = 0; i < todos!.length; i++) {
            //compare
            final Todo fetchedTodo = todos[i];
            final uploadedTodo = compare[i];
            expect(fetchedTodo.issueNumber == uploadedTodo.issueNumber, true);
            expect(fetchedTodo.title == uploadedTodo.title, true);
            expect(fetchedTodo.body == uploadedTodo.body, true);
            //compare files content
            for (int x = 0; x < fetchedTodo.files.length; x++) {
              expect(
                fetchedTodo.files[x].getFileType() ==
                    uploadedTodo.files[x].getFileType(),
                true,
              );
              expect(
                listEquals(
                  fetchedTodo.files[x].content.readAsBytesSync(),
                  uploadedTodo.files[x].content.readAsBytesSync(),
                ),
                true,
              );
            }
          }
        });
      });
    });
  });

  group(
      'modular test?: (test function which uses everything / test everything at once)',
      skip: false, () {
    const String dbConfigPath =
        'config.json'; // must be same as in autoSetup()!!!
    final Database database = Database();

    test('autoSetup', () async {
      await database.login(tokenOnlyRequiredScopes);
      final bool success = await database.autoSetup();
      expect(success, true);
    });
    test(
        'initiate new database connection with just created repo from autoSetup()',
        () async {
      final db = await Database().init(
        token: tokenOnlyRequiredScopes,
        repoName: database.repo!.name,
        dbConfigPath: dbConfigPath,
      );
      expect(db != null, true);
    });
  });

  test('clean up: delete ALL repos -CAREFUL!', skip: true, () async {
    ///login
    final Database database = Database();
    await database.login(tokenAllScopes);
    print(database.getResetOfRateLimit());
    print(database.getRemainingRateLimit());

    ///count variables
    int totalBefore = 0;
    int deleted = 0;

    ///for each repo
    Stream<Repository> stream = database.gitHub.repositories.listRepositories();
    await for (final repo in stream) {
      totalBefore += 1;

      ///delete repo
      await database.gitHub.repositories.deleteRepository(repo.slug());
      print('deleted repo: ${repo.fullName}');
      deleted += 1;
    }

    ///count repos after deletion
    stream = database.gitHub.repositories.listRepositories();
    int totalAfter = 0;
    await for (final _ in stream) {
      totalAfter += 1;
    }

    ///compare num of: all counted repos VS deleted + after deletion counted repos
    expect(
      totalBefore,
      totalAfter + deleted,
      reason: 'num of repos should have decreased',
    );
  });
}
