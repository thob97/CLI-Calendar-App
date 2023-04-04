import 'package:cli_calendar_app/pages/calendarPage.dart';
import 'package:cli_calendar_app/services/database/database_proxy.dart';
import 'package:cli_calendar_app/services/database/mocked_database.dart';
import 'package:cli_calendar_app/services/notification/notification_service.dart';
import 'package:cli_calendar_app/services/persistent_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:timezone/data/latest.dart' as tz;

enum PageState {
  calendarMonth,
  calendarDay,
  todoView,
  todoNew,
  settings,
}

Future<void> main() async {
  //to ensure everything before MyApp is initialized/runnable
  WidgetsFlutterBinding.ensureInitialized();

  ///load data from persistent storage
  final PersistentStorage storage = await PersistentStorage().init();
  final String? token = storage.getToken();
  final String? repoPath = storage.getRepoPath();
  final String? configPath = storage.getConfigPath();

  ///init database
  final DatabaseProxy database = DatabaseProxy(database: MockedDatabase());
  if (token != null && repoPath != null && configPath != null) {
    await database.init(
      token: token,
      repoName: repoPath,
      dbConfigPath: configPath,
    );
  }

  ///init notifications
  NotificationService().initNotification();
  tz.initializeTimeZones();

  ///runApp with storage&database as singelton
  runApp(
    Provider<DatabaseProxy>(
      create: (_) => database,
      child: Provider<PersistentStorage>(
        create: (_) => storage,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ///-----APP-----
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CalendarPage(),
    );
  }
}

//
//
//
//
//
///-----AppBar-----
class ListeningAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ListeningAppBar({
    super.key,
    required this.calenderViewController,
    required this.pageStateNotifier,
  });

  final ValueNotifier<PageState> pageStateNotifier;
  final CalendarController calenderViewController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: pageStateNotifier,
      builder: (_, PageState state, ___) {
        return AppBar(
          title: _decideTitle(state),
          leading: _decideSuffixButton(state),
          actions: _decidePrefixButton(state),
        );
      },
    );
  }

  ///-----WIDGETS-----
  Text _decideTitle(PageState state) {
    switch (state) {
      case PageState.calendarDay:
      case PageState.calendarMonth:
        return const Text('Calendar');
      case PageState.todoView:
      case PageState.todoNew:
        return const Text('Todo');
      case PageState.settings:
        return const Text('Settings');
    }
  }

  Widget? _decideSuffixButton(PageState state) {
    switch (state) {
      case PageState.calendarDay:
      case PageState.todoView:
      case PageState.settings:
        return _backButton();
      case PageState.todoNew:
        return _abortButton();
      case PageState.calendarMonth:
        return null;
    }
  }

  List<Widget>? _decidePrefixButton(PageState state) {
    switch (state) {
      case PageState.calendarDay:
      case PageState.calendarMonth:
      case PageState.todoView:
        return [_settingsButton()];
      case PageState.todoNew:
        return [_acceptButton()];
      case PageState.settings:
        return null;
    }
  }

  IconButton _backButton() {
    return IconButton(
      onPressed: _onPressedBackButton,
      icon: const Icon(Icons.arrow_back_ios),
    );
  }

  IconButton _abortButton() {
    return IconButton(
      onPressed: _onPressedAbortButton,
      icon: const Icon(Icons.cancel_outlined),
    );
  }

  IconButton _settingsButton() {
    return IconButton(
      onPressed: _onPressedSettingsButton,
      icon: const Icon(Icons.settings_outlined),
    );
  }

  IconButton _acceptButton() {
    return IconButton(
      onPressed: _onPressedAcceptButton,
      icon: const Icon(Icons.check_outlined),
    );
  }

  ///-----FUNCTIONS-----
  @override //use system standard defined height for appbar
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  //onPressed functions:
  void _onPressedBackButton() {
    //change calendar.view to month.view
    calenderViewController.view = CalendarView.month;
    pageStateNotifier.value = PageState.calendarMonth;
  }

  void _onPressedAbortButton() {
    //todo show notificationgs
    pageStateNotifier.value = PageState.calendarMonth;
  }

  void _onPressedSettingsButton() {
    pageStateNotifier.value = PageState.settings;
  }

  void _onPressedAcceptButton() {
    //todo upload todo
    pageStateNotifier.value = PageState.todoView;
  }
}

//
//
//
//
//
///-----BottomNavBar-----
class ListeningBotNavBar extends StatelessWidget {
  const ListeningBotNavBar({super.key, required this.pageStateNotifier});

  final ValueNotifier<PageState> pageStateNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: pageStateNotifier,
      builder: (_, PageState pageState, ___) {
        return BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _decideMainButton(pageState),
              _decideSubButton(pageState),
            ],
          ),
        );
      },
    );
  }

  ///-----WIDGETS-----
  Widget _decideMainButton(PageState pageState) {
    if (pageState != PageState.settings) {
      return _newTodoButton();
    } else {
      return _autoSetupButton();
    }
  }

  Widget _decideSubButton(PageState pageState) {
    switch (pageState) {
      case PageState.calendarDay:
      case PageState.calendarMonth:
        return _showTodoButton();
      case PageState.todoView:
      case PageState.todoNew:
      case PageState.settings:
        return const SizedBox.shrink();
    }
  }

  Widget _newTodoButton() {
    return CupertinoButton(
      onPressed: onNewTodo,
      child: Row(
        children: const [
          Icon(Icons.add_circle),
          SizedBox(width: 5),
          Text(
            'New Issue',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              //fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _showTodoButton() {
    return CupertinoButton(
      onPressed: onShowTodos,
      child: const Text('Show Issues'),
    );
  }

  Widget _autoSetupButton() {
    return CupertinoButton(
      onPressed: onAutoSetup,
      child: Row(
        children: const [
          Icon(Icons.add_circle),
          SizedBox(width: 5),
          Text(
            'Auto Setup',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              //fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  ///-----STYLE-----
  ///-----FUNCTIONS-----
  void onAutoSetup() {}

  void onNewTodo() {
    pageStateNotifier.value = PageState.todoNew;
  }

  void onShowTodos() {
    pageStateNotifier.value = PageState.todoView;
  }
}
