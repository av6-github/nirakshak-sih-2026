import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/compliance_flip_card.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';

class DetailsScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const DetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isComplaint = item['type'] == 'COMPLAINT';
    final title = isComplaint ? 'Complaint Details' : 'Scan Breakdown';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Download Report',
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...')));
                final dio = Dio();
                final endpoint = isComplaint 
                  ? '/reports/complaint/${item['complaint_id']}/download'
                  : '/reports/${item['scan_id']}/download';
                
                final response = await dio.get(
                  '${ApiClient.getBaseUrl}$endpoint',
                  options: Options(responseType: ResponseType.bytes),
                );
                await Printing.sharePdf(bytes: response.data, filename: 'compliance_report.pdf');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download report: $e')));
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${isComplaint ? item['complaint_id'] : item['scan_id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (isComplaint) _buildComplaintDetails(context) else _buildScanDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('Shop Info', [
          'Shopkeeper: ${item['shopkeeper_name'] ?? 'N/A'}',
          'Address: ${item['shop_address'] ?? 'N/A'}',
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Pricing Issue', [
          'Paid Price: ₹${item['paid_price']}',
          'Printed MRP: ₹${item['printed_mrp']}',
          'Description: ${item['description'] ?? 'None'}',
        ]),
        const SizedBox(height: 16),
        const Text('Evidence:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (item['receipt_image_url'] != null)
              Expanded(
                child: Column(
                  children: [
                    const Text('Receipt', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: '${ApiClient.getBaseUrl}${item['receipt_image_url']}'))),
                      child: Image.network('${ApiClient.getBaseUrl}${item['receipt_image_url']}', height: 120, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                    ),
                  ],
                ),
              ),
            if (item['product_image_url'] != null)
              Expanded(
                child: Column(
                  children: [
                    const Text('Product', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: '${ApiClient.getBaseUrl}${item['product_image_url']}'))),
                      child: Image.network('${ApiClient.getBaseUrl}${item['product_image_url']}', height: 120, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image)),
                    ),
                  ],
                ),
              ),
          ],
        )
      ],
    );
  }

  Widget _buildScanDetails(BuildContext context) {
    final declarations = item['extracted_declarations'] ?? {};
    final evaluations = (item['evaluations'] as List?) ?? [];
    final summary = item['compliance_summary'] ?? {};
    final score = summary['compliance_score'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === PRODUCT PHOTOS ===
        if (item['image_urls'] != null && (item['image_urls'] as Map).isNotEmpty) ...[
          const Text(
            'SCANNED EVIDENCE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: (item['image_urls'] as Map<String, dynamic>).entries.map((entry) {
                final String side = entry.key;
                final String url = entry.value?.toString() ?? '';
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

        // === DIGITAL E-COMMERCE TWIN ===
        if (declarations is Map) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Digital E-commerce Twin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Cross-reference physical scan with online listings.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final brand = declarations['manufacturer_name'] ?? '';
                          final product = declarations['generic_product_name'] ?? item['product_category'] ?? '';
                          final query = Uri.encodeComponent('${brand} ${product}'.trim().isEmpty ? 'Packaged Commodity' : '${brand} ${product}');
                          final url = Uri.parse('https://www.google.com/search?tbm=shop&q=$query');
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        },
                        icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                        label: const Text('Google Shopping', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          foregroundColor: Colors.blue[300],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final brand = declarations['manufacturer_name'] ?? '';
                          final product = declarations['generic_product_name'] ?? item['product_category'] ?? '';
                          final query = Uri.encodeComponent('${brand} ${product}'.trim().isEmpty ? 'Packaged Commodity' : '${brand} ${product}');
                          final url = Uri.parse('https://www.amazon.in/s?k=$query');
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        },
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Amazon', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withValues(alpha: 0.2),
                          foregroundColor: Colors.orange[300],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // === REGULATION SCORE ===
        Center(
          child: Column(
            children: [
              const Text('REGULATION SCORE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              Container(
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
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // === EXTRACTED DECLARATIONS ===
        const Text(
          'Extracted Facts',
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
              ...(declarations as Map).entries.toList().asMap().entries.map((entry) {
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

        // === AI LEGAL ANALYSIS (FLIP CARDS) ===
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
      ],
    );
  }

  Widget _buildInfoCard(String title, List<String> lines) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentCyan)),
            const Divider(),
            ...lines.map((l) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(l),
            )),
          ],
        ),
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
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
