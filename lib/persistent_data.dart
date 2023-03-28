import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveConfigPathToPersistentStorage(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('configPath', path);
}

Future<void> saveRepoPathToPersistentStorage(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('repoPath', path);
}

Future<void> saveTokenToPersistentStorage(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

Future<String?> readConfigPathFromPersistentStorage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('configPath');
}

Future<String?> readRepoPathFromPersistentStorage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('repoPath');
}

Future<String?> readTokenFromPersistentStorage() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}
