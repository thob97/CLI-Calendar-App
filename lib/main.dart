import 'package:cli_calendar_app/pages/settings.dart';
import 'package:cli_calendar_app/persistent_data.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  //to ensure everything before MyApp is initialized/runnable
  WidgetsFlutterBinding.ensureInitialized();
  final String configPath = await readConfigPathFromPersistentStorage() ?? '';
  final String repoPath = await readRepoPathFromPersistentStorage() ?? '';
  final String token = await readTokenFromPersistentStorage() ?? '';
  runApp(MyApp(token: token, configPath: configPath, repoPath: repoPath));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.token,
    required this.configPath,
    required this.repoPath,
  });

  ///todo remove variables - instead use path provider
  final String token;
  final String configPath;
  final String repoPath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SettingsPage(
        token: token,
        configPath: configPath,
        repoPath: repoPath,
      ),
    );
  }
}

