///提取uri中的正则表达式部分
///[regexp] 含有正则表达式的uri
///[path] 请求中的uri
List<String> parseRegExp(String regExp,String path) {
  var regExpSplit = regExp.split('/');
  regExpSplit.removeWhere((element) => element == "");
  var pathSplit = path.split('/');
  pathSplit.removeWhere((element) => element == "");

  List<String> result = [];
  for(int i = 0 ; i < regExpSplit.length && i < pathSplit.length ; i++) {
    if(regExpSplit[i].contains('#')) {
      result.add(RegExp(regExpSplit[i].replaceAll('#', '')).firstMatch(pathSplit[i])!.group(0)!);
    }
  }
  return result;
}