// Deliberately violates no_hardcoded_font_size. The lint ratchet analyzes this
// file and fails if systematic_lints reports nothing for it, which proves the
// plugin is loaded and the rule is listed under diagnostics. Excluded from the
// normal analyze run in analysis_options.yaml.
class TextStyle {
  const TextStyle({double? fontSize});
}

final probe = TextStyle(fontSize: 13);
