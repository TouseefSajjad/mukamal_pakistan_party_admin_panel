import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────

const _kGreen = Color(0xFF1B6B3A);
const _kBg = Color(0xFFF7F9F7);
const _kSurface = Colors.white;
const _kTextPrimary = Color(0xFF111827);
const _kTextSecondary = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kShadow = Color(0x0D000000);
const _kHover = Color(0xFFF0FAF4);

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final bool active;

  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.active,
  });

  factory BannerModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return BannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      active: data['active'] ?? true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _uploading = false;

  // ───────────────────────────────────────────────────────────────────────────
  // STREAM
  // ───────────────────────────────────────────────────────────────────────────

  Stream<List<BannerModel>> _streamBanners() {
    return _firestore
        .collection('banners')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BannerModel.fromDoc(doc))
          .toList();
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ADD BANNER
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _addBanner() async {
    final titleController = TextEditingController();

    Uint8List? imageBytes;
    String? imageName;
    bool active = true;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Banner',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Banner title',
                          filled: true,
                          fillColor: const Color(0xFFF9FAFB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                            const BorderSide(color: _kBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                            const BorderSide(color: _kBorder),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Pick image
                      GestureDetector(
                        onTap: () async {
                          final result = await FilePicker.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );(
                            type: FileType.image,
                            withData: true,
                          );

                          if (result != null &&
                              result.files.single.bytes != null) {
                            setModalState(() {
                              imageBytes =
                              result.files.single.bytes!;
                              imageName =
                                  result.files.single.name;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(14),
                            border: Border.all(color: _kBorder),
                            color: const Color(0xFFF9FAFB),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                size: 38,
                                color: _kGreen,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                imageName ?? 'Choose Banner Image',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (imageBytes != null) ...[
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(14),
                          child: Image.memory(
                            imageBytes!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      SwitchListTile(
                        value: active,
                        activeColor: _kGreen,
                        title: const Text('Active Banner'),
                        onChanged: (v) {
                          setModalState(() {
                            active = v;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final title =
                    titleController.text.trim();

                    if (title.isEmpty || imageBytes == null) {
                      return;
                    }

                    try {
                      setState(() {
                        _uploading = true;
                      });

                      final fileName =
                      DateTime.now().millisecondsSinceEpoch
                          .toString();

                      final ref = _storage
                          .ref()
                          .child('banners')
                          .child('$fileName.jpg');

                      await ref.putData(imageBytes!);

                      final imageUrl =
                      await ref.getDownloadURL();

                      await _firestore
                          .collection('banners')
                          .add({
                        'title': title,
                        'imageUrl': imageUrl,
                        'active': active,
                      });

                      if (mounted) {
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content:
                            Text('Banner added successfully'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );
                    } finally {
                      setState(() {
                        _uploading = false;
                      });
                    }
                  },
                  child: const Text('Add Banner'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELETE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _deleteBanner(BannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Delete Banner'),
          content: Text(
            'Delete "${banner.title}" banner?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ??
        false;

    if (!confirmed) return;

    try {
      await _firestore
          .collection('banners')
          .doc(banner.id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Banner deleted'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOGGLE ACTIVE
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _toggleBanner(
      BannerModel banner,
      bool value,
      ) async {
    await _firestore
        .collection('banners')
        .doc(banner.id)
        .update({
      'active': value,
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,

      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: const Text(
          'Banners Management',
          style: TextStyle(
            color: _kTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        onPressed: _uploading ? null : _addBanner,
        icon: _uploading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.add_rounded),
        label: Text(
          _uploading ? 'Uploading...' : 'Add Banner',
        ),
      ),

      body: StreamBuilder<List<BannerModel>>(
        stream: _streamBanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _kGreen,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final banners = snapshot.data ?? [];

          if (banners.isEmpty) {
            return const Center(
              child: Text(
                'No banners found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kTextSecondary,
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final gridCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 800
                  ? 3
                  : constraints.maxWidth > 500
                  ? 2
                  : 1;

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: banners.length,
                gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridCount,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (_, index) {
                  final banner = banners[index];

                  return _BannerCard(
                    banner: banner,
                    onDelete: () =>
                        _deleteBanner(banner),
                    onToggle: (v) =>
                        _toggleBanner(banner, v),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANNER CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BannerCard extends StatefulWidget {
  final BannerModel banner;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _BannerCard({
    required this.banner,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        decoration: BoxDecoration(
          color: _hovered ? _kHover : _kSurface,
          borderRadius: BorderRadius.circular(22),

          border: Border.all(
            color: _hovered
                ? _kGreen.withOpacity(0.25)
                : _kBorder,
          ),

          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? _kGreen.withOpacity(0.08)
                  : _kShadow,
              blurRadius: _hovered ? 14 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                child: Image.network(
                  banner.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 42,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: banner.active
                                ? _kGreen.withOpacity(0.10)
                                : const Color(0xFFFEF2F2),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: banner.active
                                      ? _kGreen
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                banner.active
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  fontWeight:
                                  FontWeight.w600,
                                  color: banner.active
                                      ? _kGreen
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Switch(
                        value: banner.active,
                        activeColor: _kGreen,
                        onChanged: widget.onToggle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: widget.onDelete,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                      ),
                      label: const Text(
                        'Delete Banner',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}