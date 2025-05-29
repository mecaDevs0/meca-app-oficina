import '../../data/data.dart';

extension AgendaExtension on AgendaModel {
  WeekDayModel getWeekDay(DaysOfWeek day) {
    return switch (day) {
      DaysOfWeek.monday => monday,
      DaysOfWeek.tuesday => tuesday,
      DaysOfWeek.wednesday => wednesday,
      DaysOfWeek.thursday => thursday,
      DaysOfWeek.friday => friday,
      DaysOfWeek.saturday => saturday,
      DaysOfWeek.sunday => sunday,
    };
  }
}
