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
  const AutoSetupButton(
      {super.key, required this.isDisabled, required this.onPressed});

  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MainButton(
      text: 'Auto Setup',
      onPressed: () => _showAlert(context),
      icon: Icons.refresh,
      isDisabled: isDisabled,
    );
  }

  void _showAlert(BuildContext context) {
    showDialog(
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
              },
              child: const Text('Abort'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                onPressed();
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

class NewTodoButton extends StatelessWidget {
  const NewTodoButton(
      {super.key, required this.isDisabled, required this.onPressed});

  final bool isDisabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MainButton(
      text: 'Create a Todo',
      icon: Icons.add_circle,
      onPressed: onPressed,
      isDisabled: isDisabled,
    );
  }
}

class MainButton extends StatelessWidget {
  const MainButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
    required this.isDisabled,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1,
      child: CupertinoButton(
        onPressed: isDisabled ? null : onPressed,
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 5),
            Text(
              text,
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
}

class ShowTodosButton extends StatelessWidget {
  const ShowTodosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SubButton(text: 'Show todos', onPressed: () => _onPressed(context));
  }

  //open todoListPage page
  void _onPressed(BuildContext context) {
    Navigator.push(
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
