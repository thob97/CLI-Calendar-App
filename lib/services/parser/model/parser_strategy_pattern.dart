import 'dart:io';

import 'package:cli_calendar_app/model/calendar_appointment.dart';

abstract class ParserStrategyPattern {
  List<CalendarAppointment> convertToCalendarAppointment(
    File file,
    DateTime from,
    DateTime until,
  );
}
