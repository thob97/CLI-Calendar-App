import 'package:cli_calendar_app/services/database/database_proxy.dart';
import 'package:cli_calendar_app/widgets/appbar.dart';
import 'package:cli_calendar_app/widgets/bottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key, required this.isCreatingNewTodo});

  final bool isCreatingNewTodo;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  ///-----INIT-----
  late final DatabaseProxy database;
  late final ValueNotifier<bool> appBarListener; //change when creating newTodo
  @override
  void initState() {
    //get database
    database = Provider.of<DatabaseProxy>(context, listen: false);
    //get notifier
    appBarListener = ValueNotifier(widget.isCreatingNewTodo);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TodoListAppBar(
          isCreatingNewTodo: appBarListener,
          onAbort: onAbort,
          onAccept: onAccept),
      bottomNavigationBar: TodoListNavBar(
        onPressed: onNewTodo,
        newTodoButtonDisabled: !database.isInitialized(),
      ),
      body: const Center(
        child: Text('Todolist'),
      ),
    );
  }

  ///-----Functions-----
  void onNewTodo() {
    //notify listeners (appbar)
    appBarListener.value = true;
  }

  void onAbort() {
    appBarListener.value = false;
  }

  void onAccept() {
    appBarListener.value = false;
  }
}

//
//
//
//
//changes buttons when creating a newTodo
///-----AppBar-----
class TodoListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TodoListAppBar({
    super.key,
    required this.isCreatingNewTodo,
    required this.onAbort,
    required this.onAccept,
  });

  //set value notifier to notify appBar
  final ValueNotifier<bool> isCreatingNewTodo;
  final VoidCallback onAbort;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isCreatingNewTodo,
      builder: (_, bool isCreatingNewTodo, ___) {
        return MyAppBar(
          title: 'Todo List',
          followingButton: isCreatingNewTodo
              ? MyAcceptButton(onPressed: onAccept)
              : const MySettingsButton(),
          leadingButton:
              isCreatingNewTodo ? MyAbortButton(onPressed: onAbort) : null,
        );
      },
    );
  }

  ///-----FUNCTIONS-----
  @override //use system standard defined height for appbar
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

//
//
//
//
//
///-----NavBar-----
class TodoListNavBar extends StatelessWidget {
  const TodoListNavBar(
      {super.key,
      required this.onPressed,
      required this.newTodoButtonDisabled});

  final VoidCallback onPressed;
  final bool newTodoButtonDisabled;

  @override
  Widget build(BuildContext context) {
    return MyBottomNavBar(
      mainButton: NewTodoButton(
        isDisabled: newTodoButtonDisabled,
        onPressed: onPressed,
      ),
    );
  }
}
