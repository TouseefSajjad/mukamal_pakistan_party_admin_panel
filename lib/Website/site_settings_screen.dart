import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../widgets/admin_app_bar.dart';

/// site_settings/main is a single document, not a list — so it gets its
/// own simple form screen instead of going through GenericListScreen.
///
/// Bilingual fields (slogan, aboutIntro, visionMission, history,
/// footerText) are stored as `{ en: "...", ur: "..." }` maps in
/// Firestore, same convention as the bilingual fields in
/// GenericListScreen, so the website can show whichever language the
/// visitor picked.
class SiteSettingsScreen extends StatefulWidget {
  const SiteSettingsScreen({super.key});

  @override
  State<SiteSettingsScreen> createState() => _SiteSettingsScreenState();
}

class _SiteSettingsScreenState extends State<SiteSettingsScreen> {
  final _docRef =
  FirebaseFirestore.instance.collection('site_settings').doc('main');

  // Plain (single-language) fields.
  final _controllers = <String, TextEditingController>{
    'partyName': TextEditingController(),
    'partyNameUrdu': TextEditingController(),
    'electionSymbolName': TextEditingController(),
    'electionSymbolImageUrl': TextEditingController(),
    'logoUrl': TextEditingController(),
    'manifestoPdfUrl': TextEditingController(),
    'contact.phone': TextEditingController(),
    'contact.email': TextEditingController(),
    'contact.address': TextEditingController(),
    'contact.facebook': TextEditingController(),
    'contact.twitter': TextEditingController(),
    'contact.instagram': TextEditingController(),
    'contact.youtube': TextEditingController(),
  };

  // Bilingual fields — each gets an ::en and ::ur controller.
  static const _bilingualKeys = [
    'slogan',
    'aboutIntro',
    'visionMission',
    'history',
    'footerText',
  ];

  final _bilingualControllers = <String, TextEditingController>{};

  bool _loading = true;
  bool _saving = false;
  final _uploading = <String, bool>{};

  @override
  void initState() {
    super.initState();
    for (final key in _bilingualKeys) {
      _bilingualControllers['$key::en'] = TextEditingController();
      _bilingualControllers['$key::ur'] = TextEditingController();
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _docRef.get();
      final data = snap.data() ?? {};
      final contact = (data['contact'] as Map<String, dynamic>?) ?? {};

      _controllers['partyName']!.text = data['partyName'] ?? '';
      _controllers['partyNameUrdu']!.text = data['partyNameUrdu'] ?? '';
      _controllers['electionSymbolName']!.text = data['electionSymbolName'] ?? '';
      _controllers['electionSymbolImageUrl']!.text = data['electionSymbolImageUrl'] ?? '';
      _controllers['logoUrl']!.text = data['logoUrl'] ?? '';
      _controllers['manifestoPdfUrl']!.text = data['manifestoPdfUrl'] ?? '';
      _controllers['contact.phone']!.text = contact['phone'] ?? '';
      _controllers['contact.email']!.text = contact['email'] ?? '';
      _controllers['contact.address']!.text = contact['address'] ?? '';
      _controllers['contact.facebook']!.text = contact['facebook'] ?? '';
      _controllers['contact.twitter']!.text = contact['twitter'] ?? '';
      _controllers['contact.instagram']!.text = contact['instagram'] ?? '';
      _controllers['contact.youtube']!.text = contact['youtube'] ?? '';

      for (final key in _bilingualKeys) {
        final raw = data[key];
        final map = raw is Map ? raw : const {};
        _bilingualControllers['$key::en']!.text = (map['en'] ?? '').toString();
        _bilingualControllers['$key::ur']!.text = (map['ur'] ?? '').toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to load settings: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadImage(String controllerKey, String folder) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;
      setState(() => _uploading[controllerKey] = true);
      final Uint8List bytes = await picked.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('website/$folder/${DateTime.now().millisecondsSinceEpoch}_${picked.name}');
      await ref.putData(bytes);
      final url = await ref.getDownloadURL();
      setState(() {
        _controllers[controllerKey]!.text = url;
        _uploading[controllerKey] = false;
      });
    } catch (e) {
      setState(() => _uploading[controllerKey] = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'partyName': _controllers['partyName']!.text.trim(),
        'partyNameUrdu': _controllers['partyNameUrdu']!.text.trim(),
        'electionSymbolName': _controllers['electionSymbolName']!.text.trim(),
        'electionSymbolImageUrl': _controllers['electionSymbolImageUrl']!.text.trim(),
        'logoUrl': _controllers['logoUrl']!.text.trim(),
        'manifestoPdfUrl': _controllers['manifestoPdfUrl']!.text.trim(),
        'contact': {
          'phone': _controllers['contact.phone']!.text.trim(),
          'email': _controllers['contact.email']!.text.trim(),
          'address': _controllers['contact.address']!.text.trim(),
          'facebook': _controllers['contact.facebook']!.text.trim(),
          'twitter': _controllers['contact.twitter']!.text.trim(),
          'instagram': _controllers['contact.instagram']!.text.trim(),
          'youtube': _controllers['contact.youtube']!.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.uid ?? 'admin',
      };

      for (final key in _bilingualKeys) {
        data[key] = {
          'en': _bilingualControllers['$key::en']!.text.trim(),
          'ur': _bilingualControllers['$key::ur']!.text.trim(),
        };
      }

      await _docRef.set(data, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Site settings saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final c in _bilingualControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _text(String key, String label, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _controllers[key],
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    ),
  );

  /// Renders an English field + an Urdu (RTL) field stacked for one
  /// bilingual key, e.g. _bilingual('slogan', 'Slogan').
  Widget _bilingual(String key, String label, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _bilingualControllers['$key::en'],
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: '$label (English)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _bilingualControllers['$key::ur'],
          maxLines: maxLines,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: '$label (اردو)',
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    ),
  );

  Widget _image(String key, String label, String folder) {
    final url = _controllers[key]!.text;
    final isUploading = _uploading[key] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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
                    ? const Icon(Icons.image_outlined, color: AppTheme.textSecondary)
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading ? null : () => _pickAndUploadImage(key, folder),
                  icon: isUploading
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

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Text(text,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const AdminAppBar(title: 'Site Settings'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Party Identity'),
            _text('partyName', 'Party Name (English)'),
            _text('partyNameUrdu', 'Party Name (Urdu)'),
            _bilingual('slogan', 'Slogan'),
            _text('electionSymbolName', 'Election Symbol Name'),
            _image('electionSymbolImageUrl', 'Election Symbol Image', 'symbol'),
            _image('logoUrl', 'Party Logo', 'logo'),
            _sectionTitle('About the Party'),
            _bilingual('aboutIntro', 'About / Introduction', maxLines: 4),
            _bilingual('visionMission', 'Vision & Mission', maxLines: 4),
            _bilingual('history', 'History', maxLines: 4),
            _text('manifestoPdfUrl', 'Manifesto PDF URL'),
            _sectionTitle('Contact Info'),
            _text('contact.phone', 'Phone'),
            _text('contact.email', 'Email'),
            _text('contact.address', 'Address'),
            _text('contact.facebook', 'Facebook URL'),
            _text('contact.twitter', 'Twitter / X URL'),
            _text('contact.instagram', 'Instagram URL'),
            _text('contact.youtube', 'YouTube URL'),
            _sectionTitle('Footer'),
            _bilingual('footerText', 'Footer Text', maxLines: 2),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Save Settings', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}