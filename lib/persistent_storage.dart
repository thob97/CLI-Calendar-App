import 'package:shared_preferences/shared_preferences.dart';

//def: initially loads the values from the storage
//  afterwards it will save the values as variables
//  -> the value data can be gotten without loading/waiting/future
class PersistentStorage {
  late String? _token;
  late String? _repoPath;
  late String? _configPath;

  ///-----init-----
  bool wasInitialized = false;

  Future<PersistentStorage> init() async {
    await _loadToken();
    await _loadRepoPath();
    await _loadConfigPath();
    wasInitialized = true;
    return this;
  }

  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return _token = prefs.getString('token');
  }

  Future<String?> _loadRepoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return _repoPath = prefs.getString('repoPath');
  }

  Future<String?> _loadConfigPath() async {
    final prefs = await SharedPreferences.getInstance();
    return _configPath = prefs.getString('configPath');
  }

  ///-----save-----
  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> saveRepoPath(String path) async {
    _repoPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('repoPath', path);
  }

  Future<void> saveConfigPath(String path) async {
    _configPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('configPath', path);
  }

  ///-----get-----
  String? getToken() {
    assert(wasInitialized);
    return _token;
  }

  String? getRepoPath() {
    assert(wasInitialized);
    return _repoPath;
  }

  String? getConfigPath() {
    assert(wasInitialized);
    return _configPath;
  }
}
