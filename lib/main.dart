import 'package:cli_calendar_app/pages/calendarPage.dart';
import 'package:cli_calendar_app/pages/settings.dart';
import 'package:cli_calendar_app/pages/todoListPage.dart';
import 'package:cli_calendar_app/persistent_data.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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

  ///-----VARIABLES-----
  static const PageState startPage = PageState.settings;

  ///-----APP-----
  @override
  Widget build(BuildContext context) {
    //get calendarController to change the views in calendar widget
    final CalendarController calenderViewController = CalendarController();
    //set value notifier to notify appBar & navBar & getPage()
    final ValueNotifier<PageState> pageStateNotifier = ValueNotifier(startPage);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: ListeningAppBar(
          calenderViewController: calenderViewController,
          pageStateNotifier: pageStateNotifier,
        ),
        bottomNavigationBar: ListeningBotNavBar(
          pageStateNotifier: pageStateNotifier,
          calenderViewController: calenderViewController,
        ),
        body: getPage(calenderViewController, pageStateNotifier),
      ),
    );
  }

  ///-----getPage-----
  Widget getPage(
    CalendarController calenderViewController,
    ValueNotifier<PageState> pageStateNotifier,
  ) {
    return ValueListenableBuilder(
      valueListenable: pageStateNotifier,
      builder: (_, __, ___) {
        switch (pageStateNotifier.value) {
          ///CalendarPage
          case PageState.calendarDay:
          case PageState.calendarMonth:
            return CalendarPage(
              calenderViewController: calenderViewController,
              pageStateNotifier: pageStateNotifier,
            );

          ///CalendarSettings
          case PageState.todoView:
          case PageState.todoNew:
            return const TodoListPage();

          ///CalendarSettings
          case PageState.settings:
            return SettingsPage(
              token: token,
              configPath: configPath,
              repoPath: repoPath,
            );
        }
      },
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
      builder: (_, __, ___) {
        return AppBar(
          title: _title(),
          leading: _suffixButton(),
          actions: _prefixButton(),
        );
      },
    );
  }

  ///-----FUNCTIONS-----
  @override //use system standard defined height for appbar
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  ///-----WIDGETS-----
  Text _title() {
    switch (pageStateNotifier.value) {
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

  Widget? _suffixButton() {
    ///Calender Day View -> Show BackButton
    if (pageStateNotifier.value == PageState.calendarDay) {
      return IconButton(
        onPressed: () {
          //change calendar.view to month.view
          calenderViewController.view = CalendarView.month;
          pageStateNotifier.value = PageState.calendarMonth;
        },
        icon: const Icon(Icons.arrow_back_ios),
      );
    } else {
      return null;
    }
  }

  List<Widget>? _prefixButton() {
    ///-> Add Button
    return [IconButton(onPressed: () {}, icon: const Icon(Icons.add))];
  }
}

//
//
//
//
//
///-----BottomNavBar-----
class ListeningBotNavBar extends StatelessWidget {
  const ListeningBotNavBar({
    super.key,
    required this.pageStateNotifier,
    required this.calenderViewController,
  });

  final ValueNotifier<PageState> pageStateNotifier;
  final CalendarController calenderViewController;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: pageStateNotifier,
      builder: (_, __, ___) {
        return BottomNavigationBar(
          currentIndex: _getCurrentIndex(),
          onTap: _onTabNavigate,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Today',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Todolist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            )
          ],
        );
      },
    );
  }

  ///-----FUNCTIONS-----
  int _getCurrentIndex() {
    switch (pageStateNotifier.value) {
      case PageState.calendarDay:
      case PageState.calendarMonth:
        return 0;
      case PageState.todoView:
      case PageState.todoNew:
        return 1;
      case PageState.settings:
        return 2;
    }
  }

  void _onTabNavigate(int index) {
    switch (index) {
      ///CalendarView
      case 0:

        ///if already in calendar view -> don't reload -> just update view to date:now
        if (pageStateNotifier.value == PageState.calendarDay ||
            pageStateNotifier.value == PageState.calendarMonth) {
          //changes to month view
          calenderViewController.view = CalendarView.month;
          //displays today
          calenderViewController.displayDate = DateTime.now();
          //displays today
          calenderViewController.selectedDate = DateTime.now();
          pageStateNotifier.value = PageState.calendarMonth;
        }

        ///in different view ->
        else {
          pageStateNotifier.value = PageState.calendarMonth;
        }
        break;

      ///TodoListView
      case 1:
        pageStateNotifier.value = PageState.todoView;
        break;

      ///SettingsView
      case 2:
        pageStateNotifier.value = PageState.settings;
        break;

      ///none
      default:
        break;
    }
  }
}
