import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Formats a dynamic declaration value into a readable string.
/// Handles String, num, Map, List, and null.
String formatDeclValue(dynamic value) {
  if (value == null) return 'NOT DETECTED';
  if (value is String) return value.isEmpty ? 'NOT DETECTED' : value;
  if (value is num) return value.toString();
  if (value is Map) {
    // e.g. {"value": "500g", "unit": "grams"} → "500g (grams)"
    final parts = value.values.where((v) => v != null && v.toString().isNotEmpty).map((v) => v.toString()).toList();
    return parts.isEmpty ? 'NOT DETECTED' : parts.join(' ');
  }
  if (value is List) {
    final parts = value.where((v) => v != null && v.toString().isNotEmpty).map((v) => v.toString()).toList();
    return parts.isEmpty ? 'NOT DETECTED' : parts.join(', ');
  }
  return value.toString();
}

class ComplianceFlipCard extends StatefulWidget {
  final Map<String, dynamic> evaluation;

  const ComplianceFlipCard({super.key, required this.evaluation});

  @override
  State<ComplianceFlipCard> createState() => _ComplianceFlipCardState();
}

class _ComplianceFlipCardState extends State<ComplianceFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    final bool isFail = widget.evaluation['status'] == 'FAIL';
    final Color statusColor = isFail ? AppTheme.dangerRed : AppTheme.successGreen;

    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final isUnder = angle > pi / 2;

          return Transform(
            transform: Matrix4.rotationY(angle),
            alignment: Alignment.center,
            child: isUnder
                ? Transform(
                    transform: Matrix4.rotationY(pi),
                    alignment: Alignment.center,
                    child: _buildBackSide(statusColor),
                  )
                : _buildFrontSide(statusColor),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.evaluation['status'] == 'FAIL' ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              widget.evaluation['rule_title'] ?? 'Rule',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap to view details',
            style: TextStyle(fontSize: 9, color: Colors.grey.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide(Color color) {
    final bool isFail = widget.evaluation['status'] == 'FAIL';
    final citation = widget.evaluation['citation'];

    // Extract act name and quote from citation
    String actName = '';
    String quoteText = '';
    if (citation is Map) {
      actName = citation['act_name']?.toString() ?? '';
      quoteText = citation['quote'] ?? citation['content'] ?? citation['text']?.toString() ?? '';
    } else if (citation is String) {
      quoteText = citation;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.evaluation['status'] ?? '',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 10, letterSpacing: 1.1),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.evaluation['reason'] ?? '',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
            // Only show citation details for FAIL rules
            if (isFail && (actName.isNotEmpty || quoteText.isNotEmpty)) ...[
              const SizedBox(height: 6),
              if (actName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '⚖ $actName',
                    style: const TextStyle(fontSize: 9, color: AppTheme.accentCyan, fontWeight: FontWeight.bold),
                  ),
                ),
              if (quoteText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border(left: BorderSide(color: color, width: 3)),
                  ),
                  child: Text(
                    quoteText,
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
