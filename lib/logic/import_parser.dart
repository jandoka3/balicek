/// Rozparsuje text importu na seznam názvů položek.
///
/// - Vstup se dělí podle nových řádků i podle čárek (lze kombinovat).
/// - Každá položka se ořízne o mezery, prázdné se zahodí.
/// - Duplicity (case-insensitive) se zahodí, zachová se první výskyt
///   v původní podobě.
List<String> parseImport(String input) {
  final result = <String>[];
  final seen = <String>{};

  for (final part in input.split(RegExp(r'[\n,]'))) {
    final name = part.trim();
    if (name.isEmpty) continue;

    final key = name.toLowerCase();
    if (seen.contains(key)) continue;

    seen.add(key);
    result.add(name);
  }

  return result;
}
