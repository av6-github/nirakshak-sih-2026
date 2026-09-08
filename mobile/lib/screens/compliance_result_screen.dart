import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/compliance_flip_card.dart';
import 'details_screen.dart';

class ComplianceResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ComplianceResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final String status = result['overall_compliance'] ?? 'REVIEW';
    final Map<String, dynamic> declarations = (result['extracted_declarations'] as Map<String, dynamic>?) ?? {};
    final List evaluations = (result['evaluations'] as List?) ?? [];
    final Map<String, dynamic>? summary = result['compliance_summary'];
    final int score = summary?['compliance_score'] ?? 0;

    Color statusColor = AppTheme.warningOrange;
    IconData statusIcon = Icons.help_outline_rounded;

    if (status == 'PASS') {
      statusColor = AppTheme.successGreen;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (status == 'FAIL') {
      statusColor = AppTheme.dangerRed;
      statusIcon = Icons.cancel_outlined;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance Evaluation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.white24,
                          color: statusColor,
                          strokeWidth: 6,
                        ),
                      ),
                      Text('$score%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REGULATION SCORE',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status == 'PASS'
                              ? 'All mandatory Legal Metrology declarations detected.'
                              : 'Missing ${summary?['failed_rules'] ?? 'required'} declaration(s).',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (result['image_urls'] != null) ...[
              const Text(
                'SCANNED EVIDENCE',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: (result['image_urls'] as Map<String, dynamic>).entries.map((entry) {
                    final String side = entry.key;
                    final String url = entry.value;
                    if (url.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: '${ApiClient.getBaseUrl}$url'))),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                          image: DecorationImage(
                            image: NetworkImage('${ApiClient.getBaseUrl}$url'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black54,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            side.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section: Regulation Score
            Center(
              child: Column(
                children: [
                  const Text('REGULATION SCORE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final summary = result['compliance_summary'] ?? {};
                      final score = summary['compliance_score'] ?? 0;
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black26,
                          border: Border.all(
                            color: score >= 80 ? AppTheme.successGreen : (score >= 50 ? Colors.orange : AppTheme.dangerRed),
                            width: 6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (score >= 80 ? AppTheme.successGreen : (score >= 50 ? Colors.orange : AppTheme.dangerRed)).withValues(alpha: 0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$score%',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Section: Extracted Declarations
            const Text(
              'PRODUCT DETAILS (EXTRACTED FACTS)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppTheme.accentCyan.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppTheme.accentCyan.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('Declaration Field', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan, fontSize: 12))),
                        Expanded(flex: 3, child: Text('Extracted Value', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan, fontSize: 12))),
                      ],
                    ),
                  ),
                  ...declarations.entries.toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final mapEntry = entry.value;
                    final keyStr = mapEntry.key.toString().replaceAll('_', ' ');
                    final label = keyStr.split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
                    return _DeclRow(
                      label: label,
                      value: formatDeclValue(mapEntry.value),
                      index: idx,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section: Deterministic Rule Engine Results
            const Text(
              'DETERMINISTIC RULE ENGINE EVALUATIONS',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...evaluations.map((ev) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      ev['status'] == 'PASS' ? Icons.check_circle : Icons.error,
                      color: ev['status'] == 'PASS' ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                    title: Text(ev['rule_title'] ?? ev['rule_id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(ev['reason'] ?? '', style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (ev['status'] == 'PASS' ? AppTheme.successGreen : AppTheme.dangerRed).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ev['status'],
                        style: TextStyle(
                          color: ev['status'] == 'PASS' ? AppTheme.successGreen : AppTheme.dangerRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                )),

            const SizedBox(height: 24),

            // Section: RAG Legal Knowledge Context
            const Text(
              'RETRIEVED LEGAL KNOWLEDGE (RAG CITATIONS)',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (evaluations.isNotEmpty) ...[
              const Text('AI Legal Analysis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accentCyan)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: evaluations.length,
                itemBuilder: (context, index) {
                  return ComplianceFlipCard(evaluation: Map<String, dynamic>.from(evaluations[index] as Map));
                },
              ),
              const SizedBox(height: 24),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => context.push('/complaint'),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('FILE CONSUMER OVERCHARGING COMPLAINT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningOrange,
                foregroundColor: Colors.black,
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _exportReport(context, status, declarations, evaluations),
              icon: const Icon(Icons.file_download_outlined, color: AppTheme.accentCyan),
              label: const Text('GENERATE CONSUMER REPORT', style: TextStyle(color: AppTheme.accentCyan)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.accentCyan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReport(BuildContext context, String status, Map<String, dynamic> decls, List evaluations) async {
    final scanId = result['id'] ?? result['scan_id'];
    if (scanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot generate report: Scan ID missing.')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
      final dio = Dio();
      final response = await dio.get(
        '${ApiClient.getBaseUrl}/reports/$scanId/download',
        options: Options(responseType: ResponseType.bytes),
      );
      await Printing.sharePdf(bytes: response.data, filename: 'compliance_report_$scanId.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download report: $e')));
    }
  }
}

class _DeclRow extends StatelessWidget {
  final String label;
  final String value;
  final int index;

  const _DeclRow({required this.label, required this.value, required this.index});

  @override
  Widget build(BuildContext context) {
    final bool isMissing = value == 'NOT DETECTED';
    final bool isEven = index % 2 == 0;

    return Container(
      color: isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMissing ? AppTheme.dangerRed : Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
