import 'package:cli_calendar_app/database/database_strategy.dart';
import 'package:cli_calendar_app/persistent_storage.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key, required this.database, required this.storage});

  final PersistentStorage storage;
  final DatabaseStrategy database;

  ///-----FUNCTIONS-----
  Future<bool> login(String login) async {
    await storage.saveToken(login);
    final bool success = await database.login(login) != null;
    await storage.saveLoginState(success: success);
    return success;
  }

  Future<bool> setRepo(String repoName) async {
    await storage.saveRepoPath(repoName);
    final bool success = await database.setRepo(repoName: repoName);
    await storage.saveRepoState(success: success);
    return success;
  }

  Future<bool> setConfig(String dbConfigPath) async {
    await storage.saveConfigPath(dbConfigPath);
    final bool success = await database.setConfig(dbConfigPath: dbConfigPath);
    await storage.saveConfigState(success: success);
    return success;
  }

  ///-----PAGE-----
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      //todo add refresh
      onRefresh: () => Future(() => null),
      child: ListView(
        children: [
          loginTextField(),
          repoTextField(),
          configTextField(),
          //todo add username + api + time
        ],
      ),
    );
  }

  ///-----WIDGETS-----
  //key for getting the input of the text-field
  //notifier to notify the other text-field listeners
  final loginFormKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
  Widget loginTextField() {
    //set initial success state (when opening settings will display init value)
    isLoggedIn.value = storage.getLoginState() ?? false;
    return CustomFutureTextFormField(
      formKey: loginFormKey,
      validationErrorText: 'errorText',
      hintText: 'hintText',
      labelText: 'labelText',
      prefixIcon: Icons.person,
      initialText: storage.getToken(),
      getFutureValidation: login,
      enabled: true,
      onSubmit: (success) => isLoggedIn.value = success,
      initialState: isLoggedIn.value,
    );
  }

  //key for getting the input of the text-field
  //notifier to notify the other text-field listeners
  final repoFormKey = GlobalKey<FormState>();
  final ValueNotifier<bool> repoPathIsValid = ValueNotifier(false);
  Widget repoTextField() {
    //set initial success state (when opening settings will display init value)
    repoPathIsValid.value = storage.getRepoState() ?? false;
    return ValueListenableBuilder(
      valueListenable: isLoggedIn,
      builder: (_, bool notifierValue, ___) {
        return CustomFutureTextFormField(
          formKey: repoFormKey,
          validationErrorText: 'errorText',
          hintText: 'hintText',
          labelText: 'labelText',
          prefixIcon: Icons.home,
          initialText: storage.getRepoPath(),
          getFutureValidation: setRepo,
          onSubmit: (success) => repoPathIsValid.value = success,
          initialState: repoPathIsValid.value,
          enabled: notifierValue,
        );
      },
    );
  }

  //key for getting the input of the text-field
  final configFormKey = GlobalKey<FormState>();
  Widget configTextField() {
    return ValueListenableBuilder(
      valueListenable: repoPathIsValid,
      builder: (_, bool notifierValue, ___) {
        return CustomFutureTextFormField(
          formKey: configFormKey,
          validationErrorText: 'errorText',
          hintText: 'hintText',
          labelText: 'labelText',
          prefixIcon: Icons.settings,
          initialText: storage.getConfigPath(),
          getFutureValidation: setConfig,
          onSubmit: (_) {},
          initialState: storage.getConfigState() ?? false,
          enabled: notifierValue,
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
    required this.initialText,
    required this.hintText,
    required this.labelText,
    required this.prefixIcon,
    required this.validationErrorText,
    required this.getFutureValidation,
    required this.onSubmit,
    required this.initialState,
    required this.enabled,
  });

  final GlobalKey<FormState> formKey;
  final String validationErrorText;
  final String hintText;
  final bool enabled;
  final String labelText;
  final IconData prefixIcon;
  final String? initialText;
  final bool initialState;
  final Future<bool> Function(String) getFutureValidation;
  final void Function(bool) onSubmit;

  @override
  State<CustomFutureTextFormField> createState() =>
      _CustomFutureTextFormFieldState();
}

class _CustomFutureTextFormFieldState extends State<CustomFutureTextFormField> {
  late Future<bool> futureValidation;

  ///-----INIT-----
  @override
  void initState() {
    ///set userInput to initial value
    userInput = widget.initialText;

    ///initiate future validation
    futureValidation = Future(() => widget.initialState);
    super.initState();
  }

  ///-----BODY-----
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
    notifyAfterBuildValidation(validation);
    return Form(
      key: widget.formKey,
      child: TextFormField(
        enabled: !isDisabled() || isLoading,
        initialValue: widget.initialText,
        textInputAction: TextInputAction.send,
        validator: (_) => validator(validated: validation),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: widget.hintText,

          ///filled: true,
          ///fillColor: validate ? green : red,
          labelText: widget.labelText,
          prefixIcon: prefixIcon(validated: validation),
          suffixIcon: suffixIcon(validated: validation, isLoading: isLoading),
          errorStyle: undersideTextStyle(validated: validation),
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

      ///disable listeners while loading
      disableListener();

      ///fetch & test new validation
      futureValidation = widget.getFutureValidation(userInput);
    });
  }

  void notifyAfterBuildValidation(bool? validation) {
    ///at the end of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ///automatically retry text-field
      if (isRetry()) {
        setState(() {
          futureValidation = widget.getFutureValidation(userInput!);
        });
      }

      ///if state==success -> activate listener
      else if (isSuccess(validated: validation)) {
        print(widget.initialText);
        activateListener();
      }

      ///else disable listener
      else {
        disableListener();
      }

      ///update prevStateWasDisabled & isFirstBuild (for isRetry() check)
      isFirstBuild = false;
      prevStateWasDisabled = isDisabled();
    });
  }

  ///-----HELPERS-----
  //states textField can be in
  bool isFirstBuild = true;
  bool prevStateWasDisabled = false; //for isRetry()
  late String? userInput; //for isRetry()
  //def: automatically retry text-field input
  //+isLoading
  bool isRetry() =>
      !isDisabled() &&
      prevStateWasDisabled &&
      userInput != null &&
      !isFirstBuild;

  bool isDisabled() => !widget.enabled;

  bool isNotValidated({required bool? validated}) => validated == null;

  bool isSuccess({required bool? validated}) =>
      validated != null && validated && !isDisabled() ||
      (isFirstBuild && widget.initialState);

  bool isError({required bool? validated}) =>
      validated != null && !validated && !isDisabled();

  void disableListener() => widget.onSubmit(false);

  void activateListener() => widget.onSubmit(true);

  //todo change style to iso
  ///-----STYLE-----
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;

  TextStyle? undersideTextStyle({required bool? validated}) {
    ///success
    if (isSuccess(validated: validated)) {
      return const TextStyle(color: successColor);
    }

    ///error
    else if (isError(validated: validated)) {
      return const TextStyle(color: errorColor);
    } else {
      return null;
    }
  }

  String? validator({required bool? validated}) {
    ///onError
    if (isError(validated: validated)) {
      return widget.validationErrorText;
    } else {
      return null;
    }
  }

  Widget? prefixIcon({required bool? validated}) {
    Color? iconColor;

    ///success
    if (isSuccess(validated: validated)) {
      iconColor = successColor;
    }

    ///error
    else if (isError(validated: validated)) {
      iconColor = errorColor;
    } else {
      //
    }
    return Icon(widget.prefixIcon, color: iconColor);
  }

  Widget? suffixIcon({required bool? validated, required bool isLoading}) {
    ///loading
    if (isLoading) {
      return const CircularProgressIndicator();
    }

    ///success
    else if (isSuccess(validated: validated)) {
      return const Icon(
        Icons.check_outlined,
        color: successColor,
      );
    }

    ///error
    else if (isError(validated: validated)) {
      return const Icon(Icons.close_outlined, color: errorColor);
    } else {
      return null;
    }
  }
}
