import 'package:cli_calendar_app/pages/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///-----AppBar-----
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({
    super.key,
    required this.title,
    this.leadingButton,
    this.followingButton,
  });

  final String title;
  final Widget? leadingButton;
  final Widget? followingButton;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leadingButton,
      actions: followingButton == null ? [] : [followingButton!],
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
///-----BUTTONS-----
class MyBackButton extends StatelessWidget {
  const MyBackButton(
      {super.key, required this.onPressed, this.isDisabled = false});

  final VoidCallback onPressed;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    //doesn't change color when disabled -> used because it might flicker otherwise in settings
    return RawMaterialButton(
      onPressed: isDisabled ? null : onPressed,
      child: const Icon(Icons.arrow_back_ios),
    );
  }
}

class MyAbortButton extends StatelessWidget {
  const MyAbortButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showAlert(context),
      icon: const Icon(Icons.cancel_outlined),
    );
  }

  void _showAlert(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return CupertinoAlertDialog(
          title: const Text('Dismiss new Todos?'),
          content: const Text('Do you want to dismiss the created new todos?'),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                onPressed();
              },
              child: const Text('Yes'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('no'),
            ),
          ],
        );
      },
    );
  }
}

class MySettingsButton extends StatelessWidget {
  const MySettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _onPressed(context),
      icon: const Icon(Icons.settings_outlined),
    );
  }

  //open settings page
  void _onPressed(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => const SettingsPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class MyAcceptButton extends StatelessWidget {
  const MyAcceptButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.check_circle_outline),
    );
  }
}
