import 'dart:io';

import 'package:cli_calendar_app/pages/calendarPage.dart';
import 'package:cli_calendar_app/pages/filePage.dart';
import 'package:cli_calendar_app/services/database/database_proxy.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';
import 'package:cli_calendar_app/widgets/appbar.dart';
import 'package:cli_calendar_app/widgets/bottomNavBar.dart';
import 'package:cli_calendar_app/widgets/ios_refresh.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../model/todo.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key, required this.isCreatingNewTodo});

  final bool isCreatingNewTodo;

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  ///-----INIT-----
  late final DatabaseProxy database;
  late Future<List<Todo>?> futureTodos;
  List<Todo>? todos;

  @override
  void initState() {
    //get database
    database = Provider.of<DatabaseProxy>(context, listen: false);
    futureTodos = initIssueList();
    super.initState();
  }

  Future<List<Todo>?> initIssueList() async {
    ///if logged in/initialized
    if (database.isInitialized()) {
      ///get config
      final Config? config = await database.getConfig();
      //onError
      if (config == null) return [];

      ///get calendar file
      final List<Todo>? result =
          await database.getNumOpenIssues(config.maxDisplayedIssues);
      //onError
      if (result == null) return [];

      return result;
    }

    ///not logged in/initialized
    else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TodoListAppBar(),
      bottomNavigationBar: TodoListNavBar(
        onPressed: onCreateTodo,
        newTodoButtonDisabled: !database.isInitialized(),
      ),
      body: _futureListTodo(),
    );
  }

  ///-----Widgets-----
  Widget _futureListTodo() {
    return FutureBuilder(
      future: futureTodos,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return _loadingTodoList();
          default:
            if (snapshot.hasError) {
              return const Center(child: Text('Something went wrong'));
            } else {
              if (snapshot.data == null) {
                return Center(
                    child: Text('Once logged in you can add todos here'));
              } else {
                todos = snapshot.data;
                return iOSRefresh(
                  onRefresh: onRefresh,
                  child: TodoList(
                    animatedListKey: animatedListKey,
                    todoList: todos!,
                    onSolve: onSolveTodo,
                    onSubmit: onUpdateTodo,
                  ),
                );
              }
            }
        }
      },
    );
  }

  Widget _loadingTodoList() {
    return Stack(
      children: [
        TodoList(
          //show todos, on first loading will be empty, but on refresh it will
          // show the old todos and thus show a smoother loading experience
          // else while loading all todos will be removed and than added
          todoList: todos ?? [],
          onSolve: (_) {}, onSubmit: (_, __, ___) => Future(() => null),
        ),
        //only display the linearProgress on first load
        if (todos == null) const LinearProgressIndicator()
      ],
    );
  }

  ///-----Functions-----
  //todo auto scroll to new todo
  //global key so that add and remove functions can be accessed of animatedlist
  final GlobalKey<AnimatedListState> animatedListKey = GlobalKey();

  Future<void> onCreateTodo() async {
    ///wait until first load is completed
    await futureTodos;

    final int newIndex = todos!.length;

    ///create newTodo
    final newTodo = Todo(title: 'New Reminder', body: '', files: []);

    ///add to db
    final Config? config = await database.getConfig();
    //todo handle error
    if (config == null) {}
    final int? issueNumber =
        await database.uploadIssue(todo: newTodo, config: config!);
    //todo handle error
    if (issueNumber == null) {}
    newTodo.issueNumber = issueNumber;

    ///add to paraList (important else animated buggy)
    todos!.insert(newIndex, newTodo);

    ///add to AnimatedWidgetList
    animatedListKey.currentState!.insertItem(newIndex);
  }

  //todo wait until other solves are completed -> else fast solving leads to overflow
  Future<void> onSolveTodo(int index) async {
    ///remove from db
    final removedItem = todos![index];

    final bool success =
        await database.solveIssue(issueNumber: removedItem.issueNumber!);
    //todo handle error
    if (!success) {}

    ///remove from paraList (important else animated buggy)
    todos!.remove(removedItem);

    ///remove from AnimatedWidgetList
    //wait for checkmark animation
    Future.delayed(const Duration(milliseconds: 300), () {
      animatedListKey.currentState!.removeItem(index,
          //item which will be displayed when removed (animated)
          (context, animation) {
        return TodoItem(
          content: removedItem,
          animation: animation,
          onSolved: () => {},
          onSubmit: (_, __) => Future(() => null),
        );
      });
    });
  }

  Future<void> onUpdateTodo(int index, String title, String desc) async {
    ///change local list
    todos![index].title = title;
    todos![index].body = desc;

    ///change in db
    final Config? config = await database.getConfig();
    //todo handle error
    if (config == null) {}
    final int? issueNumber =
        await database.uploadIssue(todo: todos![index], config: config!);
    //todo handle error
    if (issueNumber == null) {}
  }

  Future<void> onRefresh() async {
    database.clearProxyData();
    todos = await initIssueList();
    setState(() {});
  }
}

//
//
//
//
///-----TodoList-----
class TodoList extends StatelessWidget {
  const TodoList(
      {super.key,
      required this.todoList,
      required this.onSolve,
      this.animatedListKey,
      required this.onSubmit});

  final List<Todo> todoList;
  final GlobalKey? animatedListKey;
  final Function(int index) onSolve;
  final Future<void> Function(int index, String title, String desc) onSubmit;

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: animatedListKey,
      shrinkWrap: true,
      //never scrolling is handled by parent
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: todoList.length,
      itemBuilder: (context, index, animation) {
        return TodoItem(
          content: todoList[index],
          animation: animation,
          onSolved: () => onSolve(index),
          onSubmit: (title, desc) => onSubmit(index, title, desc),
        );
      },
    );
  }
}

//
//
//
//
///-----TodoItem-----
class TodoItem extends StatelessWidget {
  TodoItem({
    super.key,
    required this.content,
    required this.animation,
    required this.onSolved,
    required this.onSubmit,
  });

  final Todo content;
  final Animation<double> animation;
  final VoidCallback onSolved;
  final Future<void> Function(String title, String desc) onSubmit;

  @override
  Widget build(BuildContext context) {
    //animation for animatedList
    return SizeTransition(
      key: ValueKey(content),
      sizeFactor: animation,
      child: _listTile(),
    );
  }

  Widget _listTile() {
    //CupertinoListSection.insetGrouped for style
    return CupertinoListSection.insetGrouped(
      children: [
        ListTile(
          title: _textFields(),
          leading: _checkmark(),
          subtitle: _data(),
        )
      ],
    );
  }

  ///functions
  final ValueNotifier<bool> notifieCheckboxLoading = ValueNotifier(false);

  Future<void> _onSubmit(String title, String desc) async {
    notifieCheckboxLoading.value = true;
    await onSubmit(title, desc);
    notifieCheckboxLoading.value = false;
  }

  ///widgets

  Widget _textFields() {
    return TodoTextFields(
      titleController: TextEditingController(),
      initialTitleValue: content.title,
      descController: TextEditingController(),
      initialDescValue: content.body,
      onSubmit: _onSubmit,
    );
  }

  Widget? _data() {
    ///files given
    if (content.files.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //_getDescription(),
          const SizedBox(height: 10),
          DataGridview(todoFiles: content.files),
          const SizedBox(height: 5),
        ],
      );
    } else {
      return null;
    }
  }

  Widget _checkmark() {
    return ValueListenableBuilder(
      valueListenable: notifieCheckboxLoading,
      builder: (_, bool isLoading, ___) {
        return isLoading
            ? const CupertinoActivityIndicator()
            : SizedBox(
                //use height and width of CupertinoActivityIndicator
                // so that transition on swap looks better
                height: 24,
                width: 24,
                child: MyCheckBox(onPressed: onSolved),
              );
      },
    );
  }
}

//
//
//
//
///-----TextFields-----
class TodoTextFields extends StatefulWidget {
  const TodoTextFields(
      {super.key,
      required this.titleController,
      required this.initialTitleValue,
      required this.descController,
      required this.initialDescValue,
      required this.onSubmit});

  final TextEditingController titleController;
  final TextEditingController descController;
  final String initialTitleValue;
  final String initialDescValue;
  final Function(String title, String desc) onSubmit;

  @override
  State<TodoTextFields> createState() => _TodoTextFieldsState();
}

class _TodoTextFieldsState extends State<TodoTextFields> {
  final FocusNode _focusTitle = FocusNode();
  final FocusNode _focusDesc = FocusNode();
  bool focused = false;
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    titleController.text = widget.initialTitleValue;
    descController.text = widget.initialDescValue;
    _focusTitle.addListener(_onFocusChange);
    _focusDesc.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _focusTitle.removeListener(_onFocusChange);
    _focusDesc.removeListener(_onFocusChange);
    _focusTitle.dispose();
  }

  void _onFocusChange() {
    setState(() {
      focused = _focusTitle.hasFocus || _focusDesc.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _getTitle(),
            if (focused || descController.text.isNotEmpty) _getDescription(),
          ],
        ),
      ],
    );
  }

  Widget _getTitle() {
    return TextField(
      focusNode: _focusTitle,
      controller: titleController,
      maxLength: 100,
      //todo add to config
      textInputAction: TextInputAction.send,
      onSubmitted: _onSubmit,
      decoration: InputDecoration(
        counterText: focused ? null : '',
        border: InputBorder.none,
        isDense: false,
      ),
    );
  }

  Widget _getDescription() {
    return TextField(
      focusNode: _focusDesc,
      controller: descController,
      textInputAction: TextInputAction.send,
      onSubmitted: _onSubmit,

      ///style
      scrollPhysics: const NeverScrollableScrollPhysics(),
      maxLines: null,
      maxLength: 500,
      //todo add to config
      minLines: 1,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: CupertinoColors.systemGrey,
        height: 1.2,
      ),
      decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          counterText: focused ? null : '',
          hintText: 'Description'),
    );
  }

  void _onSubmit(String input) {
    widget.onSubmit(titleController.text, descController.text);
  }
}

//
//
//
//
///-----DataGridview-----
class DataGridview extends StatelessWidget {
  const DataGridview({super.key, required this.todoFiles});

  final List<TodoFile> todoFiles;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      //todo add to config
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 80,
        childAspectRatio: 1,
      ),
      //todo add to config
      itemCount: todoFiles.length,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () => onPressed(context, index),
          child: _decideFileType(todoFiles[index]),
        );
      },
    );
  }

  ///Widgets
  Widget _decideFileType(TodoFile file) {
    switch (file.getFileType()) {
      ///picture
      case FileType.picture:
        return Image.file(
          file.content,
          fit: BoxFit.cover,
        );

      ///video & audio
      case FileType.videoOrAudio:
        return MiniVideoPlayer(file: file.content);

      ///other
      case FileType.other:
        return const ColoredBox(
          color: CupertinoColors.lightBackgroundGray,
          child: Icon(CupertinoIcons.doc),
        );
    }
  }

  ///Functions
  void onPressed(BuildContext context, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => FilePage(
          fileList: todoFiles,
          initialIndex: index,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

//
//
//
//
///-----VideoPlayer-----
class MiniVideoPlayer extends StatefulWidget {
  const MiniVideoPlayer({super.key, required this.file});

  final File file;

  @override
  State<MiniVideoPlayer> createState() => _MiniVideoPlayerState();
}

class _MiniVideoPlayerState extends State<MiniVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      //..addListener(() =>setState(() {}));
      //..setLooping(true)
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized ? _videoPlayer() : _loadingWidget();
  }

  //purpose: adds play button over it
  Widget _videoPlayer() {
    //todo use fitted box to display mini video, but throws error
    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_controller),
        const Icon(CupertinoIcons.play_circle_fill,
            size: 30, color: CupertinoColors.secondaryLabel)
      ],
    );
  }

  Widget _loadingWidget() {
    return const CupertinoActivityIndicator();
  }
}

//
//
//
//
///-----Ceckbox-----
class MyCheckBox extends StatefulWidget {
  const MyCheckBox({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<MyCheckBox> createState() => _MyCheckBoxState();
}

class _MyCheckBoxState extends State<MyCheckBox> {
  bool state = false;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      shape: const CircleBorder(),
      value: state,
      onChanged: _onChanged,
    );
  }

  void _onChanged(bool? value) {
    setState(() {
      state = true;
    });
    widget.onPressed();
  }
}

//
//
//
//
//changes buttons when creating a newTodo
///-----AppBar-----
class TodoListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TodoListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return MyAppBar(
      title: 'Settings',
      followingButton: const MySettingsButton(),
      leadingButton: MyBackButton(onPressed: () => onBackButton(context)),
    );
  }

  ///-----FUNCTIONS-----
  @override //use system standard defined height for appbar
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void onBackButton(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const CalendarPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
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

  final Future<void> Function() onPressed;
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
