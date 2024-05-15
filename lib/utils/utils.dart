regextest(String value) {
  String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  RegExp regExp = new RegExp(pattern);
  return regExp.hasMatch(value);
}