import 'package:cli_calendar_app/pages/todoListPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///-----BottomNavBar-----
class MyBottomNavBar extends StatelessWidget {
  const MyBottomNavBar({
    super.key,
    required this.mainButton,
    this.subButton,
  });

  final Widget mainButton;
  final Widget? subButton;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          mainButton,
          subButton ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

//
//
//
//
//
///-----Buttons-----
class AutoSetupButton extends StatelessWidget {
  AutoSetupButton(
      {super.key, required this.isDisabled, required this.onPressed});

  final bool isDisabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return MainButton(
      text: 'Auto Setup',
      onPressed: () => _onPressed(context),
      icon: CupertinoIcons.refresh,
      isDisabled: isDisabled,
    );
  }

  //accept so that _onPressed method can wait for database result / load
  bool accept = false;

  Future<void> _showAlert(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text('Auto Setup'),
          content: const Text(
              'This will create a new repo with your GitHub account and set the app settings accordingly, are you sure?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                accept = false;
              },
              child: const Text('Abort'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                accept = true;
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    await _showAlert(context);
    if (accept) {
      await onPressed();
    }
  }
}

class NewTodoButton extends StatelessWidget {
  const NewTodoButton(
      {super.key, required this.isDisabled, required this.onPressed});

  final bool isDisabled;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return MainButton(
      text: 'Create a Todo',
      icon: CupertinoIcons.add_circled_solid,
      onPressed: onPressed,
      isDisabled: isDisabled,
    );
  }
}

class MainButton extends StatefulWidget {
  const MainButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
    required this.isDisabled,
  });

  final String text;
  final IconData icon;
  final Future<void> Function() onPressed;
  final bool isDisabled;

  @override
  State<MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<MainButton> {
  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isDisabled ? 0.5 : 1,
      child: CupertinoButton(
        onPressed: widget.isDisabled ? null : _onPressed,
        child: Row(
          children: [
            //both should have same size so that transition looks better when they change
            if (isLoading)
              const CupertinoActivityIndicator(
                radius: 12,
              )
            else
              Icon(
                widget.icon,
                size: 24,
              ),
            const SizedBox(width: 5),
            Text(
              widget.text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                //fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //change button icon to progressIndicator while loading
  bool isLoading = false;

  Future<void> _onPressed() async {
    setState(() {
      isLoading = true;
    });
    await widget.onPressed();
    setState(() {
      isLoading = false;
    });
  }
}

class ShowTodosButton extends StatelessWidget {
  const ShowTodosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SubButton(text: 'Show todos', onPressed: () => _onPressed(context));
  }

  //open todoListPage page
  void _onPressed(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            const TodoListPage(isCreatingNewTodo: false),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class SubButton extends StatelessWidget {
  const SubButton({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(onPressed: onPressed, child: Text(text));
  }
}
