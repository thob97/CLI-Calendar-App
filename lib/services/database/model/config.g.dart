// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Config _$ConfigFromJson(Map<String, dynamic> json) => Config(
      commend_issueLabel: json['commend_issueLabel'] as String?,
      commend_issueFileDirPath: json['commend_issueFileDirPath'] as String?,
      commend_customCommitMsg: json['commend_customCommitMsg'] as String?,
      commend_calendarFilePath: json['commend_calendarFilePath'] as String?,
      commend_maxDisplayedIssues: json['commend_maxDisplayedIssues'] as String?,
      commend_newTodoPlaceholderTitle:
          json['commend_newTodoPlaceholderTitle'] as String?,
      commend_monthsBack: json['commend_monthsBack'] as String?,
      commend_monthsAhead: json['commend_monthsAhead'] as String?,
      comment_enableNotifications:
          json['comment_enableNotifications'] as String?,
      comment_notifyOffsetInHours:
          json['comment_notifyOffsetInHours'] as String?,
      comment_notifyAtDaysBefore: json['comment_notifyAtDaysBefore'] as String?,
      enableNotifications: json['enableNotifications'] as bool,
      notifyOffsetInHours: json['notifyOffsetInHours'] as int,
      notifyAtDaysBefore: (json['notifyAtDaysBefore'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
      issueLabel: json['issueLabel'] as String,
      issueFileDirPath: json['issueFileDirPath'] as String,
      customCommitMsg: json['customCommitMsg'] as String?,
      calendarFilePath: json['calendarFilePath'] as String,
      maxDisplayedIssues: json['maxDisplayedIssues'] as int,
      newTodoPlaceholderTitle: json['newTodoPlaceholderTitle'] as String,
      monthsBack: json['monthsBack'] as int,
      monthsAhead: json['monthsAhead'] as int,
    );

Map<String, dynamic> _$ConfigToJson(Config instance) => <String, dynamic>{
      'commend_issueLabel': instance.commend_issueLabel,
      'issueLabel': instance.issueLabel,
      'commend_issueFileDirPath': instance.commend_issueFileDirPath,
      'issueFileDirPath': instance.issueFileDirPath,
      'commend_customCommitMsg': instance.commend_customCommitMsg,
      'customCommitMsg': instance.customCommitMsg,
      'commend_calendarFilePath': instance.commend_calendarFilePath,
      'calendarFilePath': instance.calendarFilePath,
      'commend_maxDisplayedIssues': instance.commend_maxDisplayedIssues,
      'maxDisplayedIssues': instance.maxDisplayedIssues,
      'commend_newTodoPlaceholderTitle':
          instance.commend_newTodoPlaceholderTitle,
      'newTodoPlaceholderTitle': instance.newTodoPlaceholderTitle,
      'commend_monthsBack': instance.commend_monthsBack,
      'monthsBack': instance.monthsBack,
      'commend_monthsAhead': instance.commend_monthsAhead,
      'monthsAhead': instance.monthsAhead,
      'comment_enableNotifications': instance.comment_enableNotifications,
      'enableNotifications': instance.enableNotifications,
      'comment_notifyOffsetInHours': instance.comment_notifyOffsetInHours,
      'notifyOffsetInHours': instance.notifyOffsetInHours,
      'comment_notifyAtDaysBefore': instance.comment_notifyAtDaysBefore,
      'notifyAtDaysBefore': instance.notifyAtDaysBefore,
    };
