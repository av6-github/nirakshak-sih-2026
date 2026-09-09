import 'package:flutter/material.dart';
import 'details_screen.dart';

/// ComplianceResultScreen provides the full compliance breakdown evaluation
/// with the exact same layout, 3D interactive carton avatar, statutory facts table,
/// RAG LLM rule carousel, chatbot linking, price history graph, and PDF export as [DetailsScreen].
class ComplianceResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ComplianceResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return DetailsScreen(item: result);
  }
}
