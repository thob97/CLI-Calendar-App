import 'dart:io';

import 'package:cli_calendar_app/services/parser/regex.dart';

class Todo {
  Todo({
    this.issueNumber,
    required this.title,
    required this.body,
    required this.files,
  })  : assert(issueNumber == null || issueNumber > 0),
        assert(title.isNotEmpty);
  int?
      issueNumber; //will be null when nearly created, when updated to db will be !=0
  String title;
  String body;
  List<TodoFile> files;
}

//todo add more filetypes once phone can select files
//purpose: has filetype to differentiate files on phone and github
class TodoFile {
  TodoFile({required this.content});

  File content;
  FileType? _type;

  //def: parse filetype from filename
  //assert: input is not empty
  //expects: after the last '.' follows the filetype
  //return: filetype
  String _getFileTypeFromPath(String filename) {
    assert(filename.isNotEmpty);
    //get everything that is not a '.' from the end of the string
    //example: test_image.jpg -> jpg
    return getFirstRegexMatch(filename, r'([^\.]+)$');
  }

  //def: parses fileType
  //assert: -
  //expects: file has filename which can be parsed by method getFileTypeFromPath()
  //return: fileType
  FileType getFileType() {
    if (_type != null) {
      return _type!;
    } else {
      String fileType = _getFileTypeFromPath(content.path);
      fileType = fileType.toLowerCase();
      switch (fileType) {
        case 'png':
        case 'jpg':
        case 'jpeg':
          _type = FileType.picture;
          return _type!;
        case 'mp4':
          _type = FileType.video;
          return _type!;
        default:
          _type = FileType.other;
          return _type!;
      }
    }
  }
}

enum FileType {
  picture,
  video,
  other,
}
