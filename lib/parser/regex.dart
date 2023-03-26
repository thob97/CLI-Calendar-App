String getFirstRegexMatch(String string, String regex) {
  final RegExp r = RegExp(regex);
  final match = r.firstMatch(string);
  return string.substring(match!.start, match.end);
}

//def: finds all regex matches in string
//expects: regex, string
//returns: matches - empty list on no matches
List<String> getAllRegexMatches(String regex, String text) {
  final RegExp r = RegExp(regex);
  final matches = r.allMatches(text);
  return matches.map((match) => match.group(0).toString()).toList();
}

//def: splits text by first regex occurrence
//expects: regex, string
//returns: split - empty list on no match
List<String> splitFirstRegexMatch(String regex, String text) {
  final r = RegExp(regex);
  final match = r.firstMatch(text);
  if (match == null) {
    return [];
  } else {
    return [
      text.substring(0, match.start),
      text.substring(match.end, text.length)
    ];
  }
}
