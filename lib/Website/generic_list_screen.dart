import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mukammal_pakistan_admin/Website/Field%20config.dart';

import '../../config/app_theme.dart';

import '../../widgets/admin_app_bar.dart';

/// bilingualText/bilingualLongText fields are stored as a map, e.g.
/// `{ en: "...", ur: "..." }`. This pulls a plain string out of that map
/// (falling back to Urdu if English is empty) for list previews — or
/// just returns the value as-is if it isn't bilingual.
String _displayText(dynamic raw) {
  if (raw == null) return '';
  if (raw is Map) {
    final en = raw['en'];
    if (en != null && en.toString().trim().isNotEmpty) return en.toString();
    final ur = raw['ur'];
    return ur?.toString() ?? '';
  }
  return raw.toString();
}

/// One generic, reusable CRUD screen driven entirely by a list of
/// [FieldConfig]. Used for leadership, manifesto_points, news, events,
/// gallery, videos and contact_messages so each collection doesn't need
/// its own hand-written screen.
class GenericListScreen extends StatefulWidget {
  final String collectionName;
  final String title;
  final List<FieldConfig> fields;
  final String displayField; // shown as the card's main text
  final String? subtitleField; // shown as the card's secondary text
  final String? orderByField;
  final bool orderDescending;
  final bool allowCreate;
  final bool allowDelete;

  const GenericListScreen({
    super.key,
    required this.collectionName,
    required this.title,
    required this.fields,
    required this.displayField,
    this.subtitleField,
    this.orderByField,
    this.orderDescending = false,
    this.allowCreate = true,
    this.allowDelete = true,
  });

  @override
  State<GenericListScreen> createState() => _GenericListScreenState();
}

class _GenericListScreenState extends State<GenericListScreen> {
  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(widget.collectionName);

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = _collection;
    if (widget.orderByField != null) {
      query = query.orderBy(widget.orderByField!,
          descending: widget.orderDescending);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AdminAppBar(title: widget.title),
      floatingActionButton: widget.allowCreate
          ? FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: () => _openForm(context, null),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No ${widget.title.toLowerCase()} yet.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final imageField = widget.fields
                  .firstWhere((f) => f.type == FieldType.image,
                  orElse: () => const FieldConfig(
                      key: '', label: '', type: FieldType.text))
                  .key;
              final imageUrl =
              imageField.isNotEmpty ? data[imageField] as String? : null;

              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          color: AppTheme.textSecondary),
                    ),
                  )
                      : CircleAvatar(
                    backgroundColor:
                    AppTheme.primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.article_outlined,
                        color: AppTheme.primaryGreen),
                  ),
                  title: Text(
                    _displayText(data[widget.displayField]),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                  subtitle: widget.subtitleField != null
                      ? Text(
                    _displayText(data[widget.subtitleField!]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  )
                      : null,
                  onTap: () => _openForm(context, doc),
                  trailing: widget.allowDelete
                      ? IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _confirmDelete(context, doc.id),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _collection.doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Deleted.')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  void _openForm(BuildContext context, DocumentSnapshot<Map<String, dynamic>>? doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EntryFormSheet(
        collection: _collection,
        title: widget.title,
        fields: widget.fields,
        existingDoc: doc,
      ),
    );
  }
}

class _EntryFormSheet extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> collection;
  final String title;
  final List<FieldConfig> fields;
  final DocumentSnapshot<Map<String, dynamic>>? existingDoc;

  const _EntryFormSheet({
    required this.collection,
    required this.title,
    required this.fields,
    required this.existingDoc,
  });

  @override
  State<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends State<_EntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};
  final Map<String, String?> _dropdownValues = {};
  final Map<String, DateTime?> _dateValues = {};
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final data = widget.existingDoc?.data() ?? {};
    for (final f in widget.fields) {
      switch (f.type) {
        case FieldType.boolean:
          _boolValues[f.key] = data[f.key] == true;
          break;
        case FieldType.dropdown:
          _dropdownValues[f.key] = data[f.key] as String? ??
              (f.options != null && f.options!.isNotEmpty
                  ? f.options!.first
                  : null);
          break;
        case FieldType.date:
          final ts = data[f.key];
          _dateValues[f.key] = ts is Timestamp ? ts.toDate() : null;
          break;
        case FieldType.bilingualText:
        case FieldType.bilingualLongText:
          final raw = data[f.key];
          final map = raw is Map ? raw : const {};
          _controllers['${f.key}::en'] =
              TextEditingController(text: (map['en'] ?? '').toString());
          _controllers['${f.key}::ur'] =
              TextEditingController(text: (map['ur'] ?? '').toString());
          break;
        default:
          final raw = data[f.key];
          _controllers[f.key] =
              TextEditingController(text: raw == null ? '' : raw.toString());
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage(FieldConfig f) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      setState(() => _uploadingImage = true);
      final Uint8List bytes = await picked.readAsBytes();
      final ref = FirebaseStorage.instance.ref().child(
          'website/${widget.collection.id}/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();
      setState(() {
        _controllers[f.key]!.text = url;
        _uploadingImage = false;
      });
    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
    }
  }

  Future<void> _pickDate(FieldConfig f) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateValues[f.key] ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _dateValues[f.key] = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final Map<String, dynamic> data = {};
      for (final f in widget.fields) {
        if (f.readOnly) continue; // never write back read-only fields
        switch (f.type) {
          case FieldType.boolean:
            data[f.key] = _boolValues[f.key] ?? false;
            break;
          case FieldType.dropdown:
            data[f.key] = _dropdownValues[f.key];
            break;
          case FieldType.date:
            final d = _dateValues[f.key];
            data[f.key] = d != null ? Timestamp.fromDate(d) : null;
            break;
          case FieldType.number:
            final text = _controllers[f.key]!.text.trim();
            data[f.key] = text.isEmpty ? null : num.tryParse(text);
            break;
          case FieldType.bilingualText:
          case FieldType.bilingualLongText:
            data[f.key] = {
              'en': _controllers['${f.key}::en']!.text.trim(),
              'ur': _controllers['${f.key}::ur']!.text.trim(),
            };
            break;
          default:
            data[f.key] = _controllers[f.key]!.text.trim();
        }
      }

      if (widget.existingDoc == null) {
        await widget.collection.add(data);
      } else {
        await widget.collection.doc(widget.existingDoc!.id).update(data);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved.')));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Widget _buildField(FieldConfig f) {
    switch (f.type) {
      case FieldType.text:
      case FieldType.longText:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            controller: _controllers[f.key],
            readOnly: f.readOnly,
            maxLines: f.type == FieldType.longText ? 4 : 1,
            decoration: InputDecoration(
              labelText: f.label,
              filled: f.readOnly,
              fillColor: f.readOnly ? AppTheme.dividerColor.withOpacity(0.3) : null,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => f.required && (v == null || v.trim().isEmpty)
                ? '${f.label} is required'
                : null,
          ),
        );
      case FieldType.bilingualText:
      case FieldType.bilingualLongText:
        final maxLines = f.type == FieldType.bilingualLongText ? 4 : 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controllers['${f.key}::en'],
                readOnly: f.readOnly,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: '${f.label} (English)',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => f.required && (v == null || v.trim().isEmpty)
                    ? '${f.label} (English) is required'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllers['${f.key}::ur'],
                readOnly: f.readOnly,
                maxLines: maxLines,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: '${f.label} (اردو)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      case FieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: TextFormField(
            controller: _controllers[f.key],
            readOnly: f.readOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: f.label,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => f.required && (v == null || v.trim().isEmpty)
                ? '${f.label} is required'
                : null,
          ),
        );
      case FieldType.boolean:
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(f.label),
            activeColor: AppTheme.primaryGreen,
            value: _boolValues[f.key] ?? false,
            onChanged: f.readOnly
                ? null
                : (v) => setState(() => _boolValues[f.key] = v),
          ),
        );
      case FieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            value: _dropdownValues[f.key],
            decoration: InputDecoration(
              labelText: f.label,
              border: const OutlineInputBorder(),
            ),
            items: (f.options ?? [])
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: f.readOnly
                ? null
                : (v) => setState(() => _dropdownValues[f.key] = v),
          ),
        );
      case FieldType.date:
        final d = _dateValues[f.key];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            onTap: f.readOnly ? null : () => _pickDate(f),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: f.label,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                d == null
                    ? 'Select date'
                    : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        );
      case FieldType.image:
        final url = _controllers[f.key]!.text;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.label,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: url.isEmpty
                        ? const Icon(Icons.image_outlined,
                        color: AppTheme.textSecondary)
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(url, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: f.readOnly || _uploadingImage
                          ? null
                          : () => _pickAndUploadImage(f),
                      icon: _uploadingImage
                          ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_outlined, size: 18),
                      label: Text(url.isEmpty ? 'Upload image' : 'Replace image'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDoc != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  isEditing ? 'Edit ${widget.title}' : 'Add ${widget.title}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 18),
                ...widget.fields.map(_buildField),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Save',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}