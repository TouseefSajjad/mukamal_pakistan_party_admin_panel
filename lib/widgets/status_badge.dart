import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final cfg = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: cfg.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: cfg.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            cfg.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: cfg.text,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _Cfg _resolve(String s) {
    switch (s) {
      case 'approved':
        return _Cfg(
          label: 'Approved',
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFF6EE7B7),
          dot: const Color(0xFF10B981),
          text: const Color(0xFF065F46),
        );
      case 'rejected':
        return _Cfg(
          label: 'Rejected',
          bg: const Color(0xFFFEF2F2),
          border: const Color(0xFFFCA5A5),
          dot: const Color(0xFFEF4444),
          text: const Color(0xFF991B1B),
        );
      default:
        return _Cfg(
          label: 'Pending',
          bg: const Color(0xFFFFFBEB),
          border: const Color(0xFFFCD34D),
          dot: const Color(0xFFF59E0B),
          text: const Color(0xFF92400E),
        );
    }
  }
}

class _Cfg {
  final String label;
  final Color bg, border, dot, text;
  const _Cfg({
    required this.label,
    required this.bg,
    required this.border,
    required this.dot,
    required this.text,
  });
}