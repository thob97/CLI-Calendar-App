// ignore_for_file: unnecessary_this

import 'package:cli_calendar_app/model/calendar_appointment.dart';
import 'package:cli_calendar_app/services/notification/notification_service.dart';

//this class extends the notificationService to implement _registerNotificationForCalendarAppointments
///do not implement cache functionality for this
//as the test to compare cache (the test to check whenever the notifications should be updated) is more resource heavy than just registering them again
class CalendarNotification extends NotificationService {
  //todo check for iphone vs android
  //iphone only supports max 64 appointments
  void registerAppointmentNotifications({
    required List<CalendarAppointment> appointments,
    required int hoursBeforeNotify,
    required List<int> daysToNotifyOn,
  }) {
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
            this.scheduleNotification(
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
}
