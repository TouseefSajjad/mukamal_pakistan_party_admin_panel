enum FieldType {
  text,
  longText,
  number,
  boolean,
  image,
  date,
  dropdown,
  bilingualText, // stores as a map: { en: "...", ur: "..." }
  bilingualLongText, // same as above, multi-line
}

/// Describes one field of a Firestore document so GenericListScreen can
/// render a list item, a form field, and save it back — without a new
/// screen having to be written for every collection.
///
/// bilingualText / bilingualLongText fields are stored in Firestore as a
/// map, e.g. `title: { en: "Full agenda", ur: "..." }`, instead of a plain
/// string, so the website can show whichever language the visitor picked.
class FieldConfig {
  final String key; // Firestore field name
  final String label; // shown to the admin (used as the English field's label)
  final FieldType type;
  final List<String>? options; // required for FieldType.dropdown
  final bool readOnly; // shown but not editable (e.g. contact form fields)
  final bool required; // for bilingual fields, only the English side is required

  const FieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.readOnly = false,
    this.required = false,
  });
}