import 'package:shared_preferences/shared_preferences.dart';

//def: initially loads the values from the storage
//  afterwards it will save the values as variables
//  -> the value data can be gotten without loading/waiting/future
class PersistentStorage {
  late String? _token;
  late String? _repoPath;
  late String? _configPath;
  late bool? _lastLoginValid;
  late bool? _lastRepoValid;
  late bool? _lastConfigValid;

  ///-----init-----
  bool wasInitialized = false;

  Future<PersistentStorage> init() async {
    await _loadToken();
    await _loadRepoPath();
    await _loadConfigPath();
    await _loadLoginState();
    await _loadRepoState();
    await _loadConfigState();
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

  Future<bool?> _loadLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return _lastLoginValid = prefs.getBool('loginState');
  }

  Future<bool?> _loadRepoState() async {
    final prefs = await SharedPreferences.getInstance();
    return _lastRepoValid = prefs.getBool('repoState');
  }

  Future<bool?> _loadConfigState() async {
    final prefs = await SharedPreferences.getInstance();
    return _lastConfigValid = prefs.getBool('configState');
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

  Future<void> saveLoginState({required bool success}) async {
    _lastLoginValid = success;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loginState', success);
  }

  Future<void> saveRepoState({required bool success}) async {
    _lastRepoValid = success;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('repoState', success);
  }

  Future<void> saveConfigState({required bool success}) async {
    _lastConfigValid = success;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('configState', success);
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

  bool? getLoginState() {
    assert(wasInitialized);
    return _lastLoginValid;
  }

  bool? getRepoState() {
    assert(wasInitialized);
    return _lastRepoValid;
  }

  bool? getConfigState() {
    assert(wasInitialized);
    return _lastConfigValid;
  }
}
