/// Locale-independent matching; display text always keeps the user's spelling.
String normalizeText(String value) {
  const replacements = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
    'Ç': 'c',
    'ç': 'c',
    'â': 'a',
    'Â': 'a',
    'î': 'i',
    'Î': 'i',
    'û': 'u',
    'Û': 'u',
  };
  var result = value;
  replacements.forEach((from, to) {
    result = result.replaceAll(from, to);
  });
  return result
      .toLowerCase()
      .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

String skillKey(String value) {
  const aliases = {
    'guitar': 'gitar',
    'piano': 'piyano',
    'music': 'muzik',
    'software': 'yazilim',
    'photography': 'fotografcilik',
    'psychology': 'psikoloji',
    'english': 'ingilizce',
    'spanish': 'ispanyolca',
  };
  final key = normalizeText(value);
  return aliases[key] ?? key;
}
