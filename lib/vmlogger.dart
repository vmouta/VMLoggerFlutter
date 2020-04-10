library vmlogger;

import 'dart:io';
import 'dart:developer' as logger;

import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:stack_trace/stack_trace.dart';

//const String defaultLogFormat = "%.30d %-7p %-20.-20c - %m";
const String LogFormatFull = "%d (%.7t): [%-7p] - %c (%F#%M:%L) - %m";
const String LogFormatWithMethodName = "[%-7p]- %-20.-20c - #%M: %m";
const String LogFormatDefault = "[%-7p]- %-20.-20c - %m";
const String LogFormat = LogFormatWithMethodName;

const String lenghtPattern = "([-]?\\d{1,2}[.][-]?\\d{1,2}|[.][-]?\\d{1,2}|[-]?\\d{1,2})";

const String identifier = "%" + lenghtPattern + "?" + "(logger|lo|c)";
const String level = "%" + lenghtPattern + "?" + "(level|le|p)";
const String date = "%" + lenghtPattern + "?" + "(date|d)";
const String message = "%" + lenghtPattern + "?" + "(message|msg|m)";

const String thread = "%" + lenghtPattern + "?" + "(thread|t)";

const String caller = "%" + lenghtPattern + "?" + "(Caller)";
const String function = "%" + lenghtPattern + "?" + "(M|Method)";
const String file = "%" + lenghtPattern + "?" + "(F|file)";
const String line = "%" + lenghtPattern + "?" + "(L|line)";

const String lineSeparator = "%n";

const String grouping = "%" + lenghtPattern + "[(].{1,}[)]";

const PATTERNS = [identifier, level, date, message, thread, caller,function,file,line, lineSeparator];

void formatEntry(LogRecord rec) {
  var resultString = LogFormat;
  RegExp exp = new RegExp(grouping);
  Iterable<Match> matches = exp.allMatches(resultString);
  for (var match in matches) {
    var content = resultString.substring(match.start, match.end);
    var start = content.indexOf('(');
    var subPattern = content.substring(start);
    subPattern = patternReplacement(rec, subPattern);
    subPattern = formatSpecifiers(content, subPattern);
    resultString = resultString.replaceFirst(content.substring(start), subPattern);
  }

  logger.log(patternReplacement(rec, resultString));
  //print(patternReplacement(rec, resultString));
  //print('[${rec.loggerName}] ${rec.level.name}: ${DateFormat('kk:mm.mmm').format(rec.time)}: ${rec.message}');
}

String formatSpecifiers(String expression, String replacement) {
  var newReplacement = replacement;
  RegExp exp = new RegExp(lenghtPattern);
  Iterable<Match> matches = exp.allMatches(expression);
  for (var match in matches) {
    int max;
    int min;
    var specifier = expression.substring(match.start, match.end);
    List<String> values = specifier.split('.');
    if (values.length == 1) {
      min = int.parse(values[0]);
    } else if (values.length == 2) {
      min = (values[0].isEmpty ? -1 : int.parse(values[0]));
      max = (values[1].isEmpty ? -1 : int.parse(values[1]));
    }

    if (values[0].isEmpty == false && newReplacement.length < min.abs()) {
      newReplacement = (min < 0 ? newReplacement.padRight(min.abs(), ' ') : newReplacement.padLeft(min.abs(), ' '));
    }

    if (values.length > 1 && newReplacement.length > max.abs()) {
      newReplacement = (max < 0 ? newReplacement.substring(0, max.abs()) : newReplacement.substring(newReplacement.length-max));
    }
  }
  return newReplacement;
}

String patternReplacement(LogRecord rec, String patterns) {
  int offset = 0;
  Map<int, dynamic> orderMatches = Map();
  String details = patterns;

  for (var pat in PATTERNS) {
    RegExp exp = new RegExp(pat);
    Iterable<Match> matches = exp.allMatches(details);
    for (var match in matches) {
      orderMatches[match.start] = [pat, match];
    }
  }

  // This should be part of LogReport
  final List<Frame> frames = Trace.current().frames;
  final Frame f = frames.skip(2).firstWhere((Frame f) => f.package == 'vila', orElse: () => frames.first);

  var sortedKeys = orderMatches.keys.toList()..sort();
  for (var key in sortedKeys) {
    var match = orderMatches[key][1];
    var pat = orderMatches[key][0];
    var start = match.start + offset;
    String replacement = "";
    switch(pat) {
      case identifier:
        replacement = rec.loggerName;
        break;
      case level:
        replacement = rec.level.name;
        break;
      case date:
        //replacement = DateFormat('HH:mm:ss').format(rec.time);
        replacement = rec.time.toIso8601String();
        break;
      case message:
        replacement = rec.message;
        break;
      case thread:
        replacement = pid.toString();
        break;
      case caller:
        // Not supported
        break;
      case function:
        replacement = f.member.substring(f.member.indexOf('.')+1);
        break;
      case file:
        replacement = f.library.split('/').last;
        break;
      case line:
        replacement = f.line.toString();
        break;
      case lineSeparator:
        replacement = "\n";
        break;
      default:
        break;
    }
    var expression = details.substring(start, start+ (match.end - match.start));
    replacement = formatSpecifiers(expression, replacement);

    details = details.replaceFirst(expression, replacement);
    offset += (replacement.length - expression.length);
  }
  return details;
}
