import 'package:cli_calendar_app/parser/when_parser.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ///
  group('uniqueMatchIndex', () {
    test('expected input', () {
      String? res = uniquePrefixMatch(
        'mon',
        ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'sunday'],
      );
      expect(res, 'monday');
      res = uniquePrefixMatch(
        'thu',
        ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'sunday'],
      );
      expect(res, 'thursday');
      res = uniquePrefixMatch(
        'thutietie',
        ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'sunday'],
      );
      expect(res, 'thursday');
      res = uniquePrefixMatch(
        'mon.....',
        ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'sunday'],
      );
      expect(res, 'monday');
      res = uniquePrefixMatch(
        'thu...',
        ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'sunday'],
      );
      expect(res, 'thursday');
    });
    test('empty input', () {
      String? res = uniquePrefixMatch(
        '',
        ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'sunday'],
      );
      expect(res, null);
      res = uniquePrefixMatch('thu', []);
      expect(res, null);
      res = uniquePrefixMatch('', []);
      expect(res, null);
    });
    test('no unique match input (random)', () {
      final String? res =
          uniquePrefixMatch('tiemtcietietiectieon', ['motcienday', 'ctiecti']);
      expect(res, null);
    });
  });
  group('weekdayToInt', () {
    group('all valid inputs (weekdays)', () {
      test('normal formatted', () {
        expect(weekdayToInt('monday'), 1);
        expect(weekdayToInt('tuesday'), 2);
        expect(weekdayToInt('wednesday'), 3);
        expect(weekdayToInt('thursday'), 4);
        expect(weekdayToInt('friday'), 5);
        expect(weekdayToInt('saturday'), 6);
        expect(weekdayToInt('sunday'), 7);
      });
      test('case sensitive inputs', () {
        expect(weekdayToInt('MONDAY'), 1);
        expect(weekdayToInt('TUEsday'), 2);
        expect(weekdayToInt('Wednesday'), 3);
        expect(weekdayToInt('thursdaY'), 4);
      });
    });

    test('invalid input', () {
      expect(() => weekdayToInt('tiecie'), throwsAssertionError);
    });
  });
  group('monthToInt', () {
    group('all valid inputs (months)', () {
      test('normal formatted', () {
        expect(monthToInt('january'), 1);
        expect(monthToInt('february'), 2);
        expect(monthToInt('march'), 3);
        expect(monthToInt('april'), 4);
        expect(monthToInt('may'), 5);
        expect(monthToInt('june'), 6);
        expect(monthToInt('july'), 7);
        expect(monthToInt('august'), 8);
        expect(monthToInt('september'), 9);
        expect(monthToInt('october'), 10);
        expect(monthToInt('november'), 11);
        expect(monthToInt('december'), 12);
      });
      test('case sensitive', () {
        expect(monthToInt('MAY'), 5);
        expect(monthToInt('JUne'), 6);
        expect(monthToInt('July'), 7);
        expect(monthToInt('auguST'), 8);
      });
    });
    test('invalid input', () {
      expect(() => monthToInt('tiecie'), throwsAssertionError);
    });
  });
  group('parseWhenDay', () {
    test('valid input', () {
      expect(parseWhenDay('1'), 1);
      expect(parseWhenDay('16'), 16);
      expect(parseWhenDay('31'), 31);
    });
    test('invalid input', () {
      expect(parseWhenDay('32'), -1);
      expect(parseWhenDay('3200'), -1);
      expect(parseWhenDay('0'), -1);
      expect(parseWhenDay('-1'), -1);
      expect(parseWhenDay('-5640658'), -1);
    });
    test('invalid format', () {
      expect(() => parseWhenDay('te sy'), throwsAssertionError);
      expect(() => parseWhenDay(' '), throwsAssertionError);
    });
  });
  group('parseWhenWeekday', () {
    test('digit input', () {
      expect(parseWhenWeekday('1'), 1);
      expect(parseWhenWeekday('7'), 7);
      expect(parseWhenWeekday('4'), 4);
    });
    test('string input', () {
      expect(parseWhenWeekday('monday'), 1);
      expect(parseWhenWeekday('sunday'), 7);
      expect(parseWhenWeekday('thursday'), 4);
    });
    test('invalid input', () {
      expect(parseWhenWeekday('tiecie'), -1);
      expect(parseWhenWeekday(''), -1);
      expect(parseWhenWeekday('-1'), -1);
      expect(parseWhenWeekday('-5640658'), -1);
    });
    test('invalid format', () {
      expect(() => parseWhenWeekday('tes y'), throwsAssertionError);
      expect(() => parseWhenDay(' '), throwsAssertionError);
    });
  });
  group('parseWhenMonth', () {
    test('digit input', () {
      expect(parseWhenMonth('1'), 1);
      expect(parseWhenMonth('7'), 7);
      expect(parseWhenMonth('12'), 12);
    });
    test('string input', () {
      expect(parseWhenMonth('january'), 1);
      expect(parseWhenMonth('december'), 12);
      expect(parseWhenMonth('june'), 6);
    });
    test('invalid input', () {
      expect(parseWhenMonth('tiecie'), -1);
      expect(parseWhenMonth(''), -1);
      expect(parseWhenMonth('-1'), -1);
      expect(parseWhenMonth('-13056406'), -1);
    });
    test('invalid format', () {
      expect(() => parseWhenMonth('tes y'), throwsAssertionError);
      expect(() => parseWhenMonth(' '), throwsAssertionError);
    });
  });
  group('parseWhenYear', () {
    test('valid input', () {
      expect(parseWhenYear('1'), 1);
      expect(parseWhenYear('2023'), 2023);
      expect(parseWhenYear('3000'), 3000);
    });
    test('invalid input', () {
      expect(parseWhenYear('0'), -1);
      expect(parseWhenYear('-1'), -1);
      expect(parseWhenYear('-5640658'), -1);
    });
    test('invalid format', () {
      expect(() => parseWhenMonth('tes y'), throwsAssertionError);
      expect(() => parseWhenMonth(' '), throwsAssertionError);
    });
  });
  //todo
  group('WhenDate: ', () {
    group('isValidWhenDate()', () {
      test('valid input: date', () {
        expect(WhenDate(day: 28, year: 2023, month: 2).isValidWhenDate(), true);
        expect(
          WhenDate(day: 28, year: 2023, month: 2, weekday: 2).isValidWhenDate(),
          true,
          reason: 'test weekday',
        );
        expect(WhenDate(day: 1, year: 1, month: 1).isValidWhenDate(), true);
        expect(WhenDate(day: 1, year: 2023, month: 1).isValidWhenDate(), true);
        expect(WhenDate(day: 31, year: 2023, month: 3).isValidWhenDate(), true);
        expect(
          WhenDate(day: 29, year: 2023, month: 12).isValidWhenDate(),
          true,
        );
        expect(
          WhenDate(day: 24, year: 2023, month: 12, weekday: 7)
              .isValidWhenDate(),
          true,
          reason: 'test weekday',
        );
        expect(
          WhenDate(day: 18, year: 2023, month: 12, weekday: 1)
              .isValidWhenDate(),
          true,
          reason: 'test weekday',
        );
      });
      test('valid input: variable date', () {
        expect(WhenDate(year: 1, month: 1).isValidWhenDate(), true);
        expect(WhenDate(day: 1, month: 1).isValidWhenDate(), true);
        expect(
          WhenDate(
            day: 1,
            year: 1,
          ).isValidWhenDate(),
          true,
        );
        expect(
          WhenDate(
            day: 1,
          ).isValidWhenDate(),
          true,
        );
        expect(WhenDate(year: 1).isValidWhenDate(), true);
        expect(WhenDate(month: 1).isValidWhenDate(), true);
        expect(WhenDate().isValidWhenDate(), true);
      });
      test('invalid input: dates', () {
        expect(
          WhenDate(day: 29, year: 2023, month: 2).isValidWhenDate(),
          false,
          reason: 'day',
        );
        expect(
          WhenDate(day: 28, year: 2023, month: 2, weekday: 1).isValidWhenDate(),
          false,
          reason: 'weekday',
        );
        expect(WhenDate(day: 1, year: 1, month: 0).isValidWhenDate(), false);
        expect(WhenDate(day: 1, year: -1, month: 1).isValidWhenDate(), false);
        expect(WhenDate(day: 0, year: 1, month: 1).isValidWhenDate(), false);
        expect(WhenDate(day: 0, year: -1, month: 0).isValidWhenDate(), false);
        expect(WhenDate(day: 32, year: 1, month: 1).isValidWhenDate(), false);
        expect(WhenDate(day: 1, year: 1, month: 13).isValidWhenDate(), false);
      });
      group('fixed Date', () {
        test('valid input: date', () {
          expect(
            WhenDate(day: 28, year: 2023, month: 2).isValidWhenDate(),
            true,
          );
          expect(
            WhenDate(day: 28, year: 2023, month: 2, weekday: 2)
                .isValidWhenDate(),
            true,
          );
          expect(WhenDate(day: 1, year: 1, month: 1).isValidWhenDate(), true);
          expect(
            WhenDate(day: 1, year: 2023, month: 1).isValidWhenDate(),
            true,
          );
          expect(
            WhenDate(day: 31, year: 2023, month: 3).isValidWhenDate(),
            true,
          );
          expect(
            WhenDate(day: 29, year: 2023, month: 12).isValidWhenDate(),
            true,
          );
          expect(
            WhenDate(day: 24, year: 2023, month: 12, weekday: 7)
                .isValidWhenDate(),
            true,
          );
          expect(
            WhenDate(day: 18, year: 2023, month: 12, weekday: 1)
                .isValidWhenDate(),
            true,
          );
        });

        test('invalid input: dates', () {
          expect(
            WhenDate(day: 29, year: 2023, month: 2).isValidWhenDate(),
            false,
            reason: 'day',
          );
          expect(
            WhenDate(day: 28, year: 2023, month: 2, weekday: 1)
                .isValidWhenDate(),
            false,
            reason: 'weekday',
          );
          expect(WhenDate(day: 1, year: 1, month: 0).isValidWhenDate(), false);
          expect(WhenDate(day: 1, year: -1, month: 1).isValidWhenDate(), false);
          expect(WhenDate(day: 0, year: 1, month: 1).isValidWhenDate(), false);
          expect(WhenDate(day: 0, year: -1, month: 0).isValidWhenDate(), false);
          expect(WhenDate(day: 32, year: 1, month: 1).isValidWhenDate(), false);
          expect(WhenDate(day: 1, year: 1, month: 13).isValidWhenDate(), false);
        });
      });
    });
  });

  group('parseFixedDate()', () {
    group('valid input', () {
      test('expected input', () {
        expect(
          parseFixedDate('2023 2 28')
              .testCompare(WhenDate(day: 28, year: 2023, month: 2)),
          true,
        );
        expect(
          parseFixedDate('1 1 1')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
        expect(
          parseFixedDate('1 12 1')
              .testCompare(WhenDate(day: 1, year: 1, month: 12)),
          true,
        );
        expect(
          parseFixedDate('1 12 31')
              .testCompare(WhenDate(day: 31, year: 1, month: 12)),
          true,
        );
        expect(
          parseFixedDate('1 jan 1')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
        expect(
          parseFixedDate('1 janua 1')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
        expect(
          parseFixedDate('1 january 1')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
      });
      test('valid input with many whitespaces', () {
        expect(
          parseFixedDate('   2023 2 28')
              .testCompare(WhenDate(day: 28, year: 2023, month: 2)),
          true,
        );
        expect(
          parseFixedDate('1    1 1')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
        expect(
          parseFixedDate('1 12    1')
              .testCompare(WhenDate(day: 1, year: 1, month: 12)),
          true,
        );
        expect(
          parseFixedDate('1    12    31')
              .testCompare(WhenDate(day: 31, year: 1, month: 12)),
          true,
        );
        expect(
          parseFixedDate('   1    jan    1  ')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
        expect(
          parseFixedDate('   1  janua  1')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
        expect(
          parseFixedDate('1       january   1')
              .testCompare(WhenDate(day: 1, year: 1, month: 1)),
          true,
        );
      });
    });
    test('invalid input: date', () {
      expect(parseFixedDate('2023 2 30').testCompare(WhenDate.invalid()), true);
      expect(parseFixedDate('2023 2 32').testCompare(WhenDate.invalid()), true);
      expect(
        parseFixedDate('2023 13 32').testCompare(WhenDate.invalid()),
        true,
      );
      expect(parseFixedDate('2023 0 32').testCompare(WhenDate.invalid()), true);
      expect(parseFixedDate('2023 0 0').testCompare(WhenDate.invalid()), true);
      expect(parseFixedDate('2023 -1 0').testCompare(WhenDate.invalid()), true);
      expect(
        parseFixedDate('2023 -1 -1').testCompare(WhenDate.invalid()),
        true,
      );
      expect(parseFixedDate('-1 -1 -1').testCompare(WhenDate.invalid()), true);
      expect(parseFixedDate('-1 1 -1').testCompare(WhenDate.invalid()), true);
      expect(parseFixedDate('-1 1 1').testCompare(WhenDate.invalid()), true);
      expect(parseFixedDate(' dec 1 1').testCompare(WhenDate.invalid()), true);
      expect(
        parseFixedDate(' dec dec 1').testCompare(WhenDate.invalid()),
        true,
      );
      expect(
        parseFixedDate(' dec dec dec').testCompare(WhenDate.invalid()),
        true,
      );
      expect(
        parseFixedDate(' 1 dec dec').testCompare(WhenDate.invalid()),
        true,
      );
      expect(parseFixedDate(' 1 1 dec').testCompare(WhenDate.invalid()), true);
    });

    test('invalid format', () {
      expect(() => parseFixedDate('t 2023  2  28'), throwsException);
      expect(() => parseFixedDate('  2  28'), throwsException);
      expect(() => parseFixedDate('  28'), throwsException);
      expect(() => parseFixedDate(''), throwsException);
      expect(() => parseFixedDate('  '), throwsException);
      expect(() => parseFixedDate('       '), throwsException);
    });
  });
  group('parseVariableValueEquation()', () {
    test('expected input', () {
      expect(parseVariableValueEquation('w=1'), ['w', '1']);
      expect(parseVariableValueEquation('d=10'), ['d', '10']);
      expect(parseVariableValueEquation('m=12'), ['m', '12']);
      expect(parseVariableValueEquation('y=2100'), ['y', '2100']);
    });
    test('valid input with many whitespaces, case sensitive, random chars', () {
      expect(parseVariableValueEquation('   W   =  1100    '), ['w', '1100']);
      expect(parseVariableValueEquation('   W=  1100    '), ['w', '1100']);
      expect(parseVariableValueEquation('x=  1100    '), ['x', '1100']);
      expect(parseVariableValueEquation('b=1100    '), ['b', '1100']);
      expect(parseVariableValueEquation('W=1100'), ['w', '1100']);
      expect(parseVariableValueEquation('i=  du{}<aedue'), ['i', 'du{}<aedue']);
      expect(parseVariableValueEquation('W =  /><{}    '), ['w', '/><{}']);
      expect(parseVariableValueEquation(' W=  iiedu    '), ['w', 'iiedu']);
      expect(parseVariableValueEquation('D  =  tietie    '), ['d', 'tietie']);
    });
    test('invalid format', () {
      expect(parseVariableValueEquation('   W   D   =  1100    '), null);
      expect(parseVariableValueEquation('   WD=  11  00    '), null);
      expect(parseVariableValueEquation('t   xd=  1100    '), null);
      expect(parseVariableValueEquation('back==1100    '), null);
      expect(parseVariableValueEquation('WD=110=0'), null);
      expect(parseVariableValueEquation('iei==etc=  duaedue'), null);
      expect(parseVariableValueEquation('i  WD =  1100    '), null);
      expect(parseVariableValueEquation(' Wti       cetieD=  iiedu    '), null);
      expect(parseVariableValueEquation(' WD  =  tie      tie    '), null);
    });
  });
  group('solveVariableValueEquation()', () {
    group('valid input', () {
      test('expected input', () {
        expect(
          solveVariableValueEquation('w=1').testCompare(WhenDate(weekday: 1)),
          true,
        );
        expect(
          solveVariableValueEquation('m=1').testCompare(WhenDate(month: 1)),
          true,
        );
        expect(
          solveVariableValueEquation('d=1').testCompare(WhenDate(day: 1)),
          true,
        );
        expect(
          solveVariableValueEquation('y=1').testCompare(WhenDate(year: 1)),
          true,
        );
      });
      test('valid input with many whitespaces and case sensitive', () {
        expect(
          solveVariableValueEquation('W =1').testCompare(WhenDate(weekday: 1)),
          true,
        );
        expect(
          solveVariableValueEquation(' m   =  1  ')
              .testCompare(WhenDate(month: 1)),
          true,
        );
        expect(
          solveVariableValueEquation('     D  =1  ')
              .testCompare(WhenDate(day: 1)),
          true,
        );
        expect(
          solveVariableValueEquation('y          = 1     ')
              .testCompare(WhenDate(year: 1)),
          true,
        );
      });
    });
    group('invalid format', () {
      test('empty input', () {
        expect(() => solveVariableValueEquation(''), throwsException);
        expect(() => solveVariableValueEquation(' '), throwsException);
        expect(() => solveVariableValueEquation('       '), throwsException);
      });
      test('invalid format', () {
        expect(() => solveVariableValueEquation('w=1 1'), throwsException);
        expect(() => solveVariableValueEquation('mm=1'), throwsException);
        expect(() => solveVariableValueEquation('d= =1'), throwsException);
        expect(() => solveVariableValueEquation('==='), throwsException);
        expect(() => solveVariableValueEquation(' ite=tie='), throwsException);
        expect(() => solveVariableValueEquation('tiensrtie'), throwsException);
        expect(() => solveVariableValueEquation('m=1 13'), throwsException);
        expect(() => solveVariableValueEquation('y1=1'), throwsException);
      });
    });
  });
  group('unionWhenDates()', () {
    test('expected input', () {
      final date1 = WhenDate(year: 1);
      final date2 = WhenDate(year: 2);
      expect(unionWhenDates([date1], [date2]), [date1, date2]);
    });
    test('valid input with emtpy lists', () {
      final date2 = WhenDate(year: 2);
      expect(unionWhenDates([], [date2]), [date2]);
      expect(unionWhenDates([date2], []), [date2]);
      expect(unionWhenDates([], []), []);
    });
  });
  group('intersectWhenDates()', () {
    test('expected input: single item', () {
      ///1
      var date1 = WhenDate(month: 1, day: 1);
      var date2 = WhenDate(year: 2);
      var intersected = intersectWhenDates([date1], [date2]);
      expect(intersected.length, 1);
      expect(
        intersected.first.testCompare(WhenDate(year: 2, month: 1, day: 1)),
        true,
      );

      ///2
      date1 = WhenDate(month: 12, day: 31);
      date2 = WhenDate(year: 2023);
      intersected = intersectWhenDates([date1], [date2]);
      expect(intersected.length, 1);
      expect(
        intersected.first.testCompare(WhenDate(year: 2023, month: 12, day: 31)),
        true,
      );
    });
    test('invalid input dates: item will be removed', () {
      ///3
      final date1 = WhenDate(month: 0, day: 0);
      final date2 = WhenDate(year: -1, weekday: 7);
      final intersected = intersectWhenDates([date1], [date2]);
      expect(intersected.length, 0);
    });
    test('expected input: multiple items', () {
      final date1 = WhenDate(month: 1, day: 1);
      final date2 = WhenDate(year: 2);
      final date3 = WhenDate(year: 3);
      final intersected = intersectWhenDates([date1], [date2, date3]);
      expect(intersected.length, 2);
      expect(
        intersected.first.testCompare(WhenDate(year: 2, month: 1, day: 1)),
        true,
      );
      expect(
        intersected[1].testCompare(WhenDate(year: 3, month: 1, day: 1)),
        true,
      );
    });
    test('valid input with emtpy lists', () {
      final date2 = WhenDate(year: 2);
      expect(intersectWhenDates([], [date2]), []);
      expect(intersectWhenDates([date2], []), []);
      expect(intersectWhenDates([], []), []);
    });
    test('invalid input (not intersect-able items)', () {
      final date1 = WhenDate(month: 1, day: 1);
      final date2 = WhenDate(year: 2, month: 2);
      final date3 = WhenDate(year: 3);
      final intersected = intersectWhenDates([date1], [date2, date3]);
      expect(intersected.length, 1);
      expect(
        intersected.first.testCompare(WhenDate(year: 3, month: 1, day: 1)),
        true,
      );
    });
  });
  group('isOperator()', () {
    test('valid input', () {
      expect(isOperator('&'), true);
      expect(isOperator('|'), true);
      expect(isOperator('%'), true);
      expect(isOperator('-'), true);
      expect(isOperator('<'), true);
      expect(isOperator('<='), true);
      expect(isOperator('>'), true);
      expect(isOperator('>='), true);
      expect(isOperator('='), true);
      expect(isOperator('!'), true);
      expect(isOperator('!='), true);
    });
    test('empty input and whitespaces', () {
      expect(isOperator(''), false);
      expect(isOperator('   '), false);
      expect(isOperator('         '), false);
    });
    test('invalid input', () {
      expect(isOperator('tiectie'), false);
      expect(isOperator(' eitceobei  '), false);
      expect(isOperator('itecit&'), false);
      expect(isOperator('|tie'), false);
      expect(isOperator('%  '), false);
      expect(isOperator('  -'), false);
      expect(isOperator('tie<tie'), false);
      expect(isOperator(' <= '), false);
      expect(isOperator('   >etietie'), false);
      expect(isOperator('>eit='), false);
      expect(isOperator('eii= '), false);
      expect(isOperator('!  '), false);
      expect(isOperator('!  ='), false);
    });
  });

  group('splitWhenLine()', () {
    test('valid input', () {
      expect(
        const ListEquality().equals(
          splitWhenLine('2022 02 13, 10:10 - 10:20 tests'),
          ['2022 02 13', ' 10:10 - 10:20 tests'],
        ),
        true,
      );
      expect(
        const ListEquality().equals(
          splitWhenLine('2022 02 13, 10:10 - 0:20 ,tests,'),
          ['2022 02 13', ' 10:10 - 0:20 ,tests,'],
        ),
        true,
      );
      expect(
        const ListEquality().equals(
          splitWhenLine('w=2 & d=02 & m=13, 10:10a - 0:20p tests'),
          ['w=2 & d=02 & m=13', ' 10:10a - 0:20p tests'],
        ),
        true,
      );
      expect(
        const ListEquality().equals(
          splitWhenLine('w=2 & d=02 & m=13, tests 10:10'),
          ['w=2 & d=02 & m=13', ' tests 10:10'],
        ),
        true,
      );
      expect(
        const ListEquality().equals(
          splitWhenLine('w=2 & d=02 & m=13, tests'),
          ['w=2 & d=02 & m=13', ' tests'],
        ),
        true,
      );
    });
    test('empty input and whitespaces & gibberish', () {
      expect(
        const ListEquality().equals(
          splitWhenLine(
            '        2022 02 13,        10:10 - 10:20 tests       ',
          ),
          ['        2022 02 13', '        10:10 - 10:20 tests       '],
        ),
        true,
      );
      expect(
        const ListEquality().equals(splitWhenLine(' ,  '), [' ', '  ']),
        true,
      );
      expect(
        const ListEquality().equals(
          splitWhenLine(' itetie, tie,ti,etie '),
          [' itetie', ' tie,ti,etie '],
        ),
        true,
      );
    });
    test('invalid input', () {
      expect(() => splitWhenLine('  '), throwsException);
      expect(() => splitWhenLine(' tietcie '), throwsException);
      expect(
        () => splitWhenLine(' w=2 & d=02 & m=13 - tests '),
        throwsException,
      );
    });
  });
  test('removeWhenComment()', () {
    expect(removeWhenComment(''), '');
    expect(removeWhenComment('#'), '');
    expect(removeWhenComment(' '), ' ');
    expect(removeWhenComment(' #'), ' ');
    expect(removeWhenComment('# '), '');
    expect(removeWhenComment('      '), '      ');
    expect(removeWhenComment('#      '), '');
    expect(removeWhenComment('      #'), '      ');
    expect(removeWhenComment('   #   #'), '   ');
    expect(
      removeWhenComment('2022 02 13, 10:10 - 10:20 tests'),
      '2022 02 13, 10:10 - 10:20 tests',
    );
    expect(
      removeWhenComment('2022 02 13, 10:10 - 10:20 tests#'),
      '2022 02 13, 10:10 - 10:20 tests',
    );
    expect(
      removeWhenComment('2022 02 13, 10:10 - #10:20 tests#'),
      '2022 02 13, 10:10 - ',
    );
    expect(removeWhenComment('#2022 02 13, 10:10 - #10:20 tests#'), '');
  });
  group('parseWhenTime()', () {
    test('valid input', () {
      expect(
        parseWhenTime('10:20').first.isEqual(WhenTime(hour: 10, minute: 20)),
        true,
      );
      expect(
        parseWhenTime('10:20 20:20')[1].isEqual(WhenTime(hour: 20, minute: 20)),
        true,
      );
      expect(
        parseWhenTime('xd 10:20  20:20-  ')[0]
            .isEqual(WhenTime(hour: 10, minute: 20)),
        true,
      );
      expect(
        parseWhenTime('xd 10:20  20:20-  ')[1]
            .isEqual(WhenTime(hour: 20, minute: 20)),
        true,
      );
      expect(
        parseWhenTime('xd 10:20a  20:20a-  ')[0]
            .isEqual(WhenTime(hour: 10, minute: 20)),
        true,
      );
      expect(
        parseWhenTime('xd 10:20p  20:20a-  ')[0]
            .isEqual(WhenTime(hour: 22, minute: 20)),
        true,
      );
    });
    test('empty input and whitespaces & gibberish', () {
      expect(
        parseWhenTime('ite/{} ua_]ie ie 1010506460 5406542')[0]
            .isEqual(WhenTime.zero()),
        true,
      );
      expect(parseWhenTime('')[0].isEqual(WhenTime.zero()), true);
      expect(parseWhenTime('    ')[0].isEqual(WhenTime.zero()), true);
    });
    test('invalid input', () {
      expect(parseWhenTime('25:25 10:00')[0].isEqual(WhenTime.zero()), true);
      expect(parseWhenTime('100:01')[0].isEqual(WhenTime.zero()), true);
      expect(parseWhenTime('00:010')[0].isEqual(WhenTime.zero()), true);
      expect(parseWhenTime('10:10 10:65')[0].isEqual(WhenTime.zero()), true);
      expect(parseWhenTime('10:10 13:10p')[0].isEqual(WhenTime.zero()), true);
    });
  });

  group('solveNestedAppointment()', () {
    test('valid input', () {
      ///test1
      var date1 = WhenDate(day: 1, month: 2);
      var date2 = WhenDate(year: 3, weekday: 1);
      var dates = solveNestedVariableWhenDate('((d=1 & m=2) | (y=3 & w=1))');
      expect(dates.length, 2);
      expect(dates[0].testCompare(date1), true);
      expect(dates[1].testCompare(date2), true);

      ///test2 with different format: whitespaces
      date1 = WhenDate(day: 1, month: 2);
      date2 = WhenDate(year: 3, weekday: 1);
      dates = solveNestedVariableWhenDate(
        '((  d  = 1    & m = 2) | (  y=3 &   w=  1)  )',
      );
      expect(dates.length, 2);
      expect(dates[0].testCompare(date1), true);
      expect(dates[1].testCompare(date2), true);
    });
    test('invalid format: wrong num of parentheses', () {
      expect(
        () => solveNestedVariableWhenDate('(((d=1 & m=2) | (y=3 & w=1))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('((d=1 & m=2) | (y=3 & w=1)))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('d=1 & m=2) | (y=3 & w=1)))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('((d=1 & m=2 | (y=3 & w=1)))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('((d=1 & m=2 | y=3 & w=1))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('d=1 & m=2 | y=3 & w=1'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('(d=1 & m=2) | y=3 & w=1'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('(d=1 & m=2 | y=3 & w=1)'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('(d=1 & m=2 | (y=3 & w=1)()'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('((d=1 & m=2) | ()(y=3 & w=1))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('((d=1 & m=2)() | (y=3 & w=1)))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('((d=1 & m=2) | (y=3 & w=1))()'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('()()d=1 & m=2 | y=3 & w=1'),
        throwsException,
      );
    });
    test('invalid input: gibberish', () {
      expect(() => solveNestedVariableWhenDate('tiectie'), throwsException);
      expect(
        () => solveNestedVariableWhenDate(' eitceobei  '),
        throwsException,
      );
      expect(() => solveNestedVariableWhenDate('itecit&'), throwsException);
      expect(
        () => solveNestedVariableWhenDate('tiectie{}/{_[2 | (y=3 & w=1)))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate('d=1 & m=}{/[_}{/{} | y=3 & w=1'),
        throwsException,
      );
      expect(() => solveNestedVariableWhenDate('/{}/[/}/['), throwsException);
      expect(
        () => solveNestedVariableWhenDate('((d=1 & m=2) | ()(y=3 & w=1))'),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate(
          '((d=1 & tieti/{}/{}/{}=2)() | (y=3 & w=1)))',
        ),
        throwsException,
      );
      expect(
        () => solveNestedVariableWhenDate(
          '((d=1 & u_{]_[]m=2) | (y=3 & w=1))()',
        ),
        throwsException,
      );
      expect(() => solveNestedVariableWhenDate(''), throwsException);
      expect(() => solveNestedVariableWhenDate('     '), throwsException);
      expect(() => solveNestedVariableWhenDate('           '), throwsException);
    });
  });

  group('parseWhenLine()', () {
    test('valid input', () {
      ///fixed date
      WhenAppointment? whenAppointment = WhenParser()
          .parseWhenLine('  2022 12  25, 10:10 this is a test #comment');
      expect(whenAppointment != null, true);
      expect(whenAppointment!.description, ' 10:10 this is a test ');
      expect(
        whenAppointment.startTime.isEqual(WhenTime(hour: 10, minute: 10)),
        true,
      );
      expect(whenAppointment.endTime.isEqual(WhenTime.zero()), true);
      expect(whenAppointment.dates.length == 1, true);
      expect(
        whenAppointment.dates.first
            .testCompare(WhenDate(year: 2022, month: 12, day: 25)),
        true,
      );

      ///variable date
      whenAppointment = WhenParser().parseWhenLine(
        '((m=2 | d=10) & y=2022), 10:10 this is a test #comment',
      );
      expect(whenAppointment != null, true);
      expect(whenAppointment!.description, ' 10:10 this is a test ');
      expect(
        whenAppointment.startTime.isEqual(WhenTime(hour: 10, minute: 10)),
        true,
      );
      expect(whenAppointment.endTime.isEqual(WhenTime.zero()), true);
      expect(whenAppointment.dates.length == 2, true);
      expect(
        whenAppointment.dates
            .any((date) => date.testCompare(WhenDate(year: 2022, month: 2))),
        true,
      );
      expect(
        whenAppointment.dates
            .any((date) => date.testCompare(WhenDate(year: 2022, day: 10))),
        true,
      );
    });
    test('empty input', () {
      expect(WhenParser().parseWhenLine(' '), null);
    });
    test('invalid input', () {
      ///fixed date
      WhenAppointment? whenAppointment = WhenParser()
          .parseWhenLine('  2202 13  25, 10:10 this is a test #comment');
      expect(whenAppointment != null, true);
      expect(whenAppointment!.description, ' 10:10 this is a test ');
      expect(
        whenAppointment.startTime.isEqual(WhenTime(hour: 10, minute: 10)),
        true,
      );
      expect(whenAppointment.endTime.isEqual(WhenTime.zero()), true);
      expect(whenAppointment.dates.length == 1, true);
      expect(whenAppointment.dates.first.testCompare(WhenDate.invalid()), true);

      ///fixed date
      whenAppointment = WhenParser()
          .parseWhenLine('  2202 12  25x, 10:10 this is a test #comment');
      expect(whenAppointment != null, true);
      expect(whenAppointment!.description, ' 10:10 this is a test ');
      expect(
        whenAppointment.startTime.isEqual(WhenTime(hour: 10, minute: 10)),
        true,
      );
      expect(whenAppointment.endTime.isEqual(WhenTime.zero()), true);
      expect(whenAppointment.dates.length == 1, true);
      expect(whenAppointment.dates.first.testCompare(WhenDate.invalid()), true);

      ///fixed date
      whenAppointment = WhenParser()
          .parseWhenLine(' 10 2202 12 , 10:10 this is a test #comment');
      expect(whenAppointment != null, true);
      expect(whenAppointment!.description, ' 10:10 this is a test ');
      expect(
        whenAppointment.startTime.isEqual(WhenTime(hour: 10, minute: 10)),
        true,
      );
      expect(whenAppointment.endTime.isEqual(WhenTime.zero()), true);
      expect(whenAppointment.dates.length == 1, true);
      expect(whenAppointment.dates.first.testCompare(WhenDate.invalid()), true);

      ///fixed date
      whenAppointment = WhenParser()
          .parseWhenLine(' 220u2 10 12 , 10:10 this is a test #comment');
      expect(whenAppointment != null, true);
      expect(whenAppointment!.description, ' 10:10 this is a test ');
      expect(
        whenAppointment.startTime.isEqual(WhenTime(hour: 10, minute: 10)),
        true,
      );
      expect(whenAppointment.endTime.isEqual(WhenTime.zero()), true);
      expect(whenAppointment.dates.length == 1, true);
      expect(whenAppointment.dates.first.testCompare(WhenDate.invalid()), true);

      ///variable date
      whenAppointment = WhenParser().parseWhenLine(
        '((m=2 | d=10) & y=2022xd), 10:10 this is a test #comment',
      );
      expect(whenAppointment != null, true);
      expect(whenAppointment!.description, ' 10:10 this is a test ');
      expect(
        whenAppointment.startTime.isEqual(WhenTime(hour: 10, minute: 10)),
        true,
      );
      expect(whenAppointment.endTime.isEqual(WhenTime.zero()), true);
      expect(whenAppointment.dates.isEmpty, true);
    });
    test('invalid format: gibberish', () {
      expect(
        WhenParser().parseWhenLine(' nrsesirtnsrnesrtn ulnmet lnmut'),
        null,
      );
      expect(
        WhenParser().parseWhenLine(' nrsesirtnsrnesrtn ulnmet ,lnmut'),
        null,
      );
    });
  });
}
