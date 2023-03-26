// ignore_for_file: non_constant_identifier_names, avoid_init_to_null
//purpose: ignore ^ for this file, as this file is read by the end user
//  -> make the variable names as read able as possible

import 'package:json_annotation/json_annotation.dart';

part 'config.g.dart';

//def: config file for app - should not be changeable in app but by pc
//purpose: upload to github so that this file can be changed by pc
//  has use full default settings preconfigured
@JsonSerializable(
  explicitToJson: false,
) //explicitToJson allows nested json classes
class Config {
  const Config({
    ///default settings
    this.issueLabelOfTodoEntries = 'TodoList',
    this.issueFileUploadDirPath = 'assets',
    this.customCommitMsg = null, //=null
    required this.calendarFilePath,
    this.maxNumberOfDisplayedTodosInApp = 10,
    this.placeholderTitleOnNewTodo = 'New Issue',
    this.lookBackMonthsBeforeRecalculatingCalendarFile_min0 = 1,
    this.lookAheadMonthsBeforeRecalculatingCalendarFile_min1 = 3,
  })  : assert(lookBackMonthsBeforeRecalculatingCalendarFile_min0 >= 0),
        assert(
          lookAheadMonthsBeforeRecalculatingCalendarFile_min1 >= 1,
        ); //min 1
//todo: test assert (don't crash on wrong input)

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
  final String issueLabelOfTodoEntries;
  final String issueFileUploadDirPath;
  final String? customCommitMsg;
  final String calendarFilePath;
  final int maxNumberOfDisplayedTodosInApp;
  final String placeholderTitleOnNewTodo;
  final int lookBackMonthsBeforeRecalculatingCalendarFile_min0;
  final int lookAheadMonthsBeforeRecalculatingCalendarFile_min1;

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}
