import 'dart:io';

import 'package:cli_calendar_app/main.dart';
import 'package:cli_calendar_app/model/calendar_appointment.dart';
import 'package:cli_calendar_app/services/database/database_strategy.dart';
import 'package:cli_calendar_app/services/database/model/config.dart';
import 'package:cli_calendar_app/services/notification_service.dart';
import 'package:cli_calendar_app/services/parser/when_parser.dart';
import 'package:cli_calendar_app/widgets/custom_future_builder.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.calenderViewController,
    required this.pageStateNotifier,
    required this.database,
  });

  final DatabaseStrategy database;
  final ValueNotifier<PageState> pageStateNotifier;
  final CalendarController calenderViewController;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final Future<File?> futureDatabaseCalendarFile;

  ///-----init-----
  void initCalendarFile() {
    //if initialized -> fetch calendar file
    if (widget.database.isInitialized()) {
      futureDatabaseCalendarFile = widget.database.fetchCalendarFile();
    } else {
      futureDatabaseCalendarFile = Future(() => null);
    }
  }

  late final DateTime showEntriesFrom;
  late final DateTime showEntriesUntil;
  late final int hoursBeforeNotify; //for notifications
  late final List<int> daysToNotifyOn; //for notifications

  void initConfig() {
    ///if config available: get values
    if (widget.database.isInitialized()) {
      ///calculate dates
      final Config config = widget.database.getConfig();
      final DateTime now = DateTime.now();
      showEntriesFrom = DateTime(
        now.year,
        now.month - config.monthsBack,
        now.day,
      );
      showEntriesUntil = DateTime(
        now.year,
        now.month + config.monthsAhead,
        now.day,
      );
      hoursBeforeNotify = config.notifyOffsetInHours;
      daysToNotifyOn = config.notifyAtDaysBefore;
    }

    ///else show no dates -> placeholder values
    else {
      showEntriesFrom = DateTime.now();
      showEntriesUntil = showEntriesFrom;
    }
  }

  @override
  void initState() {
    initCalendarFile();
    initConfig();
    super.initState();
  }

  ///-----BUILD-PAGE-----
  @override
  Widget build(BuildContext context) {
    return _buildFuture();
  }

  ///-----WIDGETS-----
  Widget _buildFuture() {
    return CustomFutureBuilder(
      futureData: futureDatabaseCalendarFile,
      builder: (calendarFile) {
        return _calendar(calendarFile as File?);
      },
    );
  }

  Widget _calendar(File? calendarFile) {
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
      hoursBeforeNotify: hoursBeforeNotify,
      daysToNotifyOn: daysToNotifyOn,
    );

    ///show calendar widget
    return SfCalendar(
      view: defaultView,
      controller: widget.calenderViewController,
      onTap: _onTapDateChangeToDayView,
      dataSource: CalendarEventDataSource(appointments),
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
    if (widget.calenderViewController.view == CalendarView.month &&
        calendarTapDetails.targetElement == CalendarElement.calendarCell) {
      //todo maybe change view to schedule
      //change view
      widget.calenderViewController.view = CalendarView.day;
      //notify listeners
      widget.pageStateNotifier.value = PageState.calendarDay;
    }
  }

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

  //todo: updating border not functioning?
  void _upDateBorder(ViewChangedDetails details) {
    if (widget.calenderViewController.view == CalendarView.day) {
      print(widget.calenderViewController.selectedDate);
      widget.calenderViewController.selectedDate = details.visibleDates.first;
      print(widget.calenderViewController.selectedDate);
    }
  }
}
