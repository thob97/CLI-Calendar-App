import 'package:cli_calendar_app/pages/calendarPage.dart';
import 'package:cli_calendar_app/services/database/database_proxy.dart';
import 'package:cli_calendar_app/services/persistent_storage.dart';
import 'package:cli_calendar_app/widgets/appbar.dart';
import 'package:cli_calendar_app/widgets/bottomNavBar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ///-----INIT-----
  late final PersistentStorage storage;
  late final DatabaseProxy database;

  ///notifiers
  //notify appbars (disable back)
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  //notify appbars (autoSetup buttons)
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier(false);

  @override
  void initState() {
    //get database & storage
    database = Provider.of<DatabaseProxy>(context, listen: false);
    storage = Provider.of<PersistentStorage>(context, listen: false);
    isLoggedInNotifier.value = storage.getLoginState() ?? false;
    loginController.text = storage.getToken() ?? '';
    repoController.text = storage.getRepoPath() ?? '';
    configController.text = storage.getConfigPath() ?? '';
    super.initState();
  }

  ///-----PAGE-----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SettingsAppBar(disableWhileLoading: isLoadingNotifier),
      bottomNavigationBar: SettingsNavBar(
        onPressed: onAutoSetup,
        disableWhileLoggedOut: isLoggedInNotifier,
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            _textFields(),
            _userInfo(),
          ],
        ),
      ),
    );
  }

  ///-----FUNCTIONS-----
  //purpose: keys to call the onSubmit Methods
  final GlobalKey loginWidgetKey = GlobalKey();
  final GlobalKey repoWidgetKey = GlobalKey();

  //purpose: to change textField values for autoSetup method
  final TextEditingController loginController = TextEditingController();
  final TextEditingController repoController = TextEditingController();
  final TextEditingController configController = TextEditingController();

  Future<void> onRefresh() {
    (loginWidgetKey.currentState! as _CustomFutureTextFormFieldState)
        .onFieldSubmitted(loginController.text);
    return Future(() => null);
  }

  Future<void> onAutoSetup() async {
    assert(isLoggedInNotifier.value);

    ///if autoSetup success
    if (await database.autoSetup()) {
      ///update textFields
      repoController.text = database.autoSetupRepoName;
      configController.text = database.autoSetupConfigPath;

      ///test textFields
      (repoWidgetKey.currentState! as _CustomFutureTextFormFieldState)
          .onFieldSubmitted(repoController.text);
    }
  }

  Future<bool> login(String login) async {
    await storage.saveToken(login);
    final bool success = await database.login(login);
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

  ///-----WIDGETS-----
  Widget _textFields() {
    return TextFields(
      isLoggedInNotifier: isLoggedInNotifier,
      isLoadingNotifier: isLoadingNotifier,
      initialLoginState: storage.getLoginState(),
      initialRepoState: storage.getRepoState(),
      initialConfigState: storage.getConfigState(),
      loginFutureValidation: login,
      repoFutureValidation: setRepo,
      configFutureValidation: setConfig,
      loginWidgetKey: loginWidgetKey,
      repoWidgetKey: repoWidgetKey,
      loginController: loginController,
      repoController: repoController,
      configController: configController,
    );
  }

  Widget _userInfo() {
    return ValueListenableBuilder(
      valueListenable: isLoggedInNotifier,
      builder: (_, bool notifierValue, ___) {
        return UserInfo(
          userName: notifierValue ? database.getUsername() : null,
          apiCallsLeft: notifierValue ? database.getRemainingRateLimit() : null,
          resetTime: notifierValue ? database.getResetOfRateLimit() : null,
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
class TextFields extends StatelessWidget {
  TextFields({
    required this.isLoggedInNotifier,
    required this.isLoadingNotifier,
    required this.initialLoginState,
    required this.initialRepoState,
    required this.initialConfigState,
    required this.loginFutureValidation,
    required this.repoFutureValidation,
    required this.configFutureValidation,
    required this.loginWidgetKey,
    required this.repoWidgetKey,
    required this.loginController,
    required this.repoController,
    required this.configController,
  });

  final GlobalKey loginWidgetKey;
  final GlobalKey repoWidgetKey;
  final TextEditingController loginController;
  final TextEditingController repoController;
  final TextEditingController configController;

  final ValueNotifier<bool> isLoggedInNotifier;
  final ValueNotifier<bool> isLoadingNotifier;
  final bool? initialLoginState;
  final bool? initialRepoState;
  final bool? initialConfigState;
  final Future<bool> Function(String) loginFutureValidation;
  final Future<bool> Function(String) repoFutureValidation;
  final Future<bool> Function(String) configFutureValidation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        loginTextField(),
        repoTextField(),
        configTextField(),
      ],
    );
  }

  //

  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();

  Widget loginTextField() {
    return CustomFutureTextFormField(
      key: loginWidgetKey,
      formKey: loginFormKey,
      validationErrorText: 'errorText',
      hintText: 'hintText',
      labelText: 'labelText',
      prefixIcon: Icons.person,
      getFutureValidation: loginFutureValidation,
      enabled: true,
      notifyNextTextField: (success) => isLoggedInNotifier.value = success,
      initialState: isLoggedInNotifier.value,
      notifyWhenLoading: (isLoading) => isLoadingNotifier.value = isLoading,
      textEditingController: loginController,
    );
  }

  GlobalKey<FormState> repoFormKey = GlobalKey<FormState>();
  ValueNotifier<bool> repoPathIsValid = ValueNotifier(false);

  Widget repoTextField() {
    //set initial success state (when opening settings will display init value)
    repoPathIsValid.value = initialRepoState ?? false;
    return ValueListenableBuilder(
      valueListenable: isLoggedInNotifier,
      builder: (_, bool notifierValue, ___) {
        return CustomFutureTextFormField(
          key: repoWidgetKey,
          formKey: repoFormKey,
          validationErrorText: 'errorText',
          hintText: 'hintText',
          labelText: 'labelText',
          prefixIcon: Icons.home,
          getFutureValidation: repoFutureValidation,
          notifyNextTextField: (success) => repoPathIsValid.value = success,
          initialState: repoPathIsValid.value,
          enabled: notifierValue,
          notifyWhenLoading: (isLoading) => isLoadingNotifier.value = isLoading,
          textEditingController: repoController,
        );
      },
    );
  }

  GlobalKey<FormState> configFormKey = GlobalKey<FormState>();

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
          getFutureValidation: configFutureValidation,
          notifyNextTextField: (_) {},
          initialState: initialConfigState ?? false,
          enabled: notifierValue,
          notifyWhenLoading: (isLoading) => isLoadingNotifier.value = isLoading,
          textEditingController: configController,
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
    super.key,
    required this.formKey,
    required this.hintText,
    required this.labelText,
    required this.prefixIcon,
    required this.validationErrorText,
    required this.getFutureValidation,
    required this.notifyNextTextField,
    required this.initialState,
    required this.enabled,
    required this.notifyWhenLoading,
    required this.textEditingController,
  });

  final TextEditingController textEditingController;
  final GlobalKey<FormState> formKey;
  final String validationErrorText;
  final String hintText;
  final bool enabled;
  final String labelText;
  final IconData prefixIcon;
  final bool initialState;
  final Future<bool> Function(String) getFutureValidation;
  final void Function(bool) notifyNextTextField;
  final void Function(bool) notifyWhenLoading;

  @override
  State<CustomFutureTextFormField> createState() =>
      _CustomFutureTextFormFieldState();
}

class _CustomFutureTextFormFieldState extends State<CustomFutureTextFormField> {
  late Future<bool> futureValidation;

  ///-----INIT-----
  @override
  void initState() {
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
    notifyAfterBuildValidation(validation, isLoading);
    return Form(
      key: widget.formKey,
      child: TextFormField(
        controller: widget.textEditingController,
        enabled: !isDisabled() || isLoading,
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
      ///disable listeners while loading
      disableListener();

      ///fetch & test new validation
      futureValidation = widget.getFutureValidation(userInput);
    });
  }

  void notifyAfterBuildValidation(bool? validation, bool isLoading) {
    ///at the end of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ///notify appbar that its loading
      if (!isDisabled()) {
        widget.notifyWhenLoading(isLoading);
      }

      ///automatically retry text-field
      if (isRetry()) {
        setState(() {
          futureValidation =
              widget.getFutureValidation(widget.textEditingController.text);
        });
      }

      ///if state==success -> activate listener
      else if (isSuccess(validated: validation)) {
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
  //def: automatically retry text-field input
  //+isLoading
  bool isRetry() =>
      !isDisabled() &&
      prevStateWasDisabled &&
      widget.textEditingController.text != '' &&
      !isFirstBuild;

  bool isDisabled() => !widget.enabled;

  bool isNotValidated({required bool? validated}) => validated == null;

  bool isSuccess({required bool? validated}) =>
      validated != null && validated && !isDisabled() ||
      (isFirstBuild && widget.initialState);

  bool isError({required bool? validated}) =>
      validated != null && !validated && !isDisabled();

  void disableListener() => widget.notifyNextTextField(false);

  void activateListener() => widget.notifyNextTextField(true);

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

//
//
//
//
//
///-----UserInfo-----
class UserInfo extends StatelessWidget {
  const UserInfo({
    super.key,
    required this.userName,
    required this.apiCallsLeft,
    required this.resetTime,
  });

  final String? userName;
  final int? apiCallsLeft;
  final DateTime? resetTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Logged in as: $userName'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('API calls left: $apiCallsLeft'),
            Text(
              'Next reset at: ${resetTime == null ? '' : DateFormat.Hm().format(resetTime!)}',
            )
          ],
        ),
      ],
    );
  }
}

//
//
//
//
//shows backButton when in day view
///-----AppBar-----
class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({
    super.key,
    required this.disableWhileLoading,
  });

  //set value notifier to notify appBar
  //disable backbutton while loading
  final ValueNotifier<bool> disableWhileLoading;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: disableWhileLoading,
      builder: (_, bool isDisabled, ___) {
        return MyAppBar(
          title: 'Settings',
          //normally show back button(null->pushedNavigator->autoBackButton), show disable back button when disabled
          leadingButton: MyBackButton(
            onPressed: () => onBackButton(context),
            isDisabled: isDisabled,
          ),
        );
      },
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
class SettingsNavBar extends StatelessWidget {
  const SettingsNavBar({
    super.key,
    required this.onPressed,
    required this.disableWhileLoggedOut,
  });

  final VoidCallback onPressed;
  final ValueNotifier<bool> disableWhileLoggedOut;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: disableWhileLoggedOut,
      builder: (_, bool isLoggedIn, ___) {
        return MyBottomNavBar(
          mainButton: AutoSetupButton(
            isDisabled: !isLoggedIn,
            onPressed: onPressed,
          ),
        );
      },
    );
  }
}
