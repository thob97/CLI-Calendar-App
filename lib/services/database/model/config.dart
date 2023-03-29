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
    this.commend_issueLabel,
    this.commend_issueFileDirPath,
    this.commend_customCommitMsg,
    this.commend_calendarFilePath,
    this.commend_maxDisplayedIssues,
    this.commend_newTodoPlaceholderTitle,
    this.commend_monthsBack,
    this.commend_monthsAhead,
    this.comment_enableNotifications,
    this.comment_notifyOffsetInHours,
    this.comment_notifyAtDaysBefore,
    required this.enableNotifications,
    required this.notifyOffsetInHours,
    required this.notifyAtDaysBefore,
    required this.issueLabel,
    required this.issueFileDirPath,
    required this.customCommitMsg, //=null
    required this.calendarFilePath,
    required this.maxDisplayedIssues,
    required this.newTodoPlaceholderTitle,
    required this.monthsBack,
    required this.monthsAhead,
  })  : assert(monthsBack >= 0),
        assert(monthsAhead >= 1); //min 1
  //todo: test assert (don't crash on wrong input) when fetched from github
  //todo assert & test all values

  ///default settings
  factory Config.defaultSettings({required String calendarFilePath}) {
    return Config(
      commend_issueLabel: 'The label the issues created by the app will have',
      issueLabel: 'TodoList',
      commend_issueFileDirPath:
          'Path to a dir in which the issue files will be stored',
      issueFileDirPath: 'assets',
      commend_customCommitMsg:
          'The message which will be committed when uploading issue files. If null the default format of "issue <num>: add <filename>" is used',
      customCommitMsg: null,
      commend_maxDisplayedIssues:
          'The maximum allowed number of issues to display in the app',
      maxDisplayedIssues: 10,
      commend_newTodoPlaceholderTitle:
          'The placeholder title which will be displayed when creating a new issue',
      newTodoPlaceholderTitle: 'New Issue',
      commend_monthsAhead:
          'The amount of months the calendar will look ahead before needing to recalculate. A lower value will mean faster calculation.',
      monthsAhead: 3,
      commend_monthsBack:
          'The amount of months the calendar will look back before needing to recalculate. A lower value will mean faster calculation.',
      monthsBack: 1,
      commend_calendarFilePath: 'The file path to the calendar file',
      calendarFilePath: calendarFilePath,
      comment_enableNotifications:
          'Whenever notifications should be enabled in app',
      enableNotifications: true,
      comment_notifyOffsetInHours:
          'The amount of hours before the appointment the app should send a notification',
      notifyOffsetInHours: 1,
      comment_notifyAtDaysBefore:
          'At which day before the appointment the app should send a notification. 0 meaning on the same day. Please consider that iOS has a limit of 64 scheduled notifications, so on big differences in days like [0,100] the 100 days notifications may not work',
      notifyAtDaysBefore: [0, 1],
    );
  }

  factory Config.fromJson(Map<String, dynamic> json) => _$ConfigFromJson(json);
  final String? commend_issueLabel;
  final String issueLabel;
  final String? commend_issueFileDirPath;
  final String issueFileDirPath;
  final String? commend_customCommitMsg;
  final String? customCommitMsg;
  final String? commend_calendarFilePath;
  final String calendarFilePath;
  final String? commend_maxDisplayedIssues;
  final int maxDisplayedIssues;
  final String? commend_newTodoPlaceholderTitle;
  final String newTodoPlaceholderTitle;
  final String? commend_monthsBack;
  final int monthsBack;
  final String? commend_monthsAhead;
  final int monthsAhead;
  final String? comment_enableNotifications;
  final bool enableNotifications;
  final String? comment_notifyOffsetInHours;
  final int notifyOffsetInHours;
  final String? comment_notifyAtDaysBefore;
  final List<int> notifyAtDaysBefore;

  Map<String, dynamic> toJson() => _$ConfigToJson(this);
}
