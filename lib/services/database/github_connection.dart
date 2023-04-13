import 'dart:convert';
import 'dart:io';

import 'package:cli_calendar_app/model/todo.dart';
import 'package:cli_calendar_app/services/database/database_strategy.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';
import 'package:cli_calendar_app/services/parser/regex.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class GitHubConnection implements DatabaseStrategy {
  @visibleForTesting
  late GitHub gitHub;
  @visibleForTesting
  RepositorySlug? repo; //null when not valid set
  String? _configPath; //null when not valid set
  String? _userName; //null when not logged in

  ///-----Helpers-----
  @visibleForTesting
  bool isLoggedInWithToken() {
    return _userName != null &&
        gitHub.auth != null &&
        gitHub.auth!.token != null;
  }

  @visibleForTesting
  bool repoIsSet() {
    return repo != null;
  }

  @visibleForTesting
  bool configIsSet() {
    return _configPath != null;
  }

  @override
  bool isInitialized() {
    return isLoggedInWithToken() && repoIsSet() && configIsSet();
  }

  //purpose: to inform user
  //assert: user is logged in with token
  @override
  int? getRemainingRateLimit() {
    assert(isLoggedInWithToken());
    return gitHub.rateLimitRemaining;
  }

  //purpose: to inform user
  //assert: user is logged in with token
  //todo utc time gap
  @override
  DateTime? getResetOfRateLimit() {
    assert(isLoggedInWithToken());
    return gitHub.rateLimitReset?.add(const Duration(hours: 2));
  }

  ///-----INITIAL-----
  //def: initializes the database with the given login, repo, and config
  //purpose: used on each restart of the device / when a connection needs to be established
  //assert: -
  //return: true on success - false on failure
  @override
  Future<bool> init({
    required String token,
    required String repoName,
    required String dbConfigPath,
  }) async {
    ///login -> setRepo -> setConfig -> testTokenRight -> on any error return null
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
    onError = !(await tokenScopeIsValid());
    if (onError) {
      return false;
    }
    return true;
  }

  //purpose: const values for autoSetup
  //assert: only get after autoSetup method was run
  @override
  late String autoSetupRepoName;

  @override
  String get autoSetupConfigPath => 'config.json';

  //def: creates & uploads a new repo with all needed files for the app to function
  //purpose: used for an easy start and showcase of the app
  //assert: user is logged in with token & autoSetup repo name is not already taken (should not occur under normal circumstances)
  //return: true if api succeeds - false on failure
  @override
  Future<bool> autoSetup() async {
    assert(isLoggedInWithToken());

    ///const variables
    //repo
    autoSetupRepoName =
        'Calendar-${DateFormat.yMd().add_Hms().format(DateTime.now()).replaceAll(RegExp(r'\D'), '-')}';
    final String repoName = autoSetupRepoName;
    const String repoDesc =
        'The repository to sync your cli calendar file with your phone';
    //calendar file
    const String dbCalendarPath = 'calendar';
    final calendarShowcaseFile = await _getFileFromAssets(
      'assets/autoSetup/when_showcase_calendar_file.txt',
    );
    const String calendarCommitMsg = 'add calendar file';
    //config
    final String dbConfigPath = autoSetupConfigPath;
    final Config autoGeneratedConfig =
        Config.defaultSettings(calendarFilePath: dbCalendarPath);
    //issue
    const String issueTitle = 'Your first Reminder!';
    const String issueText =
        'You can add text, pictures, videos, and audio files. Everything will be uploaded to the specified repository as an issue. Thus, you can view the reminder on your phone, through the CLI, or on the website.';
    final List<TodoFile> issueFiles = [
      TodoFile(content: await _getFileFromAssets('assets/autoSetup/audio.mp3')),
      TodoFile(
        content: await _getFileFromAssets('assets/autoSetup/picture.jpg'),
      ),
      TodoFile(content: await _getFileFromAssets('assets/autoSetup/video.mp4'))
    ];
    final Todo showCaseIssue =
        Todo(title: issueTitle, body: issueText, files: issueFiles);

    ///setup:  createRepo + set -> uploadConfig + set -> upload showcase Issue -> upload showcase calendar file -> on any error return null
    late bool onError;
    //createRepo + set
    onError = !(await createRepo(title: repoName, description: repoDesc));
    if (onError) {
      return false;
    }
    onError = !(await setRepo(repoName: repoName));
    if (onError) {
      return false;
    }
    //uploadConfig + set
    onError = !(await uploadConfig(
      config: autoGeneratedConfig,
      dbFilePath: dbConfigPath,
    ));
    if (onError) {
      return false;
    }
    onError = !(await setConfig(dbConfigPath: dbConfigPath));
    if (onError) {
      return false;
    }
    //upload showcaseIssue issue
    onError =
        !(await uploadIssue(todo: showCaseIssue, config: autoGeneratedConfig) !=
            null);
    if (onError) {
      return false;
    }
    //upload showcaseIssue calendar file
    onError = !(await uploadFile(
          filePath: dbCalendarPath,
          uploadFile: calendarShowcaseFile,
          commitMsg: calendarCommitMsg,
        ) !=
        null);
    if (onError) {
      return false;
    }
    return true;
  }

  ///-----SET-----
  //def: tries to login -> updates gitHub and userName accordingly
  //assert: -
  //purpose: used in init() + to change the login
  //return: true if token is valid & scope is sufficient - false on failure
  @override
  Future<bool> login(String token) async {
    ///authenticate
    final GitHub testGitHubConnection =
        GitHub(auth: Authentication.withToken(token));

    ///on success return login id and set github
    String? loginId;
    try {
      //will throw error on invalid token
      loginId = (await testGitHubConnection.users.getCurrentUser()).login;
    } catch (_) {
      //gitHub = null;
      _userName = null;
      return false;
    }
    //never has been null in testing - unsure when if could be null - but to be safe
    if (loginId == null) throw Exception('Login succeeded but user id is null');
    //update github and userName on success
    gitHub = testGitHubConnection;
    _userName = loginId;
    return tokenScopeIsValid();
  }

  //todo: assert & check: only allow special chars '-' and '_' as github doesent accept others
  //def: sets repo (sets to null on failure)
  //assert: user is logged in
  //purpose: used in init() + to change the repo
  //return: true on if repo exists - otherwise false
  @override
  Future<bool> setRepo({required String repoName}) async {
    assert(isLoggedInWithToken());

    ///set
    final testRepo = RepositorySlug(_userName!, repoName);
    try {
      //test if repo exists/ is fetch-able - will throw error on failure
      await gitHub.repositories.getRepository(testRepo);
      repo = testRepo;
      return true;
    } catch (_) {
      repo = null;
      return false;
    }
  }

  //def: sets config (sets to null on failure)
  //assert: user is logged in & repo is set
  //purpose: used in init() + to change the config
  //return: true on if config exists - otherwise false
  @override
  Future<bool> setConfig({required String dbConfigPath}) async {
    assert(isLoggedInWithToken() && repoIsSet());

    final Config? fetchedConfig = await fetchConfig(dbConfigPath: dbConfigPath);
    if (fetchedConfig == null) {
      _configPath = null;
      return false;
    } else {
      _configPath = dbConfigPath;
      return true;
    }
  }

  //docs: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps
  //def: test if login/token has sufficient rights for the used api methods
  //assert: user is logged in with token
  //purpose: used in init() + to test the scopes in app
  //return: true if scopes are sufficient
  @visibleForTesting
  Future<bool> tokenScopeIsValid() async {
    assert(isLoggedInWithToken());

    ///const
    const List<String> neededScope = ['repo', 'workflow'];

    ///curl url
    final headers = {'Authorization': 'Bearer ${gitHub.auth!.token}'};
    final url = Uri.parse('https://api.github.com/users/codertocat');
    final res = await http.head(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('http.head error: statusCode= ${res.statusCode}');
    }
    final String? scopeResponse = res.headers['x-oauth-scopes'];
    if (scopeResponse == null) {
      throw Exception(
        'gitHub api error: website does not contain x-oauth-scopes',
      );
    }

    ///test if has all valid scopes \ rights
    //scope items in response String are divided by a ',' and a whitespace (-> whitespaces will be removed)
    final List<String> fetchedScopes = scopeResponse.split(RegExp(r',\s*'));
    for (final String scope in neededScope) {
      if (fetchedScopes.contains(scope) == false) {
        return false;
      }
    }
    return true;
  }

  ///----GET----
  //todo: assert & check: only allow special chars '-' and '_' as github doesent accept others
  //def: creates a new repository
  //purpose:  used once in autoSetup() method
  //asserts: user is logged in with token
  //returns: true if title is not a duplicate or empty & if api succeeds - false otherwise
  @visibleForTesting
  Future<bool> createRepo({
    required String title,
    required String description,
  }) async {
    assert(isLoggedInWithToken());

    ///create
    //upload: auto init => readme + commit: baseCommitMsg
    final CreateRepository newRepo = CreateRepository(
      title,
      description: description,
      private: true,
      autoInit: false,
    );

    ///upload
    late final Repository uploadedRepo;
    try {
      uploadedRepo = await gitHub.repositories.createRepository(newRepo);
    }
    //on api error || title is not valid
    catch (_) {
      return false;
    }

    ///test
    //github will return a repo with id=0 if it fails
    return uploadedRepo.id != 0;
  }

  //def: fetches Config from db
  //assert: user is logged in & repo is set
  //return: config if path is valid & if api succeeds - null otherwise
  @visibleForTesting
  Future<Config?> fetchConfig({required String dbConfigPath}) async {
    assert(isLoggedInWithToken() && repoIsSet());

    ///fetch
    final File? file = await fetchFile(dbFilePath: dbConfigPath);

    ///test if config exists
    if (file == null) {
      return null;
    } else {
      ///decode json encoding (string -> map)
      final Map<String, dynamic> fetchedJson =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      ///json to object
      return Config.fromJson(fetchedJson);
    }
  }

  //def: upload config to db
  //purpose:  used once in autoSetup() method
  //assert: user is logged in & repo is set
  //return: true if api succeeds & (file does not already exists) - false otherwise
  @visibleForTesting
  Future<bool> uploadConfig({
    required Config config,
    required String dbFilePath,
  }) async {
    assert(isLoggedInWithToken() && repoIsSet());

    ///object to json
    final json = config.toJson();

    ///encode
    // withIndent so its more readable
    const JsonEncoder newEncoder = JsonEncoder.withIndent('    ');
    final encodedJson = newEncoder.convert(json);

    ///create file
    final File file = await _createTempFile('config.json');
    file.writeAsStringSync(encodedJson);

    ///upload
    return await uploadFile(
          filePath: dbFilePath,
          uploadFile: file,
          commitMsg: 'init config',
        ) !=
        null;
  }

  //todo add tests
  //def: fetches CalendarFile from db
  //assert: database is initialized
  //return: file if it exists on repo & if api succeeds - null otherwise
  @override
  Future<File?> fetchCalendarFile({required Config config}) async {
    assert(isInitialized());

    ///fetch
    final File? file = await fetchFile(dbFilePath: config.calendarFilePath);

    ///test if file exists
    if (file == null) {
      return null;
    } else {
      return file;
    }
  }

  //def: get config
  //assert: database is initialized (= config is set)
  //return: config
  @override
  Future<Config?> getConfig() {
    assert(isInitialized());
    return fetchConfig(dbConfigPath: _configPath!);
  }

  //def: get username
  //assert: user is logged in with token => thus username != null
  @override
  String getUsername() {
    return _userName!;
  }

  ///-----FILES-----
  //def: encodes file to a valid format for uploading to github
  //asserts: -
  //returns: encoded file
  String _encodeFile({required File file}) {
    return base64.encode(file.readAsBytesSync());
  }

  //def: load a file from an asset path
  //assert: path is valid
  //return: file
  Future<File> _getFileFromAssets(String path) async {
    final content = await rootBundle.load(path);
    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/${getFilenameFromPath(path)}');
    await file.writeAsBytes(content.buffer.asUint8List());
    return file;
  }

  //def: creates a temp file
  //assert: -
  //return: temp file
  Future<File> _createTempFile(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final File file = File('${directory.path}/$fileName');
    return file;
  }

  //todo remove: keep until written in bachelor thesis
  //def: decodes a encoded file by github
  //asserts: encoded file from github + a valid local Path
  //returns: decoded file
  // @visibleForTesting
  // Future<File> decodeFile({required String encoded, required String tempFilePath}) async {
  //   ///decode github encoding
  //   //github download adds seems to add some special characters (whitespaces and \n)
  //   //decode: trimRight else dart error
  //   encoded = encoded.trimRight();
  //   //it might contain invalid chars like \n
  //   encoded = encoded.replaceAll('\n', '');
  //
  //   ///decode
  //   var data = base64.decode(encoded);
  //
  //   ///to file
  //   //getTemporaryDirectory() fails in testing as flutter app has not been initialized -> use only toFilePath
  //   File file = File(tempFilePath);
  //   file.writeAsBytesSync(data);
  //   return file;
  // }
  //todo till here

  //todo edit file: maybe allow to overwrite file with blob sha (first try to fetch -> get sha -> upload) - needed if editing issues is supported
  //def: uploads file and commits it to branch
  //assert: user is logged in & repo is set
  //return: downloadUrl if file does not already exist & api succeeds - null otherwise
  @visibleForTesting
  Future<String?> uploadFile({
    required String filePath,
    required File uploadFile,
    required String commitMsg,
  }) async {
    assert(isLoggedInWithToken() && repoIsSet());

    ///create
    //docs: https://docs.github.com/en/rest/repos/contents?apiVersion=2022-11-28#create-or-update-file-contents
    final CreateFile createFile = CreateFile(
      path: filePath,
      content: _encodeFile(file: uploadFile),
      message: commitMsg,
      //branch: testBranchName,
      //committer: user
    );

    ///upload
    late final ContentCreation file;
    try {
      file = await gitHub.repositories.createFile(repo!, createFile);
    }
    //on api error
    catch (_) {
      return null;
    }

    ///test if upload succeeded
    //succeeded if is not null + has a downloadUrl
    if (file.content == null ||
        file.content!.downloadUrl == null ||
        file.content!.downloadUrl!.isEmpty) {
      return null;
    } else {
      //html url instead of raw download url, as the latter is only valid for ~10minutes
      return file.content!.htmlUrl;
    }
  }

  //def: fetches file from branch
  //assert: user is logged in & repo is set
  //return: file if db path is valid & file is lower than 100mb limit & api succeeds - null otherwise
  @visibleForTesting
  Future<File?> fetchFile({required String dbFilePath}) async {
    assert(isLoggedInWithToken() && repoIsSet());

    ///fetch content
    late final RepositoryContents fetchedContent;
    try {
      fetchedContent = await gitHub.repositories.getContents(repo!, dbFilePath);
    }
    //on api error
    catch (_) {
      return null;
    }

    ///test
    //null if file does not exist
    //fetchedFile.contend = empty if file is over 1mb large
    //  but downloadUrl will be given until 100mb file size -> download via url
    final GitHubFile? fetchedFile = fetchedContent.file;
    if (fetchedFile == null ||
        fetchedFile.downloadUrl == null ||
        fetchedFile.downloadUrl!.isEmpty) {
      return null;
    }

    ///download file
    else {
      ///download from url
      final String url = fetchedFile.downloadUrl!;
      final Response response = await get(Uri.parse(url));

      ///write to file
      final File file = await _createTempFile(getFilenameFromPath(dbFilePath));
      file.writeAsBytesSync(response.bodyBytes);
      return file;
    }
  }

  ///-----ISSUE-PARSING-----
  //def: parse filename from path
  //assert: input is not empty
  //expects: after the last '/' follows the filename
  //return: filename
  @visibleForTesting
  String getFilenameFromPath(String filePath) {
    assert(filePath.isNotEmpty);
    //get everything that is not a '/' from the end of the string
    //example: test/assets/test_image.jpg -> test_image.jpg
    return getFirstRegexMatch(filePath, r'([^\/]+)$');
  }

  //def: parse text from the content of a issue
  //assert: -
  //expects: text is on the first line
  //return: the human body text content
  @visibleForTesting
  String getTextFromIssueContent(String issueContent) {
    //gets the first line of a string
    return getFirstRegexMatch(issueContent, '^.*');
  }

  //def: parse text from the content of a issue
  //asserts: -
  //expects: input has format r'(?<=\[).+(?=])'
  //return: the path
  @visibleForTesting
  List<String> getFilePathsFromIssueContent(String issueContent) {
    //gets all matches starting with [ and ending with ]
    //example: ![assets/issue_3/test_image.jpg]
    return getAllRegexMatches(r'((?<=\[).+(?=]))', issueContent);
  }

  ///-----ISSUES-----
  //def: get the first num open issues
  //assert: database is initialized
  //return: list of issues if api succeeds - null on failure
  @override
  Future<List<Todo>?> getNumOpenIssues(int num) async {
    assert(isInitialized());

    ///get all open issues
    late final List<Issue> issues;
    try {
      issues = await gitHub.issues
          .listByRepo(
            repo!,
            sort: 'updated',
            direction: 'asc',
            state: 'open',
            perPage: num,
          )
          .toList();
    }
    //on api error
    catch (_) {
      return null;
    }

    ///Issues to Todos
    final List<Todo> result = [];
    for (final Issue issue in issues) {
      ///parse: body & file paths
      final String issueText = getTextFromIssueContent(issue.body);
      final List<String> dbFilePaths = getFilePathsFromIssueContent(issue.body);
      final List<TodoFile> fetchedFiles = [];

      ///download files
      for (final String dbFilePath in dbFilePaths) {
        //fetch
        final File? file = await fetchFile(dbFilePath: dbFilePath);
        //abort on error
        if (file == null) {
          return null;
        }
        //add if succeeded
        fetchedFiles.add(TodoFile(content: file));
      }
      //add to list result-map list
      result.add(
        Todo(
          issueNumber: issue.number,
          title: issue.title,
          body: issueText,
          files: fetchedFiles,
        ),
      );
    }

    ///result
    return result;
  }

  //todo on edit all files will be uploaded - maybe only upload new files for less internet usage?
  //def: create issue if issueNumber=null - otherwise edit existing issue
  //assert: database is initialized & everything TodoClass asserts
  //return: issue id if api succeeds - null on failure
  @override
  Future<int?> uploadIssue({required Todo todo, required Config config}) async {
    assert(isInitialized());

    ///create new issue
    int? issueNumber = todo.issueNumber;
    if (issueNumber == null) {
      final IssueRequest createIssue = IssueRequest(
        title: todo.title,
        body: '',
        labels: [config.issueLabel],
      );
      late final Issue issue;
      try {
        issue = await gitHub.issues.create(repo!, createIssue);
      }
      //on api error
      catch (_) {
        return null;
      }
      issueNumber = issue
          .number; //do not set todoIssueNumber here - bad practice setting is here
      //test if upload was successful
      if (issue.id == 0) {
        return null;
      }
    }

    ///upload files
    String content = todo.body;
    for (final TodoFile todoFile in todo.files) {
      final String filename = getFilenameFromPath(todoFile.content.path);

      ///upload
      final String githubFilePath =
          '${config.issueFileDirPath}/issue_$issueNumber/$filename';
      final String? url = await uploadFile(
        filePath: githubFilePath,
        uploadFile: todoFile.content,
        commitMsg:
            config.customCommitMsg ?? 'issue $issueNumber: add $filename ',
      );

      ///if upload failed
      if (url == null) {
        return null;
      }

      ///add url to issue content
      else {
        if (todoFile.getFileType() == FileType.picture) {
          //to display pictures embedded in github issues a special format is needed: ![](url)
          final String relativeIssuePictureLink =
              '![$githubFilePath]($url?raw=true)';
          content = '$content\n$relativeIssuePictureLink';
        } else if (todoFile.getFileType() != FileType.other) {
          final String relativeIssueVideoLink =
              '[$githubFilePath]($url?raw=true)';
          content = '$content\n$relativeIssueVideoLink';
        }
      }
    }

    ///update issue with files
    final IssueRequest newIssueRequest =
        IssueRequest(title: todo.title, body: content);
    late final Issue issue;
    try {
      issue = await gitHub.issues.edit(repo!, issueNumber, newIssueRequest);
    }
    //on api error
    catch (_) {
      return null;
    }
    //test if update was successful
    if (issue.id == 0) {
      return null;
    }
    return issueNumber;
  }

  //def: solves issue (/set issue to closed)
  //assert: database is initialized & issueNumber is > 0
  //return: true if api succeeds - false on failure
  @override
  Future<bool> solveIssue({required int issueNumber}) async {
    assert(isInitialized());
    assert(issueNumber > 0);

    ///solve issue (/set issue to closed)
    final IssueRequest newIssueRequest = IssueRequest(state: 'closed');
    late final Issue issue;
    try {
      issue = await gitHub.issues.edit(repo!, issueNumber, newIssueRequest);
    }
    //on api error
    catch (_) {
      return false;
    }

    ///test if edit was successful
    return issue.id != 0;
  }
}
