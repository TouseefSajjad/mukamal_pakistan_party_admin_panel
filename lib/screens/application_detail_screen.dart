import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:mukammal_pakistan_admin/models/services/application_service.dart';
import '../models/membership_application.dart';
import '../widgets/status_badge.dart';

// ── Theme constants (same palette) ────────────────────────────────────────────
const _kGreen = Color(0xFF1B6B3A);
const _kBg = Color(0xFFF7F9F7);
const _kSurface = Colors.white;
const _kTextPrimary = Color(0xFF111827);
const _kTextSecondary = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kShadow = Color(0x0D000000);

// ── Global registry to avoid duplicate view factory registrations ─────────────
final _registeredViews = <String>{};

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _isUpdating = false;

  // ── Review action ─────────────────────────────────────────────────────────
  Future<void> _review(MembershipApplication app, String status) async {
    setState(() => _isUpdating = true);
    try {
      await ApplicationService.instance.reviewApplication(
        applicationId: app.id,
        userId: app.userId,
        status: status,
        adminId: 'admin',
      );
      if (mounted) {
        _showSnack(
          '${_cap(status)} successfully',
          status == 'approved'
              ? const Color(0xFF10B981)
              : status == 'rejected'
              ? const Color(0xFFEF4444)
              : const Color(0xFFF59E0B),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Error: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
          const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(20),
    ));
  }

  void _confirmAction(
      BuildContext context,
      MembershipApplication app,
      String action,
      String status,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirm ${_cap(action)}',
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: _kTextPrimary)),
        content: Text(
          'Are you sure you want to $action this application?\n'
              'This will update the applicant\'s membership status.',
          style: const TextStyle(color: _kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _review(app, status);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'approved'
                  ? const Color(0xFF10B981)
                  : status == 'rejected'
                  ? const Color(0xFFEF4444)
                  : const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_cap(action)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(context),
      body: StreamBuilder<MembershipApplication>(
        stream:
        ApplicationService.instance.streamApplication(widget.applicationId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _kGreen, strokeWidth: 2.5));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snap.hasData) {
            return const Center(child: Text('Application not found.'));
          }

          final app = snap.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 48 : 20,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeaderCard(app: app),
                        const SizedBox(height: 20),
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _PersonalCard(app: app)),
                              const SizedBox(width: 20),
                              Expanded(child: _ContactCard(app: app)),
                            ],
                          )
                        else ...[
                          _PersonalCard(app: app),
                          const SizedBox(height: 20),
                          _ContactCard(app: app),
                        ],
                        const SizedBox(height: 20),
                        _EducationCard(app: app),
                        const SizedBox(height: 20),
                        _DocumentsCard(app: app),
                        const SizedBox(height: 20),
                        _StatusCard(app: app),
                        const SizedBox(height: 20),
                        _ActionsCard(
                          app: app,
                          isUpdating: _isUpdating,
                          onAction: (action, status) =>
                              _confirmAction(context, app, action, status),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          border: Border(bottom: BorderSide(color: _kBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _BackButton(onTap: () => Navigator.of(context).pop()),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Application Detail',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                      letterSpacing: -0.3,
                    ),
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

// ── Back button ───────────────────────────────────────────────────────────────

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _hovered
                ? _kGreen.withOpacity(0.12)
                : _kGreen.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
          const Icon(Icons.arrow_back_rounded, color: _kGreen, size: 18),
        ),
      ),
    );
  }
}

// ── Header Card ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final MembershipApplication app;
  const _HeaderCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final name = app.personalInfo.fullName.trim().isEmpty
        ? 'Unknown'
        : app.personalInfo.fullName;

    return _SectionCard(
      child: Row(
        children: [
          _ProfileAvatar(
            profileUrl: app.documents.profileImage,
            name: name,
            size: 70,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary,
                        letterSpacing: -0.3)),
                const SizedBox(height: 4),
                if (app.contactInfo.email.isNotEmpty)
                  Text(app.contactInfo.email,
                      style:
                      const TextStyle(fontSize: 13, color: _kTextSecondary)),
                const SizedBox(height: 12),
                StatusBadge(status: app.status, fontSize: 13),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('App ID',
                  style: TextStyle(fontSize: 11, color: _kTextSecondary)),
              const SizedBox(height: 3),
              Text(
                app.id.length > 10
                    ? '…${app.id.substring(app.id.length - 8)}'
                    : app.id,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              Text(_fmtDate(app.submittedAt),
                  style:
                  const TextStyle(fontSize: 11, color: _kTextSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Personal Info Card ────────────────────────────────────────────────────────

class _PersonalCard extends StatelessWidget {
  final MembershipApplication app;
  const _PersonalCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final p = app.personalInfo;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.person_rounded, label: 'Personal Information'),
          const SizedBox(height: 16),
          _Field(label: 'Full Name', value: p.fullName),
          _Field(label: 'Father Name', value: p.fatherName),
          _Field(label: 'CNIC', value: p.cnic),
          _Field(label: 'Gender', value: p.gender),
          _Field(
            label: 'Date of Birth',
            value: p.dateOfBirth != null ? _fmtDate(p.dateOfBirth!) : '—',
          ),
        ],
      ),
    );
  }
}

// ── Contact Info Card ─────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final MembershipApplication app;
  const _ContactCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final c = app.contactInfo;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.location_on_rounded, label: 'Contact Information'),
          const SizedBox(height: 16),
          _Field(label: 'Email', value: c.email),
          _Field(label: 'Phone', value: c.phone),
          _Field(label: 'City', value: c.city),
          _Field(label: 'Address', value: c.address),
        ],
      ),
    );
  }
}

// ── Education Info Card ───────────────────────────────────────────────────────

class _EducationCard extends StatelessWidget {
  final MembershipApplication app;
  const _EducationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final e = app.educationInfo;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.school_rounded,
              label: 'Education & Professional'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 480;
              if (wide) {
                return Column(children: [
                  Row(children: [
                    Expanded(
                        child: _Field(
                            label: 'Education Level',
                            value: e.educationLevel)),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _Field(
                            label: 'Year of Completion',
                            value: e.yearOfCompletion)),
                  ]),
                  Row(children: [
                    Expanded(
                        child:
                        _Field(label: 'Institution', value: e.institution)),
                    const SizedBox(width: 24),
                    Expanded(
                        child:
                        _Field(label: 'Profession', value: e.profession)),
                  ]),
                  _Field(
                    label: 'Applied Role',
                    value: e.selectedRole.toUpperCase(),
                    highlight: true,
                  ),
                ]);
              }
              return Column(children: [
                _Field(label: 'Education Level', value: e.educationLevel),
                _Field(
                    label: 'Year of Completion', value: e.yearOfCompletion),
                _Field(label: 'Institution', value: e.institution),
                _Field(label: 'Profession', value: e.profession),
                _Field(
                  label: 'Applied Role',
                  value: e.selectedRole.toUpperCase(),
                  highlight: true,
                ),
              ]);
            },
          ),
        ],
      ),
    );
  }
}

// ── Documents Card ────────────────────────────────────────────────────────────

class _DocumentsCard extends StatelessWidget {
  final MembershipApplication app;
  const _DocumentsCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final docs = app.documents;
    final hasCnic = docs.cnicImages.isNotEmpty;
    final hasEdu = docs.educationCertificate.isNotEmpty;
    final hasProfile = docs.profileImage.isNotEmpty;
    final hasOther = docs.otherDocuments.isNotEmpty;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: Icons.folder_copy_rounded, label: 'Documents'),
          const SizedBox(height: 20),

          // ── Profile image ───────────────────────────────────────────────
          if (hasProfile) ...[
            const _DocSubtitle(label: 'Profile Photo'),
            const SizedBox(height: 10),
            _DocImage(url: docs.profileImage, maxHeight: 200),
            const SizedBox(height: 20),
          ],

          // ── CNIC images ─────────────────────────────────────────────────
          if (hasCnic) ...[
            const _DocSubtitle(label: 'CNIC Images'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, c) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: docs.cnicImages
                      .map((url) => _DocImage(
                    url: url,
                    maxHeight: 160,
                    maxWidth: (c.maxWidth / 2) - 8,
                  ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // ── Education certificate ───────────────────────────────────────
          if (hasEdu) ...[
            const _DocSubtitle(label: 'Education Certificate'),
            const SizedBox(height: 10),
            _DocImage(url: docs.educationCertificate, maxHeight: 220),
            const SizedBox(height: 20),
          ],

          // ── Other documents ─────────────────────────────────────────────
          if (hasOther) ...[
            const _DocSubtitle(label: 'Other Documents'),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, c) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: docs.otherDocuments
                      .asMap()
                      .entries
                      .map((entry) => _DocImage(
                    url: entry.value,
                    maxHeight: 180,
                    maxWidth: (c.maxWidth / 2) - 8,
                  ))
                      .toList(),
                );
              },
            ),
          ],

          // ── Nothing uploaded ────────────────────────────────────────────
          if (!hasProfile && !hasCnic && !hasEdu && !hasOther)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No documents uploaded',
                    style: TextStyle(color: _kTextSecondary, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocSubtitle extends StatelessWidget {
  final String label;
  const _DocSubtitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kTextSecondary,
            letterSpacing: 0.5));
  }
}

// ── Doc Image — Flutter Web fix using HtmlElementView ────────────────────────

class _DocImage extends StatefulWidget {
  final String url;
  final double maxHeight;
  final double? maxWidth;

  const _DocImage({
    required this.url,
    required this.maxHeight,
    this.maxWidth,
  });

  @override
  State<_DocImage> createState() => _DocImageState();
}

class _DocImageState extends State<_DocImage> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();

    _viewId = 'doc_img_${widget.url.hashCode.abs()}';

    _registerFactory();
  }

  void _registerFactory() {
    if (_registeredViews.contains(_viewId)) return;

    _registeredViews.add(_viewId);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
          (int id) {
        final img = html.ImageElement()
          ..src = widget.url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.cursor = 'pointer'
          ..style.display = 'block';

        return img;
      },
    );
  }

  void _openViewer() {
    final viewerId = 'viewer_${widget.url.hashCode.abs()}';

    if (!_registeredViews.contains(viewerId)) {
      _registeredViews.add(viewerId);

      ui_web.platformViewRegistry.registerViewFactory(
        viewerId,
            (int id) {
          final img = html.ImageElement()
            ..src = widget.url
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'contain'
            ..style.backgroundColor = 'black';

          return img;
        },
      );
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.94),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 5,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 1400,
                      maxHeight: 900,
                    ),
                    child: HtmlElementView(
                      viewType: viewerId,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    if (widget.url.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _openViewer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: widget.maxHeight,
          width: widget.maxWidth,
          constraints: BoxConstraints(
            maxHeight: widget.maxHeight,
            maxWidth: widget.maxWidth ?? double.infinity,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: HtmlElementView(
                  viewType: _viewId,
                ),
              ),

              // View overlay
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_full_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'View',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── Application Status Card ───────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final MembershipApplication app;
  const _StatusCard({required this.app});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.info_outline_rounded, label: 'Application Status'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'Current Status',
                  value: '',
                  customValue:
                  StatusBadge(status: app.status, fontSize: 13),
                ),
              ),
              Expanded(
                child: _Field(
                  label: 'Submitted Date',
                  value: _fmtDate(app.submittedAt),
                ),
              ),
            ],
          ),
          if (app.reviewedAt != null)
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'Reviewed Date',
                    value: _fmtDate(app.reviewedAt!),
                  ),
                ),
                Expanded(
                  child: _Field(
                    label: 'Reviewed By',
                    value: app.reviewedBy ?? '—',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Admin Actions Card ────────────────────────────────────────────────────────

class _ActionsCard extends StatelessWidget {
  final MembershipApplication app;
  final bool isUpdating;
  final void Function(String action, String status) onAction;

  const _ActionsCard({
    required this.app,
    required this.isUpdating,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.admin_panel_settings_rounded,
              label: 'Admin Actions'),
          const SizedBox(height: 20),
          if (isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                    color: _kGreen, strokeWidth: 2.5),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (app.status != 'approved')
                  _ActionBtn(
                    label: 'Approve',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () => onAction('approve', 'approved'),
                  ),
                if (app.status != 'rejected')
                  _ActionBtn(
                    label: 'Reject',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: () => onAction('reject', 'rejected'),
                  ),
                if (app.status != 'pending')
                  _ActionBtn(
                    label: 'Set Pending',
                    icon: Icons.hourglass_top_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () => onAction('mark as pending', 'pending'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
          const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color
                : widget.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.color.withOpacity(_hovered ? 0 : 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: _hovered ? Colors.white : widget.color,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Avatar — Flutter Web fix using HtmlElementView ───────────────────

class _ProfileAvatar extends StatefulWidget {
  final String profileUrl;
  final String name;
  final double size;

  const _ProfileAvatar({
    required this.profileUrl,
    required this.name,
    required this.size,
  });

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'avatar_img_${widget.profileUrl.hashCode.abs()}';
    if (widget.profileUrl.isNotEmpty) {
      _registerFactory();
    }
  }

  void _registerFactory() {
    if (_registeredViews.contains(_viewId)) return;
    _registeredViews.add(_viewId);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
          (int id) {
        final img = html.ImageElement()
          ..src = widget.profileUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.display = 'block';
        return img;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profileUrl.isEmpty) return _fallback();

    final radius = widget.size * 0.22;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: HtmlElementView(viewType: _viewId),
      ),
    );
  }

  Widget _fallback() {
    final words = widget.name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : words.isNotEmpty
        ? words[0][0].toUpperCase()
        : '?';
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(widget.size * 0.22),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
              fontSize: widget.size * 0.32,
              fontWeight: FontWeight.w800,
              color: _kGreen),
        ),
      ),
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: _kShadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

// ── Card title ────────────────────────────────────────────────────────────────

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CardTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kGreen.withOpacity(0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: _kGreen, size: 18),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary)),
      ],
    );
  }
}

// ── Field display ─────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Widget? customValue;

  const _Field({
    required this.label,
    required this.value,
    this.highlight = false,
    this.customValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _kTextSecondary,
                letterSpacing: 0.6),
          ),
          const SizedBox(height: 5),
          customValue ??
              (highlight
                  ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kGreen),
                ),
              )
                  : Text(
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary),
              )),
        ],
      ),
    );
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────

String _fmtDate(DateTime dt) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
}

String _cap(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);