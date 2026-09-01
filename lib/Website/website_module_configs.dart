import 'package:mukammal_pakistan_admin/Website/Field%20config.dart';


/// One FieldConfig list per website collection. Add/remove a field here
/// and the list + add/edit form update automatically — no screen code
/// to touch.
///
/// bilingualText / bilingualLongText fields store as
/// `{ en: "...", ur: "..." }` in Firestore, so the website can show
/// whichever language the visitor selected.

const leadershipFields = [
  FieldConfig(key: 'name', label: 'Name', type: FieldType.text, required: true),
  FieldConfig(key: 'position', label: 'Position', type: FieldType.bilingualText, required: true),
  FieldConfig(key: 'isChairman', label: 'Is Chairman', type: FieldType.boolean),
  FieldConfig(key: 'photoUrl', label: 'Photo', type: FieldType.image),
  FieldConfig(key: 'education', label: 'Education', type: FieldType.text),
  FieldConfig(key: 'bio', label: 'Biography', type: FieldType.bilingualLongText),
  FieldConfig(key: 'order', label: 'Display Order', type: FieldType.number),
  FieldConfig(key: 'isActive', label: 'Active', type: FieldType.boolean),
];

const manifestoFields = [
  FieldConfig(
    key: 'type',
    label: 'Type',
    type: FieldType.dropdown,
    options: ['agenda', 'core_objective'],
    required: true,
  ),
  FieldConfig(key: 'title', label: 'Title', type: FieldType.bilingualText, required: true),
  FieldConfig(key: 'description', label: 'Description', type: FieldType.bilingualLongText),
  FieldConfig(key: 'order', label: 'Display Order', type: FieldType.number),
];

const newsFields = [
  FieldConfig(key: 'title', label: 'Title', type: FieldType.bilingualText, required: true),
  FieldConfig(key: 'slug', label: 'Slug (url-friendly)', type: FieldType.text, required: true),
  FieldConfig(key: 'content', label: 'Content', type: FieldType.bilingualLongText, required: true),
  FieldConfig(key: 'coverImageUrl', label: 'Cover Image', type: FieldType.image),
  FieldConfig(
    key: 'status',
    label: 'Status',
    type: FieldType.dropdown,
    options: ['draft', 'published'],
    required: true,
  ),
  FieldConfig(key: 'publishedAt', label: 'Published Date', type: FieldType.date),
];

const eventsFields = [
  FieldConfig(key: 'title', label: 'Title', type: FieldType.bilingualText, required: true),
  FieldConfig(key: 'description', label: 'Description', type: FieldType.bilingualLongText),
  FieldConfig(key: 'eventDate', label: 'Event Date', type: FieldType.date, required: true),
  FieldConfig(key: 'location', label: 'Location', type: FieldType.text),
  FieldConfig(key: 'coverImageUrl', label: 'Cover Image', type: FieldType.image),
  FieldConfig(
    key: 'status',
    label: 'Status',
    type: FieldType.dropdown,
    options: ['upcoming', 'past'],
    required: true,
  ),
];

const galleryFields = [
  FieldConfig(key: 'imageUrl', label: 'Image', type: FieldType.image, required: true),
  FieldConfig(key: 'caption', label: 'Caption', type: FieldType.bilingualText),
  FieldConfig(key: 'category', label: 'Category', type: FieldType.text),
];

const videosFields = [
  FieldConfig(key: 'title', label: 'Title', type: FieldType.bilingualText, required: true),
  FieldConfig(key: 'youtubeUrl', label: 'YouTube URL', type: FieldType.text, required: true),
  FieldConfig(key: 'thumbnailUrl', label: 'Thumbnail', type: FieldType.image),
  FieldConfig(key: 'category', label: 'Category', type: FieldType.text),
];

/// Contact messages are submitted by visitors — admin can only read
/// them and update the status, never edit the message itself. Not
/// bilingual: this is the visitor's own words, in whatever language
/// they typed it.
const contactMessageFields = [
  FieldConfig(key: 'name', label: 'Name', type: FieldType.text, readOnly: true),
  FieldConfig(key: 'email', label: 'Email', type: FieldType.text, readOnly: true),
  FieldConfig(key: 'phone', label: 'Phone', type: FieldType.text, readOnly: true),
  FieldConfig(key: 'message', label: 'Message', type: FieldType.longText, readOnly: true),
  FieldConfig(
    key: 'status',
    label: 'Status',
    type: FieldType.dropdown,
    options: ['new', 'read', 'replied'],
  ),
];