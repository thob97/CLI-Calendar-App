// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_null_in_if_null_operators

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
      issueLabelOfTodoEntries:
          json['issueLabelOfTodoEntries'] as String? ?? 'TodoList',
      issueFileUploadDirPath:
          json['issueFileUploadDirPath'] as String? ?? 'assets',
      customCommitMsg: json['customCommitMsg'] as String? ?? null,
      calendarFilePath: json['calendarFilePath'] as String,
      maxNumberOfDisplayedTodosInApp:
          json['maxNumberOfDisplayedTodosInApp'] as int? ?? 10,
      placeholderTitleOnNewTodo:
          json['placeholderTitleOnNewTodo'] as String? ?? 'New Issue',
      lookBackMonthsBeforeRecalculatingCalendarFile_min0:
          json['lookBackMonthsBeforeRecalculatingCalendarFile_min0'] as int? ??
              1,
      lookAheadMonthsBeforeRecalculatingCalendarFile_min1:
          json['lookAheadMonthsBeforeRecalculatingCalendarFile_min1'] as int? ??
              3,
    );

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'issueLabelOfTodoEntries': instance.issueLabelOfTodoEntries,
      'issueFileUploadDirPath': instance.issueFileUploadDirPath,
      'customCommitMsg': instance.customCommitMsg,
      'calendarFilePath': instance.calendarFilePath,
      'maxNumberOfDisplayedTodosInApp': instance.maxNumberOfDisplayedTodosInApp,
      'placeholderTitleOnNewTodo': instance.placeholderTitleOnNewTodo,
      'lookBackMonthsBeforeRecalculatingCalendarFile_min0':
          instance.lookBackMonthsBeforeRecalculatingCalendarFile_min0,
      'lookAheadMonthsBeforeRecalculatingCalendarFile_min1':
          instance.lookAheadMonthsBeforeRecalculatingCalendarFile_min1,
    };
