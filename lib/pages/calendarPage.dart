import 'dart:io';

import 'package:cli_calendar_app/database/github_connection.dart';
import 'package:cli_calendar_app/main.dart';
import 'package:cli_calendar_app/model/calendar_appointment.dart';
import 'package:cli_calendar_app/parser/when_parser.dart';
import 'package:cli_calendar_app/widgets/custom_future_builder.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    required this.calenderViewController,
    required this.pageStateNotifier,
  });

  final ValueNotifier<PageState> pageStateNotifier;
  final CalendarController calenderViewController;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final Future<File?> futureDatabaseCalendarFile;

  @override
  void initState() {
    futureDatabaseCalendarFile = _tempDatabaseTest();
    super.initState();
  }

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
    return SfCalendar(
      view: defaultView,
      controller: widget.calenderViewController,
      onTap: _onTapDateChangeToDayView,
      dataSource: CalendarEventDataSource(
        calendarFile == null
            ? []
            : WhenParser().convertToCalendarAppointment(
                calendarFile,
                DateTime(2022),
                DateTime(2024),
              ),
      ),
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

  Future<File?> _tempDatabaseTest() async {
    final Database github = Database();
    await github.login('');
    await github.autoSetup();
    return github.fetchCalendarFile();
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
//
//
//
//
//
