import 'dart:math';

import 'package:cli_calendar_app/persistent_data.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({
    super.key,
    required this.token,
    required this.configPath,
    required this.repoPath,
  });

  final String token;
  final String configPath;
  final String repoPath;

  ///-----FUNCTIONS-----
  Future<bool> mockedLogin(String login) async {
    await saveTokenToPersistentStorage(login);
    return Future.delayed(const Duration(seconds: 1))
        .then((value) => Random().nextBool());
  }

  Future<bool> mockedRepo(String repoPath) async {
    await saveRepoPathToPersistentStorage(repoPath);
    return Future.delayed(const Duration(seconds: 1))
        .then((value) => Random().nextBool());
  }

  Future<bool> mockedConfig(String configPath) async {
    await saveConfigPathToPersistentStorage(configPath);
    return Future.delayed(const Duration(seconds: 1))
        .then((value) => Random().nextBool());
  }

  ///-----PAGE-----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Today",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: "Todolist"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings")
        ],
        currentIndex: 2,
      ),
      body: body(context),
    );
  }

  ///-----BODY-----
  Widget body(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        loginTextField(),
        repoTextField(),
        configTextField(),
      ],
    );
  }

  ///-----WIDGETS-----
  //
  final loginFormKey = GlobalKey<FormState>();
  ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
  Widget loginTextField() {
    return CustomFutureTextFormField(
      formKey: loginFormKey,
      validationSuccessText: 'successText',
      validationErrorText: 'errorText',
      validationIsRetryText: '',
      hintText: 'hintText',
      labelText: 'labelText',
      prefixIcon: Icons.person,
      initialValue: token,
      getFutureValidation: mockedLogin,
      enabled: true,
      onSubmit: (success) => isLoggedIn.value = success,
    );
  }

  //
  final repoFormKey = GlobalKey<FormState>();
  Widget repoTextField() {
    return ValueListenableBuilder(
      valueListenable: isLoggedIn,
      builder: (BuildContext context, bool notifierValue, Widget? child) {
        return CustomFutureTextFormField(
          formKey: repoFormKey,
          validationSuccessText: 'successText',
          validationErrorText: 'errorText',
          validationIsRetryText: 'login changed, please retry repo',
          hintText: 'hintText',
          labelText: 'labelText',
          prefixIcon: Icons.home,
          initialValue: repoPath,
          getFutureValidation: mockedRepo,
          enabled: notifierValue,
          onSubmit: (success) => repoPathIsValid.value = success,
        );
      },
    );
  }

  //
  final configFormKey = GlobalKey<FormState>();
  ValueNotifier<bool> repoPathIsValid = ValueNotifier(false);
  Widget configTextField() {
    return ValueListenableBuilder(
      valueListenable: repoPathIsValid,
      builder: (BuildContext context, bool notifierValue, Widget? child) {
        return CustomFutureTextFormField(
          formKey: configFormKey,
          validationSuccessText: 'successText',
          validationErrorText: 'errorText',
          validationIsRetryText: 'repo changed, please retry config',
          hintText: 'hintText',
          labelText: 'labelText',
          prefixIcon: Icons.settings,
          initialValue: configPath,
          getFutureValidation: mockedConfig,
          enabled: notifierValue,
          onSubmit: (_) {},
        );
      },
    );
  }
}

//
//
//
//
//
///-----Textfield-----
class CustomFutureTextFormField extends StatefulWidget {
  const CustomFutureTextFormField({
    required this.formKey,
    required this.initialValue,
    required this.hintText,
    required this.labelText,
    required this.enabled,
    required this.prefixIcon,
    required this.validationSuccessText,
    required this.validationErrorText,
    required this.validationIsRetryText,
    required this.getFutureValidation,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool enabled;
  final String validationSuccessText;
  final String validationErrorText;
  final String validationIsRetryText;
  final String hintText;
  final String labelText;
  final IconData prefixIcon;
  final String? initialValue;
  final Future<bool> Function(String) getFutureValidation;
  final void Function(bool) onSubmit;

  @override
  State<CustomFutureTextFormField> createState() =>
      _CustomFutureTextFormFieldState();
}

class _CustomFutureTextFormFieldState extends State<CustomFutureTextFormField> {
  late Future<bool?> futureValidation;

  @override
  void initState() {
    ///set userInput to initial value
    userInput = widget.initialValue;

    ///initiate future validation
    if (isDisabled() || userInput == null) {
      futureValidation = Future.delayed(Duration.zero).then((value) => false);
    }
    //try to validate if a initial value is given
    else {
      futureValidation = widget.getFutureValidation(userInput!);
    }

    super.initState();
  }

  //def: shows the text-field loading while waiting for getFutureValidation
  //return: on success shows the validated text-field
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureValidation,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return customTextField(isLoading: true);
          default:
            return snapshot.hasError
                ? const Center(child: Text('Something went wrong'))
                : customTextField(validation: snapshot.data);
        }
      },
    );
  }

  ///-----WIDGETS-----
  Widget customTextField({bool? validation, bool isLoading = false}) {
    afterBuild(validation);
    return Form(
      key: widget.formKey,
      child: TextFormField(
        enabled: widget.enabled,
        initialValue: widget.initialValue,
        textInputAction: TextInputAction.send,
        validator: (_) =>
            validator(validated: validation, isLoading: isLoading),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: widget.hintText,
          //filled: true,
          //fillColor: validate ? green : red,
          labelText: widget.labelText,
          prefixIcon: prefixIcon(validated: validation, isLoading: isLoading),
          suffixIcon: suffixIcon(validated: validation, isLoading: isLoading),
          errorStyle:
              undersideTextStyle(validated: validation, isLoading: isLoading),
        ),
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }

  ///-----FUNCTIONS-----
  void onFieldSubmitted(String userInput) {
    setState(() {
      ///update text
      this.userInput = userInput;

      ///fetch new validation
      //return false on empty input
      if (userInput.isEmpty) {
        futureValidation = Future.delayed(Duration.zero).then((value) => false);
      }
      //if no empty input => validate
      else {
        futureValidation = widget.getFutureValidation(userInput);
      }
    });
  }

  //
  //
  //todo: ab hier: refactor-> (isRetry style und getter überdenken)
  //todo: remember last state -> don't isRetry() on every new device start
  //todo: add retry on upswipe
  void afterBuild(bool? validation) {
    ///at the end of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bool? success = validation;
      if (isDisabled() || isRetry()) {
        success = false;
      }

      ///run onValidation: if validation updated + its not Retry + its enabled
      if (success != null) {
        widget.onSubmit(success);
      }

      ///update futureValidation on new value
      if (isRetry()) {
        setState(() {
          futureValidation = widget.getFutureValidation(userInput!);
        });
      }

      ///update prevStateWasDisabled
      prevStateWasDisabled = isDisabled();
    });
  }

  ///-----HELPERS-----
  //states textField can be in
  bool isDisabled() => !widget.enabled;

  bool isActive({required bool? validated}) => validated == null;

  bool isSuccess({required bool? validated}) => validated != null && validated;

  bool isError({required bool? validated}) => validated != null && !validated;

  //+bool isLoading
  bool prevStateWasDisabled = false;
  late String? userInput; //for isRetry() test
  //retry if it was previously disabled, its now enabled, and there is already userInput
  bool isRetry() => !isDisabled() && prevStateWasDisabled && userInput != null;

  ///-----STYLE-----
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color isRetryColor = Colors.amber;

  TextStyle? undersideTextStyle({
    required bool? validated,
    required bool isLoading,
  }) {
    ///no validation
    if (isDisabled() || isActive(validated: validated) || isLoading) {
      return null;
    }

    ///isRetry
    if (isRetry()) {
      return const TextStyle(color: isRetryColor);
    }

    ///success
    else if (isSuccess(validated: validated)) {
      return const TextStyle(color: successColor);
    }

    ///error
    else {
      return const TextStyle(color: errorColor);
    }
  }

  String? validator({required bool? validated, required bool isLoading}) {
    ///no validation
    //not yet validated (no input tested yet) or is being tested right now
    if (isDisabled() || isActive(validated: validated) || isLoading) {
      return null;
    }

    ///isRetry
    if (isRetry()) {
      return widget.validationIsRetryText;
    }

    ///success
    else if (isSuccess(validated: validated)) {
      return widget.validationSuccessText;
    }

    ///error
    else {
      return widget.validationErrorText;
    }
  }

  Widget? prefixIcon({required bool? validated, required bool isLoading}) {
    late final Color? iconColor;

    ///no validation
    if (isDisabled() || isActive(validated: validated) || isLoading) {
      iconColor = null;
    } else if (isRetry()) {
      iconColor = isRetryColor;
    }

    ///success
    else if (isSuccess(validated: validated)) {
      iconColor = successColor;
    }

    ///error
    else {
      iconColor = errorColor;
    }
    return Icon(widget.prefixIcon, color: iconColor);
  }

  Widget? suffixIcon({required bool? validated, required bool isLoading}) {
    ///loading
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    ///no validation
    if (isDisabled() || isActive(validated: validated)) {
      return null;
    }

    ///retry
    else if (isRetry()) {
      return const Icon(Icons.refresh, color: isRetryColor);
    }

    ///success
    else if (isSuccess(validated: validated)) {
      return const Icon(
        Icons.check_outlined,
        color: successColor,
      );
    }

    ///error
    else {
      return const Icon(Icons.close_outlined, color: errorColor);
    }
  }
}