import 'dart:io';

import 'package:cli_calendar_app/model/calendar_appointment.dart';
import 'package:cli_calendar_app/pages/todoListPage.dart';
import 'package:cli_calendar_app/services/database/database_strategy.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';
import 'package:cli_calendar_app/services/notification_service.dart';
import 'package:cli_calendar_app/services/parser/when_parser.dart';
import 'package:cli_calendar_app/widgets/appbar.dart';
import 'package:cli_calendar_app/widgets/bottomNavBar.dart';
import 'package:cli_calendar_app/widgets/custom_future_builder.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  //database -> parse -> appointments
  late final Future<List<CalendarAppointment>?> futureAppointments;
  late final DatabaseStrategy database;


  ///-----init-----
  void _registerNotificationForCalendarAppointments({
    required List<CalendarAppointment> appointments,
    required int hoursBeforeNotify,
    required List<int> daysToNotifyOn,
  }) {
    //todo check for iphone vs android
    //iphone only supports max 64 appointments
    int counter = 0;

    ///for every appointment
    for (final CalendarAppointment appointment in appointments) {
      ///if appointment is upcoming
      if (appointment.startDate.isAfter(DateTime.now())) {
        ///for every day to notify on
        for (final int day in daysToNotifyOn) {
          final DateTime notification = appointment.startDate
              .add(Duration(days: -day, hours: -hoursBeforeNotify));

          ///if notification is upcoming
          if (notification.isAfter(DateTime.now())) {
            ///ad scheduled notification
            NotificationService().scheduleNotification(
              scheduledNotificationTime: notification,
              title: 'Calendar Notification',
              body: appointment.description,
            );

            ///break if limit of scheduled notifications reached (iOS)
            counter++;
            if (counter >= 64) break;
          }
        }
      }
    }
  }

  @override
  void initState() {
    //get database
    database = Provider.of<DatabaseStrategy>(context, listen: false);
    futureAppointments = init();
    super.initState();
  }

  Future<List<CalendarAppointment>?> init() async {
    ///if config available
    if (database.isInitialized()) {
      ///get calendar file
      final File? calendarFile = await database.fetchCalendarFile();

      ///get config
      final Config config = database.getConfig();

      ///parse calendar file
      final DateTime now = DateTime.now();
      final showEntriesFrom = DateTime(
        now.year,
        now.month - config.monthsBack,
        now.day,
      );
      final showEntriesUntil = DateTime(
        now.year,
        now.month + config.monthsAhead,
        now.day,
      );
      final List<CalendarAppointment> appointments = calendarFile == null
          ? []
          : WhenParser().convertToCalendarAppointment(
              calendarFile,
              showEntriesFrom,
              showEntriesUntil,
            );

      ///add notifications
      _registerNotificationForCalendarAppointments(
        appointments: appointments,
        hoursBeforeNotify: config.notifyOffsetInHours,
        daysToNotifyOn: config.notifyAtDaysBefore,
      );
      return appointments;
    } else {
      return null;
    }
  }

  //get calendarController to change the views in calendar widget
  final CalendarController calenderViewController = CalendarController();

  //set value notifier to notify appBar
  final ValueNotifier<bool> isDayViewNotifier = ValueNotifier(false);

  ///-----BUILD-PAGE-----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CalendarAppBar(
        calenderViewController: calenderViewController,
        isDayViewNotifier: isDayViewNotifier,
      ),
      bottomNavigationBar: CalendarNavBar(
          newTodoButtonDisabled: !database.isInitialized()),
      body: _buildFuture(),
    );
  }

  ///-----WIDGETS-----
  Widget _buildFuture() {
    return CustomFutureBuilder(
      futureData: futureAppointments,
      builder: (calendarFile) {
        return _calendar(calendarFile as List<CalendarAppointment>?);
      },
    );
  }

  Widget _calendar(List<CalendarAppointment>? appointments) {
    ///show calendar widget
    return SfCalendar(
      view: defaultView,
      controller: calenderViewController,
      onTap: _onTapDateChangeToDayView,
      dataSource: CalendarEventDataSource(appointments ?? []),
      //todo: maybe change styling
      //onViewChanged: _onViewChanged, //todo don't allow blue border
      cellBorderColor: Colors.transparent,
      //loadMoreWidgetBuilder: , //todo load max 3 pages
      //todo remove on long tab hold
    );
  }

  ///-----STYLE-----
  static const CalendarView defaultView = CalendarView.month;

  ///-----FUNCTIONS-----
  //def: change to day view when tapping on a calendar cell
  void _onTapDateChangeToDayView(CalendarTapDetails calendarTapDetails) {
    if (calenderViewController.view == CalendarView.month &&
        calendarTapDetails.targetElement == CalendarElement.calendarCell) {
      //todo maybe change view to schedule
      //change view
      calenderViewController.view = CalendarView.day;
      //notify listeners
      isDayViewNotifier.value = true;
    }
  }
}

//
//
//
//
//shows backButton when in day view
///-----AppBar-----
class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CalendarAppBar({
    super.key,
    required this.calenderViewController,
    required this.isDayViewNotifier,
  });

  final CalendarController calenderViewController;

  //set value notifier to notify appBar
  final ValueNotifier<bool> isDayViewNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDayViewNotifier,
      builder: (_, bool isDay, ___) {
        return MyAppBar(
          title: 'Calendar',
          followingButton: const MySettingsButton(),
          //show backButton when day
          leadingButton:
          isDay ? MyBackButton(onPressed: _onPressedBackButton) : null,
        );
      },
    );
  }

  ///-----FUNCTIONS-----
  @override //use system standard defined height for appbar
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _onPressedBackButton() {
    //change calendar.view to month.view
    calenderViewController.view = CalendarView.month;
    isDayViewNotifier.value = false;
  }
}
//
//
//
//
//
///-----NavBar-----
class CalendarNavBar extends StatelessWidget {
  const CalendarNavBar({super.key, required this.newTodoButtonDisabled});

  final bool newTodoButtonDisabled;

  @override
  Widget build(BuildContext context) {
    return MyBottomNavBar(
      mainButton: NewTodoButton(isDisabled: newTodoButtonDisabled,
          onPressed: () => _onPressed(context)),
      subButton: const ShowTodosButton(),);
  }

  //open todoListPage page
  void _onPressed(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
        const TodoListPage(isCreatingNewTodo: true),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}
