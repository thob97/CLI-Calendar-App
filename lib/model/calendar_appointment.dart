import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarAppointment {
  const CalendarAppointment({
    required this.description,
    required this.startDate,
    required this.endDate,
  });

  final String description;
  final DateTime startDate;
  final DateTime endDate;
}

//
//
//
//
//
///-----CalendarAppointments-to-CalendarEventDataSource
class CalendarEventDataSource extends CalendarDataSource {
  CalendarEventDataSource(List<CalendarAppointment> events) {
    appointments = events;
  }

  CalendarAppointment getEvent(int index) =>
      appointments![index] as CalendarAppointment;

  @override
  DateTime getStartTime(int index) {
    return getEvent(index).startDate;
  }

  @override
  DateTime getEndTime(int index) {
    return getEvent(index).endDate;
  }

  @override
  String getSubject(int index) {
    return getEvent(index).description;
  }

  @override
  bool isAllDay(int index) {
    //if no time gap between start and end date
    return getEvent(index).startDate.isAtSameMomentAs(getEvent(index).endDate);
  }
}
