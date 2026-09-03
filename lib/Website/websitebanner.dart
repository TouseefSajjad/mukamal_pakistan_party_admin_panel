import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mukammal_pakistan_admin/config/app_theme.dart';


class WebsiteBannersScreen extends StatefulWidget {
  const WebsiteBannersScreen({super.key});

  @override
  State<WebsiteBannersScreen> createState() => _WebsiteBannersScreenState();
}

class _WebsiteBannersScreenState extends State<WebsiteBannersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================================
  // COLORS (kept local only for things AppTheme doesn't define)
  // ============================================================

  static const Color redColor = Color(0xFFFF3B30);

  // ============================================================
  // GET BANNERS
  // ============================================================

  Stream<List<WebsiteBannerModel>> _streamBanners() {
    return _firestore
        .collection('banners')
        .snapshots()
        .map((snapshot) {
      final List<WebsiteBannerModel> banners = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // ------------------------------------------------------
        // STRICT WEB TITLE FILTER
        // ------------------------------------------------------
        //
        // If webTitle does not exist -> DO NOT SHOW
        // If webTitle is null        -> DO NOT SHOW
        // If webTitle is not String  -> DO NOT SHOW
        // If webTitle is empty       -> DO NOT SHOW
        // If webTitle is spaces only -> DO NOT SHOW
        //
        // ------------------------------------------------------

        if (!data.containsKey('webTitle')) {
          continue;
        }

        final dynamic webTitleValue = data['webTitle'];

        if (webTitleValue == null) {
          continue;
        }

        if (webTitleValue is! String) {
          continue;
        }

        final String webTitle = webTitleValue.trim();

        if (webTitle.isEmpty) {
          continue;
        }

        // ------------------------------------------------------
        // ONLY VALID WEB TITLE BANNERS COME HERE
        // ------------------------------------------------------

        banners.add(
          WebsiteBannerModel.fromDoc(doc),
        );
      }

      return banners;
    });
  }

  // ============================================================
  // ADD BANNER
  // ============================================================

  Future<void> _addBanner() async {
    final TextEditingController titleController =
    TextEditingController();

    final TextEditingController webTitleController =
    TextEditingController();

    Uint8List? imageBytes;

    bool active = true;

    // Capture the *screen's* context now, before any dialog opens.
    // The AlertDialog below is built with its own (shadowed) `context`
    // parameter, which becomes invalid the moment that dialog is
    // popped. Anything that needs to act on the screen itself after
    // the dialog closes (showing the loading dialog, popping it,
    // showing a SnackBar) must use this captured screenContext instead
    // of the shadowed one.
    final BuildContext screenContext = context;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Website Banner',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ------------------------------------------------
                      // TITLE
                      // ------------------------------------------------

                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Banner Title',
                          hintText: 'Enter banner title',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // WEB TITLE
                      // ------------------------------------------------
                      //
                      // Required. A banner without a webTitle will never
                      // show up on the website or in this admin list
                      // (see _streamBanners filter above), so we enforce
                      // it here too before it ever gets saved.
                      // ------------------------------------------------

                      TextField(
                        controller: webTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Web Title *',
                          hintText:
                          'Enter title used on the website',
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // IMAGE PICKER
                      // ------------------------------------------------

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result =
                            await FilePicker.pickFiles(
                              type: FileType.image,
                              withData: true,
                            );

                            if (result != null &&
                                result.files.isNotEmpty) {
                              final file = result.files.first;

                              if (file.bytes != null) {
                                setDialogState(() {
                                  imageBytes = file.bytes;
                                });
                              }
                            }
                          },
                          icon: const Icon(
                            Icons.image_outlined,
                          ),
                          label: Text(
                            imageBytes == null
                                ? 'Select Banner Image *'
                                : 'Image Selected',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ------------------------------------------------
                      // IMAGE PREVIEW
                      // ------------------------------------------------

                      if (imageBytes != null)
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(10),
                          child: Image.memory(
                            imageBytes!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ------------------------------------------------
                      // ACTIVE SWITCH
                      // ------------------------------------------------

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Active',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Switch(
                            value: active,
                            activeColor: AppTheme.primaryGreen,
                            onChanged: (value) {
                              setDialogState(() {
                                active = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // ------------------------------------------------
                // CANCEL
                // ------------------------------------------------

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                // ------------------------------------------------
                // ADD
                // ------------------------------------------------

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final String title =
                    titleController.text.trim();

                    final String webTitle =
                    webTitleController.text.trim();

                    // --------------------------------------------
                    // VALIDATION
                    // --------------------------------------------

                    if (webTitle.isEmpty) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Web Title is required.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (imageBytes == null) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select a banner image.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    // --------------------------------------------
                    // SHOW LOADING
                    // --------------------------------------------

                    if (!mounted) return;

                    showDialog(
                      context: screenContext,
                      barrierDismissible: false,
                      builder: (_) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen,
                          ),
                        );
                      },
                    );

                    try {
                      // ------------------------------------------
                      // UPLOAD IMAGE
                      // ------------------------------------------

                      final String fileName =
                          'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';

                      final Reference storageRef =
                      _storage
                          .ref()
                          .child('banners')
                          .child(fileName);

                      final UploadTask uploadTask =
                      storageRef.putData(
                        imageBytes!,
                        SettableMetadata(
                          contentType: 'image/jpeg',
                        ),
                      );

                      await uploadTask;

                      final String imageUrl =
                      await storageRef.getDownloadURL();

                      // ------------------------------------------
                      // SAVE TO FIRESTORE
                      // ------------------------------------------

                      await _firestore
                          .collection('banners')
                          .add({
                        'title': title,
                        'webTitle': webTitle,
                        'imageUrl': imageUrl,
                        'active': active,
                        'createdAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;

                      Navigator.pop(screenContext);

                      ScaffoldMessenger.of(screenContext)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Banner added successfully.',
                          ),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      Navigator.pop(screenContext);

                      ScaffoldMessenger.of(screenContext)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to add banner: $e',
                          ),
                        ),
                      );
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

    titleController.dispose();
    webTitleController.dispose();
  }

  // ============================================================
  // DELETE BANNER
  // ============================================================

  Future<void> _deleteBanner(WebsiteBannerModel banner) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Banner',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this banner?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _firestore
          .collection('banners')
          .doc(banner.id)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Banner deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete banner: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // TOGGLE ACTIVE
  // ============================================================

  Future<void> _toggleBanner(
      WebsiteBannerModel banner,
      bool value,
      ) async {
    try {
      await _firestore
          .collection('banners')
          .doc(banner.id)
          .update({
        'active': value,
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update banner: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppTheme.textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Banners Management',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: StreamBuilder<List<WebsiteBannerModel>>(
        stream: _streamBanners(),
        builder: (context, snapshot) {
          // ----------------------------------------------------
          // ERROR
          // ----------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading banners:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          // ----------------------------------------------------
          // LOADING
          // ----------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
              ),
            );
          }

          // banners here is already guaranteed (by _streamBanners)
          // to only contain docs with a non-empty, valid webTitle.
          final banners = snapshot.data ?? [];

          // ----------------------------------------------------
          // EMPTY
          // ----------------------------------------------------

          if (banners.isEmpty) {
            return const Center(
              child: Text(
                'No website banners found.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          // ----------------------------------------------------
          // BANNERS GRID
          // ----------------------------------------------------

          return Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.builder(
              gridDelegate:
              const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisExtent: 400,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];

                return _WebsiteBannerCard(
                  banner: banner,
                  onDelete: () {
                    _deleteBanner(banner);
                  },
                  onToggle: (value) {
                    _toggleBanner(
                      banner,
                      value,
                    );
                  },
                );
              },
            ),
          );
        },
      ),

      // ========================================================
      // ADD BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        onPressed: _addBanner,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Banner',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// BANNER MODEL
// ==================================================================

class WebsiteBannerModel {
  final String id;
  final String title;
  final String webTitle;
  final String imageUrl;
  final bool active;

  WebsiteBannerModel({
    required this.id,
    required this.title,
    required this.webTitle,
    required this.imageUrl,
    required this.active,
  });

  factory WebsiteBannerModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    return WebsiteBannerModel(
      id: doc.id,

      title: data?['title'] is String
          ? data!['title']
          : '',

      webTitle: data?['webTitle'] is String
          ? data!['webTitle']
          : '',

      imageUrl: data?['imageUrl'] is String
          ? data!['imageUrl']
          : '',

      active: data?['active'] is bool
          ? data!['active']
          : true,
    );
  }
}

// ==================================================================
// BANNER CARD
// ==================================================================

class _WebsiteBannerCard extends StatelessWidget {
  final WebsiteBannerModel banner;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _WebsiteBannerCard({
    required this.banner,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: banner.active
              ? const Color(0xFFB7DDC5)
              : const Color(0xFFE0E4E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ======================================================
          // IMAGE
          // ======================================================
          //
          // banner.webTitle is guaranteed non-empty here (filtered
          // upstream), so every card reaching this widget should
          // show its real image whenever imageUrl is present.
          // ======================================================

          SizedBox(
            height: 225,
            width: double.infinity,
            child: banner.imageUrl.trim().isEmpty
                ? Container(
              color: const Color(0xFFF1F2F4),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 45,
                  color: Colors.grey,
                ),
              ),
            )
                : Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 225,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF1F2F4),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 45,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              loadingBuilder:
                  (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryGreen,
                    value: loadingProgress
                        .expectedTotalBytes !=
                        null
                        ? loadingProgress
                        .cumulativeBytesLoaded /
                        loadingProgress
                            .expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                14,
                18,
                14,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // WEB TITLE
                  // ------------------------------------------------

                  Text(
                    banner.webTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF182230),
                    ),
                  ),

                  // ------------------------------------------------
                  // NORMAL TITLE
                  // ------------------------------------------------

                  if (banner.title.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // ------------------------------------------------
                  // ACTIVE + SWITCH
                  // ------------------------------------------------

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: banner.active
                                ? const Color(0xFFE8F3EC)
                                : const Color(0xFFF1F2F4),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: banner.active
                                      ? AppTheme.primaryGreen
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                banner.active
                                    ? 'Active'
                                    : 'Inactive',
                                style: TextStyle(
                                  color: banner.active
                                      ? AppTheme.primaryGreen
                                      : Colors.grey,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      Switch(
                        value: banner.active,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: onToggle,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // DELETE BUTTON
                  // ------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFF4038,
                        ),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                      ),
                      label: const Text(
                        'Delete Banner',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}