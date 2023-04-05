import 'dart:io';

import 'package:cli_calendar_app/model/calendar_appointment.dart';
import 'package:cli_calendar_app/services/parser/model/parser_strategy_pattern.dart';
import 'package:cli_calendar_app/services/parser/regex.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

//WhenDocs: https://manpages.ubuntu.com/manpages/focal/en/man1/when.1.html

//todo use whenCalendar config file
//doc:
// --[no]monday_first
// Start the week from Monday, rather than Sunday. Default: no
//
// --[no]orthodox_easter
// Calculate Easter according to the Orthodox Eastern Church's
// calendar. Default: no
//
// --[no]ampm
// Display the time of day using 12-hour time, rather than 24-hour
// time. Also affects the parsing of input times.  Default: yes
//
// --auto_pm=x
// When times are input with hours that are less than x, and AM or
// PM is not explicitly specified, automatically assume that they
// are PM rather than AM. Default: 0

//todo support birthday
//doc:
// For events that occur once a year, such as birthdays and anniversaries,
//     you can either use a * in place of the year,
//
// * dec 25 , Christmas
//
// or use a year with an asterisk:
//
// 1920* aug 29 , Charlie Parker turns \a, born in \y

//todo: rethink method placement & names & visibility (maybe move some into classes)


///Code
//todo
class WhenParser implements ParserStrategyPattern {
  //used for testing only
  @visibleForTesting
  List<WhenAppointment> testingParseWhenFile(File file) {
    final List<WhenAppointment> result = [];

    ///for every line in file
    final List<String> lines = file.readAsLinesSync();
    for (final String line in lines) {
      //while line isNotEOL
      ///parse whenLine
      final WhenAppointment? whenAppointment = parseWhenLine(line);

      ///add to result
      if (whenAppointment != null) {
        result.add(whenAppointment);
      }
    }
    return result;
  }

  //doc: "Blank lines ... are ignored."
  //def:
  //return:
  WhenAppointment? parseWhenLine(String line) {
    ///remove WhenComment
    line = removeWhenComment(line);
    //if line contains no appointment / is empty
    if (line.trim().isEmpty) {
      return null;
    }
    //if line containsAppointment
    else {
      ///split WhenLine (parse Description)
      List<String> sections;
      try {
        sections = splitWhenLine(line);
      }
      //format error
      catch (_) {
        return null;
      }
      final String date = sections[0];
      final String description = sections[1];

      ///parse time
      final List<WhenTime> times = parseWhenTime(description);
      final WhenTime startTime = times[0];
      final WhenTime endTime = times[1];

      ///parse whenDate
      late List<WhenDate> whenDates;
      if (isFixedWhenDate(date)) {
        ///parse fixed whenDate
        try {
          whenDates = [parseFixedDate(date)];
        }
        //format error
        catch (_) {
          return null;
        }
      }
      //else is variable whenDate
      else {
        ///parse nested variable=value whenDate
        try {
          whenDates = solveNestedVariableWhenDate(date);
        }
        //format error
        catch (_) {
          return null;
        }
      }

      ///create whenAppointment
      final WhenAppointment whenAppointment = WhenAppointment(
        description: description,
        startTime: startTime,
        endTime: endTime,
        dates: whenDates,
      );

      return whenAppointment;
    }
  }

  @override
  List<CalendarAppointment> convertToCalendarAppointment(
    File file,
    DateTime from,
    DateTime until,
  ) {
    List<CalendarAppointment> result = [];

    ///for every line in file
    final List<String> lines = file.readAsLinesSync();
    for (final String line in lines) {
      //while line isNotEOL
      ///parse whenLine
      final WhenAppointment? whenAppointment = parseWhenLine(line);

      ///if contains appointment
      if (whenAppointment != null) {
        ///parse whenAppointment to CalendarAppointments
        result = result
            .followedBy(
                whenAppointment.getNextCalendarAppointments(from, until))
            .toList();
      }
    }
    return result;
  }
}

///-
//doc: "lines beginning with a # sign are ignored."
//def: removes comments from input When line
//returns: line without comment
String removeWhenComment(String line) {
  ///remove comment
  //remove a # char and everything following it
  return line.replaceAll(RegExp('#.*'), '');
}

///-
//doc: appointments have the format "date, description"
//  "Extra whitespace is ignored until you get into the actual text after the comma"
//def: parses line to format: appointment, description
//expects: valid When string - format ".+,.+" - (syntax,desc)
//returns: list in format: [date, description], exception on invalid format
List<String> splitWhenLine(String line) {
  ///split to appointment-description
  final List<String> sections = splitFirstRegexMatch(',', line);
  //if there is no match, as splitFirstRegexMatch() will always either return 0 or 2 elements
  if (sections.length != 2) {
    throw Exception("invalid format: no ',' found when parsing the line");
  }
  final String appointment = sections[0];
  final String description = sections[1];

  ///return: appointment, description
  return [appointment, description];
}

///-
//doc: "the description can optionally contain a time in format 'dd:dd' with optional appending a or p for am or pm"
//  "Times can be in h:mm or hh:mm format"
//  when also accepts invalid times like 25:70. this program only parses valid inputs
//def: parses of the description of a whenAppointment
//returns: if time present: [startTime, endTime]
//  if time not present or invalid input: [zeroTime, zeroTime]
//  always returns a list with size exactly 2
List<WhenTime> parseWhenTime(String whenDescription) {
  ///get time
  //\d?\d:\d\d : format like dd:dd
  //[ap]? : can be followed by an  'a' or 'p' for AM or PM
  //(?<!\d) ... (?!\d) : does not match when there are additional digits: like ddd:dd or dd:ddd
  final List<String> times =
      getAllRegexMatches(r'(?<!\d)\d?\d:\d\d(?!\d)[ap]?', whenDescription);

  ///parse time
  List<WhenTime> parsedTimes = [];
  //for the first two specified times in the input
  for (int i = 0; i < times.length && i < 2; i++) {
    final String time = times[i];
    try {
      if (time.endsWith('a')) {
        //remove last char 'a' and add 'AM' to string
        final String validDateFormatString =
            '${time.substring(0, time.length - 1)} AM';
        final DateTime date =
            DateFormat.jm().parseStrict(validDateFormatString);
        parsedTimes.add(WhenTime.fromDateTime(date));
      } else if (time.endsWith('p')) {
        //remove last char 'p' and add 'PM' to string
        final String validDateFormatString =
            '${time.substring(0, time.length - 1)} PM';
        final DateTime date =
            DateFormat.jm().parseStrict(validDateFormatString);
        parsedTimes.add(WhenTime.fromDateTime(date));
      }
      //'normal' time format without am or pm
      else {
        final DateTime date = DateFormat.Hm().parseStrict(time);
        parsedTimes.add(WhenTime.fromDateTime(date));
      }
    }
    //invalid input: do not parse time
    catch (e) {
      parsedTimes = [];
      break;
    }
  }
  //in case no time was specified in description, add placeholder dates with 0 time to assert(times.length) >= 2
  parsedTimes =
      parsedTimes.followedBy([WhenTime.zero(), WhenTime.zero()]).toList();
  //only return 2 items max
  return parsedTimes.sublist(0, 2).toList();
}

///----SOLVE NESTED APPOINTMENT
///-
//def: counts parenthesis chars in input using a stack
//assert: -
//return: true if as many '(' as ')' parentheses
bool parenthesesAreBalanced(String input) {
  int depth = 0;
  for (int i = 0; i < input.length; i++) {
    final String char = input[i];
    if (char.compareTo('(') == 0) {
      depth++;
    } else if (char.compareTo(')') == 0) {
      depth--;
    }
  }
  return depth == 0;
}

//def: test if next match is variable = value equation
//assert: -
//return: int index of end of match on success, null on no match
int? nextIsVariableValueEquation(String text) {
  final match = RegExp(r'^[wmdyjabcez]\s*=\s*(\w|\d)*', caseSensitive: false)
      .firstMatch(text);
  return match?.end;
}

///-
//docs: when operators "&, |, %, -, <, <=, >, >=, =, !, !="
//def: tests if char is operator
//assert: -
//returns: true if char is operator, false if the string is not a operator or contains additional characters
bool isOperator(String char) {
  //()|()|()| : match exactly one of ()
  //^(...)$ : from start to end of string -> match only character
  return RegExp(r'^((<=)|(!=)|(>=)|(=)|\||(%)|&|>|<|!|-)$').hasMatch(char);
}

///-
//def: uses parenthesis to recursively searches for the next operator, (found if inside depth 1 of a parenthesis + matching char)
//  stops when a single variable=value equation is found, (found if no parenthesis are left)
//expects: input format always has parenthesis around operators - e.g "((v=v op v=v) op v=v)"
//return: corresponding whenDates, invalid WhenDate on invalid input ,exception on invalid format
List<WhenDate> solveNestedVariableWhenDate(String appointment) {
  ///if parentheses format exception
  if (!parenthesesAreBalanced(appointment)) {
    throw Exception('Invalid format - parentheses are not balanced');
  }

  ///init
  int parenthesesDepth = 0;
  //removes starting and leading whitespaces
  appointment = appointment.trim();

  ///for each char loop
  for (int i = 0; i < appointment.length; i++) {
    final String char = appointment[i];

    ///if following chars: variable=value match -> skip equation
    //otherwise the "=" will match as operator, even tho its part of var=val
    //check for parenthesesDepth!=0 for anker case
    final int? skip = nextIsVariableValueEquation(appointment.substring(i));
    if (parenthesesDepth != 0 && skip != null) {
      i += skip - 1;
    }

    ///is parentheses
    else if (char.compareTo('(') == 0) {
      parenthesesDepth++;
    } else if (char.compareTo(')') == 0) {
      parenthesesDepth--;
    }

    //todo: char can never be of size 2 -> <= != >= operators will never match
    ///operator found
    else if (parenthesesDepth == 1 && isOperator(char)) {
      //remove parentheses and operator from string
      final String exp1 = appointment.substring(1, i);
      final String exp2 = appointment.substring(i + 1, appointment.length - 1);
      //continue recursion
      return handleOperators(
        char,
        solveNestedVariableWhenDate(exp1),
        solveNestedVariableWhenDate(exp2),
      );
    }

    ///no nesting left & operators left - anker -> solveVariableValueEquation
    else if (parenthesesDepth == 0) {
      return [solveVariableValueEquation(appointment)];
    }

    ///else: normal character or/and inside parentheses
    else {
      //pass
    }
  }

  ///format exception
  throw Exception('Invalid format - could not parse');
}

///-----To Name-----
///todo: add missing operators
///-
//docs: when operators &, |, %, -, <, <=, >, >=, =, !, !=
//def: calls correct function for operator
//assert: -
//return: corresponding whenDates, invalid WhenDate on false input
List<WhenDate> handleOperators(
  String operator,
  List<WhenDate> dateList1,
  List<WhenDate> dateList2,
) {
  switch (operator) {
    case '&':
      return intersectWhenDates(dateList1, dateList2);
    case '|':
      return unionWhenDates(dateList1, dateList2);
    case '%':
      return [WhenDate.invalid()];
    case '-':
      return [WhenDate.invalid()];
    case '<':
      return [WhenDate.invalid()];
    case '<=':
      return [WhenDate.invalid()];
    case '>':
      return [WhenDate.invalid()];
    case '>=':
      return [WhenDate.invalid()];
    case '=':
      return [WhenDate.invalid()];
    case '!=':
      return [WhenDate.invalid()];
    case '!':
      return [WhenDate.invalid()];
    default: //non supported operator
      return [WhenDate.invalid()];
  }
}

///-
//def: joins WhenDates like the logical "and"
//assert: -
//purpose: used for "&" when variable
//example: [Wd(y=2000)] ,[Wd(y=2001)] -> [] - [Wd(w=1 r] [Wd(m=1)] -> [Wd(w=1, m=1)]
//returns: list of intersects dates - dates which are not possible are discarded
//  on empty input of one var discard all whenDates and return empty result
List<WhenDate> intersectWhenDates(
  List<WhenDate> dateList1,
  List<WhenDate> dateList2,
) {
  //there cant be any intersection with empty date input
  if (dateList1.isEmpty || dateList2.isEmpty) {
    return [];
  }

  ///intersect
  //dates are intersect-able when they are variable or equal
  final List<WhenDate> joinedList = [];
  for (final WhenDate date1 in dateList1) {
    for (final WhenDate date2 in dateList2) {
      ///tests
      //todo maybe use nested ifs here to save on computing time/power
      final bool datesAreValid =
          date1.isValidWhenDate() && date2.isValidWhenDate();
      final bool dayWJoinAble = date1._weekdayIsVariable() ||
          date2._weekdayIsVariable() ||
          date1.weekday == date2.weekday;
      final bool dayMJoinAble = date1._dayIsVariable() ||
          date2._dayIsVariable() ||
          date1.day == date2.day;
      final bool monthJoinAble = date1._monthIsVariable() ||
          date2._monthIsVariable() ||
          date1.month == date2.month;
      final bool yearJoinAble = date1._yearIsVariable() ||
          date2._yearIsVariable() ||
          date1.year == date2.year;

      ///if join-able: return joined whenDate
      if (datesAreValid &&
          dayWJoinAble &&
          dayMJoinAble &&
          monthJoinAble &&
          yearJoinAble) {
        // ??: if left null take right
        joinedList.add(
          WhenDate(
            weekday: date1.weekday ?? date2.weekday,
            day: date1.day ?? date2.day,
            month: date1.month ?? date2.month,
            year: date1.year ?? date2.year,
          ),
        );
      }
    }
  }
  return joinedList;
}

///-
//def: union WhenDates like the logical "or"
//assert: -
//purpose: used for "|" when variable
//returns: list of unions dates
//example: [Wd(y=2000)] ,[Wd(y=2001)] -> [Wd(y=2000) ,Wd(y=2001)] - [Wd(w=1 r] [Wd(m=1)] -> [Wd(w=1), Wd(m=1)]
List<WhenDate> unionWhenDates(
  List<WhenDate> dateList1,
  List<WhenDate> dateList2,
) {
  return dateList1.followedBy(dateList2).toList();
}

///-
//docs: "format "variable = value"
//  "Whitespace is ignored everywhere except inside the value"
//  "Variable names are case-insensitive"
//def: parses variable value equations
//purpose: for solveVariableValueEquation() method
//expects: input in format " variable = value "
//returns: [variable, value] on success, null if input format is invalid
List<String>? parseVariableValueEquation(String input) {
  ///test if format is valid
  //[^\s=] : any non whitespace and '=' character
  //(\s*...\s*)=(\s*...+\s*) : variable = value can be surrounded by whitespaces
  //(?<!.)...(?!.) : but there can not be any
  final bool isValidFormat =
      RegExp(r'(?<!.)(\s*[^\s=]\s*)=(\s*[^\s=]+\s*)(?!.)').hasMatch(input);

  ///if valid: parse
  if (isValidFormat) {
    final List<String> variableValue = input.split('=');
    assert(variableValue.length == 2);
    final String variable = variableValue[0].trim().toLowerCase();
    final String value = variableValue[1].trim().toLowerCase();
    return [variable, value];
  }

  ///else null
  else {
    return null;
  }
}

///todo: add missing parameters
///-
//docs: when variables "w, m, d, y, j, a, b, c, e ,z"
//def: calls correct function for variable
//expects: input in format " variable = value "
//returns: corresponding whenDate, invalid WhenDate on invalid input ,exception on invalid format
WhenDate solveVariableValueEquation(String input) {
  ///parse input from " variable= value  " to "variable" & "value"
  final List<String>? splitInput = parseVariableValueEquation(input);
  //if invalid format
  if (splitInput == null) {
    throw Exception(
      'Invalid format: can not parse variable=value equation $input',
    );
  }
  //else
  final String variable = splitInput[0];
  final String value = splitInput[1];

  ///handleParameter
  switch (variable) {
    case 'w': //day of the week
      return WhenDate(weekday: parseWhenWeekday(value));
    case 'm': //month
      return WhenDate(month: parseWhenMonth(value));
    case 'd': //day of the month
      return WhenDate(day: parseWhenDay(value));
    case 'y': //year
      return WhenDate(year: parseWhenYear(value));
    case 'j': //modified Julian day number
      return WhenDate.invalid();
    case 'a': //1 for the first 7 days of the month, 2 for the next 7, etc.
      return WhenDate.invalid();
    case 'b': //1 for the last 7 days of the month, 2 for the previous 7, etc.
      return WhenDate.invalid();
    case 'c': //on Monday or Friday, equals the day of the month of the nearest weekend day; otherwise -1
      return WhenDate.invalid();
    case 'e': //days until this year's (Western) Easter
      return WhenDate.invalid();
    case 'z': //day of the year (1 on New Year's day)
      return WhenDate.invalid();
    default: //non supported parameter
      throw Exception('Invalid format: can not parse parameter "$variable"');
  }
}

///
//doc: not specified but tested: year must be greater than 1899 else invalid in when
bool isFixedWhenDate(String input) {
  //searches for match in form yyyy mm dd with variable whitespaces
  //as many accepts as many digits as possible -> but more than yyyy mm dd would be an input error
  return RegExp(r'\d+\s+\d+\s+\d+').hasMatch(input);
}

///-
//doc: when allows a fixed date format in form: "yyyy mm dd" or "* mm dd"
//  docs does not specify if multiple whitespaces are allowed, and if preceding and following whitespaces are allowed.
//  but they are - found out through testing
//def: parses fixed date format
//assert: -
//expects: input in format "y m d"
//example: input: "* 12 24"
//returns: corresponding whenDate, invalid WhenDate on invalid input ,exception on invalid format
WhenDate parseFixedDate(String fixedDate) {
  ///parse input
  //\S+ : every word (non whitespace word)
  final List<String> date = getAllRegexMatches(r'\S+', fixedDate);
  //invalid format
  if (date.length != 3) {
    throw Exception('Invalid format: can not parse fixed date');
  }

  ///parse date
  final int? year = date[0] == '*' ? null : parseWhenYear(date[0]);
  final int month = parseWhenMonth(date[1]);
  final int day = parseWhenDay(date[2]);
  final WhenDate whenDate = WhenDate(year: year, month: month, day: day);

  //invalid input
  if (!whenDate.isValidWhenDate()) {
    return WhenDate.invalid();
  }

  ///return
  return whenDate;
}

///-----PARSE DAYS WEEKDAYS MONTHS YEARS-----
///-
//doc: when specifies digit
//  fixed Dates: 32>day>0
//  variable = value equations: day>-1
//def: parses day
//assert: valid input format: no whitespaces in input string
//return: day as int, on invalid input -1
@visibleForTesting
int parseWhenDay(String day) {
  assert(!day.contains(' '));
  late int intDay;

  ///input is int
  try {
    intDay = int.parse(day);
  }

  ///else input is text -> not supported in when
  ///invalid input
  catch (e) {
    return -1;
  }

  ///invalid input
  if (0 >= intDay || intDay > 31) {
    return -1;
  }
  //on success
  return intDay;
}

///-
//doc: when specifies either a digit or a unique substring
//  fixed Dates: 8>weekday>0
//  variable = value equations: weekday>-1
//def: parses weekday
//assert: valid input format: no whitespaces in input string
//return: weekday as int, on invalid input -1
@visibleForTesting
int parseWhenWeekday(String weekday) {
  assert(!weekday.contains(' '));
  const List<String> weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];
  late int intDay;

  ///input is int
  try {
    intDay = int.parse(weekday);
  }

  ///else input is text
  catch (e) {
    final String? uniqueMatch = uniquePrefixMatch(weekday, weekdays);

    ///invalid input
    if (uniqueMatch == null) {
      return -1;
    }
    intDay = weekdayToInt(uniqueMatch);
  }

  ///invalid input
  if (0 >= intDay || intDay > 7) {
    return -1;
  }
  //on success
  return intDay;
}

///-
//doc: "Month names are case-insensitive"
//  "... It just has to be a unique match"
//  fixed Dates: "You can give a trailing . which will be ignored"
//  variable = value equations: ^ not supported (found out through testing)
//  fixed Dates: 13>month>0
//  variable = value equations: month>-1
//  through testing: as many trailing points so that max: monthName.length + 1 -
//  through testing: marz does not match -> it has to be unique match, not only unique prefix match -> ours is unique prefix match
//def: parses month
//assert: valid input format: no whitespaces in input string
//return: month as int, on invalid input -1
@visibleForTesting
int parseWhenMonth(String month) {
  assert(!month.contains(' '));
  const List<String> months = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december'
  ];
  late int intMonth;

  ///input is int
  try {
    intMonth = int.parse(month);
  }

  ///else input is text
  catch (e) {
    final String? uniqueMatch = uniquePrefixMatch(month, months);

    ///invalid input
    if (uniqueMatch == null) {
      return -1;
    }
    intMonth = monthToInt(uniqueMatch);
  }

  ///invalid input
  if (0 >= intMonth || intMonth > 12) {
    return -1;
  }
  //on success
  return intMonth;
}

///-
//doc: when specifies digit
//  fixed Dates: year>0
//  variable = value equations: year>-1
//def: parses year
//assert: valid input format: no whitespaces in input string
//return: year as int, on invalid input -1
@visibleForTesting
int parseWhenYear(String year) {
  assert(!year.contains(' '));
  late int intYear;

  ///input is int
  try {
    intYear = int.parse(year);
  }

  ///else input is text -> not supported in when
  ///invalid input
  catch (e) {
    return -1;
  }

  ///invalid input
  if (0 >= intYear) {
    return -1;
  }
  //on success
  return intYear;
}

///-
//def: finds unique match of a prefix of multiple strings
//purpose: used in parseWeekday() & parseMonth() methods
//assert: -
//example: (tueGibberish, [monday, tuesday, friday]) -> tuesday
//return: string of match on success - null on failure
@visibleForTesting
String? uniquePrefixMatch(String prefix, List<String> strings) {
  ///find matches
  List<String> currentMatches = strings;
  List<String> newMatches = [];
  for (int i = 1; i < prefix.length; i++) {
    final String substringOfPrefix = prefix.substring(0, i);
    for (final String string in currentMatches) {
      if (string.startsWith(substringOfPrefix)) {
        newMatches.add(string);
      }
    }

    ///update matches
    currentMatches = newMatches;
    newMatches = [];

    ///if ambiguity found
    if (currentMatches.length == 1) {
      return currentMatches.first;
    }
  }

  ///no ambiguity found
  return null;
}

///-
//def: converts a month string to corresponding int (non case sensitive)
//purpose: used in parseMonth() method
//assert: input is a month
//example: january -> 1
//return: int of month on success
@visibleForTesting
int monthToInt(String month) {
  const List<String> months = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december'
  ];
  final int res = months.indexOf(month.toLowerCase());
  //if no match found
  assert(res != -1);
  return res + 1;
}

///-
//def: converts a weekday string to corresponding int (non case sensitive)
//purpose: used in parseWeekday() method
//assert: input is a weekday
//example: monday -> 1
//return: int of day on success
@visibleForTesting
int weekdayToInt(String day) {
  const List<String> weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];
  final int res = weekdays.indexOf(day.toLowerCase());
  //if no match found
  assert(res != -1);
  return res + 1;
}

///-----WhenAppointment-----
class WhenAppointment {
  WhenAppointment({
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.dates,
  });

  String description;
  WhenTime startTime;

  //doc: not (really) supported or specified by when, but by this application is the ... of an endtime
  WhenTime endTime;
  List<WhenDate> dates;

  ///todo test
  ///whenDateToDateTimeConverter
  ///done
  //def: converts variable WhenDates to specific CalendarAppointments in specific timeframe
  //expects: list of WhenDates
  //returns: list of corresponding CalendarAppointments
  List<CalendarAppointment> getNextCalendarAppointments(
    DateTime from,
    DateTime until,
  ) {
    final List<CalendarAppointment> result = [];

    ///for every whenDate
    for (final WhenDate date in dates) {
      ///get first/initial date
      DateTime currentDate = DateTime(
        date.year ?? from.year,
        date.month ?? from.month,
        date.day ?? from.day,
      );

      ///if variable date
      //thus one WhenDate will create multiple CalendarAppointments
      if (date._dayIsVariable() ||
          date._monthIsVariable() ||
          date._yearIsVariable()) {
        ///check if to advance by [year, month, day]
        final List<int> addTime = date._dayIsVariable()
            ? [0, 0, 1]
            : date._monthIsVariable()
                ? [0, 1, 0]
                : [1, 0, 0];

        ///while in time range
        while (until.isAfter(currentDate)) {
          if (date.dateIsInTimeframe(currentDate)) {
            //add CalendarAppointment
            final DateTime startDate = DateFormat('yyyy MM dd HH:mm').parse(
              '${currentDate.year} ${currentDate.month} ${currentDate.day} ${startTime.asString()}',
            );
            final DateTime endDate = DateFormat('yyyy MM dd HH:mm').parse(
              '${currentDate.year} ${currentDate.month} ${currentDate.day} ${endTime.asString()}',
            );
            result.add(
              CalendarAppointment(
                description: description,
                startDate: startDate,
                endDate: endDate,
              ),
            );
          }

          ///next date
          //test & advance to next day, month, or year
          //note: DateTime handles overflow and thus advances itself to the next month and year if parameters require it
          // example: DateTime(1,12,32) -> probably DateTime(2,1,1)
          currentDate = DateTime(
            currentDate.year + addTime[0],
            currentDate.month + addTime[1],
            currentDate.day + addTime[2],
          );
        }
      }

      ///else fixed date
      //thus will create one CalendarAppointment
      else {
        //add CalendarAppointment
        final DateTime startDate = DateFormat('yyyy MM dd HH:mm').parse(
          '${currentDate.year} ${currentDate.month} ${currentDate.day} ${startTime.asString()}',
        );
        final DateTime endDate = DateFormat('yyyy MM dd HH:mm').parse(
          '${currentDate.year} ${currentDate.month} ${currentDate.day} ${endTime.asString()}',
        );
        result.add(
          CalendarAppointment(
            description: description,
            startDate: startDate,
            endDate: endDate,
          ),
        );
      }
    }

    return result;
  }
}

///-----WhenDate-----
//def: class which mimics variable dates like When syntax does
// has variables day, weekday, month and year corresponding to When syntax
// null equals * in when thus marking the date as variable
class WhenDate {
  WhenDate({
    this.day,
    this.weekday,
    this.month,
    this.year,
  }); //once set false it should not be able to change
  factory WhenDate.invalid() {
    final WhenDate whenDate =
        WhenDate(day: -1, month: -1, year: -1, weekday: -1);
    whenDate._dateIsValid = false;
    return whenDate;
  }

  //appointment: calculating day
  int? day;
  int? weekday; //monday = 1, ...
  int? month; //january = 1, ...
  int? year;

  ///-----Helpers-----
  bool _dayIsVariable() {
    return day == null;
  }

  bool _monthIsVariable() {
    return month == null;
  }

  bool _yearIsVariable() {
    return year == null;
  }

  bool _weekdayIsVariable() {
    return weekday == null;
  }

  ///----Method----
  //def: tests if a given date is represented in this whenDate
  //purpose: to convert variable whenDates in fixedDates (used in ...)
  //return: true if dates are equal or if whenDate is variable can represent the input date
  bool dateIsInTimeframe(DateTime date) {
    final bool dayFits = _dayIsVariable() || day! >= date.day;
    final bool monthFits = _monthIsVariable() || month! >= date.month;
    final bool yearFits = _yearIsVariable() || year! >= date.year;
    final bool weekdayFits = _weekdayIsVariable() || weekday! == date.weekday;
    return dayFits && monthFits && yearFits && weekdayFits;
  }

  ///-----VALIDATE-----
  //todo move + explain
  bool _dateIsValid = true;

  ///-
  //def: tests if the current whenDate is still valid
  //assert: -
  //purpose: used for intersection() & tests
  //expects: valid if year>0 & 13>month>0 & 8>weekday>0 & 32>day
  //returns: true
  bool isValidWhenDate() {
    ///if whenDate is already invalid
    if (_dateIsValid == false) {
      return false;
    }

    ///else test
    //basic tests: if any fails -> date is invalid
    final bool yearIsValid = _yearIsVariable() || year! >= 0;
    final bool monthIsValid = _monthIsVariable() || 13 > month! && month! > 0;
    final bool weekdayIsValid =
        _weekdayIsVariable() || 8 > weekday! && weekday! > 0;
    final bool dayIsValid = _dayIsVariable() || 32 > day! && day! > 0;
    if (!yearIsValid | !monthIsValid | !weekdayIsValid | !dayIsValid) {
      _dateIsValid = false;
      return false;
    }

    ///else more tests
    else {
      ///if date is variable
      if (_dayIsVariable() | _monthIsVariable() | _yearIsVariable()) {
        return true;
      }

      ///else date is fixed
      else {
        try {
          //will throw error if date is not parse-able e.g. any is null
          final DateTime date =
              DateFormat('dd MM yyyy').parseStrict('$day $month $year');
          //if weekday is variable -> true - else check if date fits with weekday
          if (_weekdayIsVariable() || weekday == date.weekday) {
            return true;
          }
        } catch (e) {
          //
        }
        return false;
      }
    }
  }

  //def: compare this. values with another whenDate
  //purpose: for testing only
  //return: true when equal
  @visibleForTesting
  bool testCompare(WhenDate date) {
    final bool bothInvalid = !(isValidWhenDate() & date.isValidWhenDate());
    final bool variablesEqual = date.day == day &&
        date.weekday == weekday &&
        date.month == month &&
        date.year == year;
    return bothInvalid || variablesEqual;
  }
}

//doc: when supports the specification of a time in format: hh:mm
//
class WhenTime {
  WhenTime({
    required this.hour,
    required this.minute,
  });

  factory WhenTime.fromDateTime(DateTime dateTime) {
    return WhenTime(hour: dateTime.hour, minute: dateTime.minute);
  }

  factory WhenTime.zero() {
    return WhenTime(hour: 0, minute: 0);
  }

  int hour;
  int minute;

  //return: in format "hh:mm"
  String asString() {
    return '$hour:$minute';
  }

  //purpose: for testing only
  bool isEqual(WhenTime whenTime) {
    return hour == whenTime.hour && minute == whenTime.minute;
  }
}
