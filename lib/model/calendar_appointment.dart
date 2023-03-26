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
