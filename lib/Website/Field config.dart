enum FieldType { text, longText, number, boolean, image, date, dropdown }

/// Describes one field of a Firestore document so GenericListScreen can
/// render a list item, a form field, and save it back — without a new
/// screen having to be written for every collection.
class FieldConfig {
  final String key; // Firestore field name
  final String label; // shown to the admin
  final FieldType type;
  final List<String>? options; // required for FieldType.dropdown
  final bool readOnly; // shown but not editable (e.g. contact form fields)
  final bool required;

  const FieldConfig({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.readOnly = false,
    this.required = false,
  });
}