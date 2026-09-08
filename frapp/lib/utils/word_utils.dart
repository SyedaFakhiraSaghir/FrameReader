final _tokenPattern = RegExp(r"[^\s]+");
final _letters = RegExp(r"[\p{L}\p{N}]", unicode: true);
final _cleanup = RegExp(r"[^\p{L}\p{N}'’-]", unicode: true);

List<String> tokenizeWords(String text) {
  return _tokenPattern
      .allMatches(text)
      .map((match) => match.group(0)!)
      .where((token) => token.contains(_letters))
      .toList();
}

String normalizeLookupWord(String raw) {
  return raw.replaceAll(_cleanup, '').trim();
}
