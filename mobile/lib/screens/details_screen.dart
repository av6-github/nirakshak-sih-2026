import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/pulse_indicator.dart';
import '../widgets/interactive_product_carton_3d.dart';
import '../widgets/price_history_chart.dart';
import 'rules_chat_screen.dart';

class DetailsScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const DetailsScreen({super.key, required this.item});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  int _activeRuleIndex = 0;
  late final PageController _pageController = PageController(initialPage: 0);

  /// Cache of enriched violation data from LLM+RAG. Keyed by rule_id.
  final Map<String, Map<String, dynamic>> _violationCache = {};
  final Set<String> _loadingRuleIds = {};

  /// E-Commerce Twin data: twice-daily price history & product violation history
  Map<String, dynamic>? _ecommerceTwinData;
  bool _loadingEcommerceTwin = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Fetch enriched violation data for a FAIL rule lazily.
  Future<void> _fetchViolationEnrichment(String scanId, String ruleId) async {
    if (_violationCache.containsKey(ruleId) || _loadingRuleIds.contains(ruleId)) return;
    setState(() => _loadingRuleIds.add(ruleId));
    try {
      final result = await ApiClient().getViolationAnalysis(scanId, ruleId: ruleId);
      final violations = result['violations'] as List? ?? [];
      final match = violations.firstWhere(
        (v) => v['rule_id'] == ruleId || v['rule_code'] == ruleId,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty && mounted) {
        setState(() {
          _violationCache[ruleId] = Map<String, dynamic>.from(match);
          _loadingRuleIds.remove(ruleId);
        });
      } else {
        setState(() => _loadingRuleIds.remove(ruleId));
      }
    } catch (e) {
      if (mounted) setState(() => _loadingRuleIds.remove(ruleId));
    }
  }

  /// Fetch twice-daily price history and violation history for this product.
  Future<void> _fetchEcommerceTwin(String scanId) async {
    if (_ecommerceTwinData != null || _loadingEcommerceTwin) return;
    if (scanId.isEmpty || scanId == 'N/A') return;
    setState(() => _loadingEcommerceTwin = true);
    try {
      final data = await ApiClient().getProductEcommerceTwin(scanId);
      if (mounted) {
        setState(() {
          _ecommerceTwinData = data;
          _loadingEcommerceTwin = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingEcommerceTwin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isComplaint = item['type'] == 'COMPLAINT';
    final scanId = (isComplaint ? (item['complaint_id'] ?? item['id']) : (item['scan_id'] ?? item['id']))?.toString() ?? 'N/A';

    return Scaffold(
      backgroundColor: AppTheme.auraBg,
      body: AuraBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable Content
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: 110, // Padding for floating bottom dock
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, isComplaint, scanId),
                      const SizedBox(height: 12),
                      _buildScanIdPill(context, scanId),
                      const SizedBox(height: 16),
                      if (isComplaint)
                        _buildComplaintDetails(context)
                      else
                        _buildScanDetails(context),
                    ],
                  ),
                ),
              ),

              // Floating Dock Action Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildFloatingDock(context, isComplaint, scanId),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Top Navigation Header ---
  Widget _buildHeader(BuildContext context, bool isComplaint, String scanId) {
    return Column(
      children: [
        // Action Bar Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Circular Glass Button
            GestureDetector(
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/home');
                }
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppTheme.slate700,
                ),
              ),
            ),

            // Center Branding & Title
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.emerald600.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Text(
                    'NIRIKSHAK AI',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppTheme.emerald600,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isComplaint ? 'Complaint Details' : 'Scan Breakdown',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppTheme.slate900,
                  ),
                ),
              ],
            ),

            // PDF Action Button
            GestureDetector(
              onTap: () => _downloadPdfReport(context, isComplaint, scanId),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 14,
                      color: Color(0xFFF43F5E), // Rose 500
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PDF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Scan ID Pill Badge ---
  Widget _buildScanIdPill(BuildContext context, String scanId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Text(
                  '#',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate400,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ID: $scanId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.slate700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: scanId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scan ID copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.copy_rounded,
                size: 14,
                color: AppTheme.slate400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Scan Breakdown Complete Layout ---
  Widget _buildScanDetails(BuildContext context) {
    final item = widget.item;
    final String scanId = (item['scan_id'] ?? item['id'] ?? '').toString();
    final declarations = (item['extracted_declarations'] as Map?) ?? {};
    final evaluations = (item['evaluations'] as List?) ?? [];
    final summary = (item['compliance_summary'] as Map?) ?? {};
    final totalRules = evaluations.length;
    final passedRules = evaluations.where((e) {
      final st = (e['status'] ?? '').toString().toUpperCase();
      return st == 'PASS' || st == 'YES' || st == 'COMPLIANT' || st == 'TRUE';
    }).length;
    final int dynamicScore = totalRules > 0 ? ((passedRules / totalRules) * 100).round() : 0;
    final int score = summary['compliance_score'] is int
        ? summary['compliance_score'] as int
        : (summary['compliance_score'] != null ? int.tryParse(summary['compliance_score'].toString()) ?? dynamicScore : dynamicScore);
    final imageUrls = (item['image_urls'] as Map?) ?? {};

    // Format declarations — NO hardcoded fallbacks; show null as missing
    final prodName = (declarations['generic_product_name'] ?? declarations['generic_name'] ?? declarations['product_name'])?.toString();
    final mfgName = (declarations['manufacturer_name'] ?? declarations['packer_name'] ?? declarations['importer_name'])?.toString();
    final mrpValue = declarations['mrp']?.toString();
    final mfgDate = declarations['manufacturing_date']?.toString()
        ?? ((declarations['manufacture_month'] != null || declarations['manufacture_year'] != null)
            ? '${declarations['manufacture_month'] ?? ''}/${declarations['manufacture_year'] ?? ''}'.trim()
            : null);
    final expDate = declarations['expiry_date']?.toString();
    final netQty = declarations['net_quantity'] != null
        ? '${declarations['net_quantity']} ${declarations['unit'] ?? ''}'.trim()
        : null;
    final batchId = (declarations['batch_number'] ?? declarations['batch_no'])?.toString();
    final contactPhone = declarations['consumer_care_phone']?.toString();
    final contactEmail = declarations['consumer_care_email']?.toString();
    final contactAddress = declarations['consumer_care_address']?.toString();
    final contact = (contactPhone != null && contactPhone.isNotEmpty)
        ? contactPhone
        : ((contactEmail != null && contactEmail.isNotEmpty)
            ? contactEmail
            : contactAddress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SCANNED EVIDENCE SECTION
        _buildScannedEvidenceSection(context, imageUrls),

        const SizedBox(height: 20),

        // 2. PRODUCT AVATAR (3D RECONSTRUCTED CARTON)
        _buildProductAvatarSection(
          declarations: Map<String, dynamic>.from(declarations),
          imageUrls: Map<String, dynamic>.from(imageUrls),
          prodName: prodName,
          mfgName: mfgName,
          mrpValue: mrpValue,
          mfgDate: mfgDate,
          expDate: expDate,
          netQty: netQty,
          batchId: batchId,
        ),

        const SizedBox(height: 20),

        // 3. RULE CAROUSEL CARD (Rule #1 of N)
        _buildRuleCarouselCard(evaluations, mrpValue, mfgDate, expDate, score),

        const SizedBox(height: 18),

        // 4. REGULATION COMPLIANCE SCORE CARD
        _buildComplianceScoreCard(score),

        const SizedBox(height: 20),

        // 5. EXTRACTED FACTS TABLE
        _buildExtractedFactsTable(
          mfgName: mfgName,
          prodName: prodName,
          netQty: netQty,
          batchId: batchId,
          contact: contact,
          declarations: Map<String, dynamic>.from(declarations),
          item: Map<String, dynamic>.from(item),
          evaluations: evaluations,
        ),

        const SizedBox(height: 18),

        // 6. DIGITAL E-COMMERCE TWIN
        _buildEcommerceTwinSection(mfgName, prodName, scanId, mrpValue),
      ],
    );
  }

  // --- 1. Scanned Evidence Section ---
  Widget _buildScannedEvidenceSection(BuildContext context, Map imageUrls) {
    final validImages = imageUrls.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
    final count = validImages.isNotEmpty ? validImages.length : 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SCANNED EVIDENCE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppTheme.slate600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.emerald600.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.emerald600.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '$count Angles Verified',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.emerald600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 3 Thumbnail Cards Grid
        if (validImages.isNotEmpty)
          Row(
            children: validImages.map((entry) {
              final side = entry.key.toString().toUpperCase();
              final url = entry.value.toString();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrl: url.startsWith('http') ? url : '${ApiClient.getBaseUrl}$url',
                        ),
                      ),
                    ),
                    child: _buildEvidenceCard(
                      label: side,
                      imageWidget: Image.network(
                        url.startsWith('http') ? url : '${ApiClient.getBaseUrl}$url',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => _buildPlaceholderEvidence(side),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        else
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildEvidenceCard(
                    label: 'FRONT',
                    imageWidget: _buildPlaceholderEvidence('FRONT'),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildEvidenceCard(
                    label: 'BACK',
                    imageWidget: _buildPlaceholderEvidence('BACK'),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildEvidenceCard(
                    label: 'TOP',
                    imageWidget: _buildPlaceholderEvidence('TOP'),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildEvidenceCard({required String label, required Widget imageWidget}) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.slate100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageWidget,
                  // Verified Green Dot Indicator
                  Positioned(
                    top: 4,
                    left: 5,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.emerald600,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppTheme.slate700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderEvidence(String side) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.slate200),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported_outlined, size: 20, color: AppTheme.slate400),
          const SizedBox(height: 4),
          Text(
            '$side VIEW',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.slate600, fontFamily: 'monospace'),
          ),
          const Text(
            'Angle not uploaded',
            style: TextStyle(fontSize: 6.5, color: AppTheme.slate400),
          ),
        ],
      ),
    );
  }

  // --- 2. Product Avatar (3D Box Simulation) ---
  Widget _buildProductAvatarSection({
    required Map<String, dynamic> declarations,
    required Map<String, dynamic> imageUrls,
    String? prodName,
    String? mfgName,
    String? mrpValue,
    String? mfgDate,
    String? expDate,
    String? netQty,
    String? batchId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRODUCT AVATAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppTheme.slate600,
              ),
            ),
            Text(
              '3D Geometry Reconstructed',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Interactive 3D Carton
        InteractiveProductCarton3D(
          declarations: declarations,
          imageUrls: imageUrls,
          productName: prodName,
          manufacturer: mfgName,
          mrp: mrpValue,
          mfgDate: mfgDate,
          expDate: expDate,
          netQuantity: netQty,
          batchNo: batchId,
        ),
      ],
    );
  }

  // --- 3. Rule Carousel Card ---
  Widget _buildRuleCarouselCard(
    List rawEvaluations,
    String? mrpValue,
    String? mfgDate,
    String? expDate,
    int complianceScore,
  ) {
    final rulesList = [
      {
        'is_summary': true,
        'score': complianceScore,
      },
      ...rawEvaluations
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 270, // Height for Reason, RAG Citation Quote, Penalties, and Ask AI button
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _activeRuleIndex = index);
              },
              itemCount: rulesList.length,
              itemBuilder: (context, index) {
                final currentRule = Map<String, dynamic>.from(rulesList[index] as Map);
                final isSummary = currentRule['is_summary'] == true;
                
                if (isSummary) {
                  final bool isOverallPass = complianceScore >= 80;
                  return _buildSummarySlide(isOverallPass, complianceScore, index, rulesList.length);
                } else {
                  final String ruleId = (currentRule['rule_id'] ?? currentRule['rule_code'] ?? '').toString();
                  final cached = _violationCache[ruleId];
                  final ruleData = cached != null ? {...currentRule, ...cached} : currentRule;

                  final String ruleTitle = ruleData['rule_title'] ?? ruleData['rule_name'] ?? ruleData['rule_id'] ?? 'Rule';
                  final String ruleCode = ruleData['rule_code'] ?? ruleData['rule_reference'] ?? 'Rule #$index';
                  final String statusStr = (ruleData['status'] ?? 'FAIL').toString().toUpperCase();
                  final bool isPass = statusStr == 'PASS' || statusStr == 'YES' || statusStr == 'COMPLIANT' || statusStr == 'TRUE';
                  final String reason = ruleData['reason'] ?? ruleData['details'] ?? 'No supporting evidence available.';
                  
                  // Extract penalty and RAG citation
                  String penalty = (ruleData['penalty'] ?? ruleData['penalties'] ?? '').toString();
                  final citation = ruleData['citation'] as Map?;
                  final String? legalQuote = (citation?['quote'] ?? ruleData['legal_quote'])?.toString();
                  final String? actName = (citation?['act_name'] ?? ruleData['act_name'] ?? citation?['rule_reference'])?.toString();

                  // Lazy trigger LLM RAG enrichment if rule failed and penalty is missing
                  final String scanId = (widget.item['scan_id'] ?? widget.item['id'] ?? '').toString();
                  if (!isPass && penalty.isEmpty && ruleId.isNotEmpty && scanId.isNotEmpty && scanId != 'N/A') {
                    _fetchViolationEnrichment(scanId, ruleId);
                  }
                  
                  return SingleChildScrollView(
                    child: _buildRuleSlide(
                      title: ruleTitle,
                      code: ruleCode,
                      statusStr: statusStr,
                      isPass: isPass,
                      reason: reason,
                      penalty: penalty,
                      legalQuote: legalQuote,
                      actName: actName,
                      activeIndex: index,
                      totalLength: rulesList.length,
                    ),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 14),
          // Pagination Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(rulesList.length, (idx) {
              final isCurrent = idx == _activeRuleIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isCurrent ? 20 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.emerald600 : AppTheme.slate300,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySlide(bool isPass, int score, int activeIndex, int totalLength) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildRightArrow(activeIndex, totalLength),
          ],
        ),
        const SizedBox(height: 4),
        Icon(
          isPass ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
          size: 72,
          color: isPass ? AppTheme.successGreen : AppTheme.dangerRed,
        ),
        const SizedBox(height: 12),
        Text(
          isPass ? 'PRODUCT IS COMPLIANT' : 'PRODUCT NON-COMPLIANT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isPass ? AppTheme.successGreen : AppTheme.dangerRed,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Overall Compliance Score: $score%',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate600,
          ),
        ),
      ],
    );
  }

  Widget _buildRuleSlide({
    required String title,
    required String code,
    required String statusStr,
    required bool isPass,
    required String reason,
    required String penalty,
    String? legalQuote,
    String? actName,
    required int activeIndex,
    required int totalLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isPass ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isPass ? AppTheme.successGreen : AppTheme.dangerRed,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUDIT $code OF ${totalLength - 1}'.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: isPass ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppTheme.slate900,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isPass ? AppTheme.successGreen : AppTheme.dangerRed).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusStr,
                style: TextStyle(
                  color: isPass ? AppTheme.successGreen : AppTheme.dangerRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _buildLeftArrow(activeIndex),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clickable Evidence & Reason Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RulesChatScreen(
                            initialTabIndex: 1,
                            quotedRuleCode: code,
                            quotedRuleTitle: title,
                            violationReason: reason,
                            violationPenalty: penalty,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.slate200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('EVIDENCE / REASON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
                              Row(
                                children: [
                                  Text(
                                    'Click to consult AI',
                                    style: TextStyle(fontSize: 8.5, color: AppTheme.emerald600.withValues(alpha: 0.9), fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: AppTheme.emerald600),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(reason, style: const TextStyle(fontSize: 12, color: AppTheme.slate800, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  if (legalQuote != null && legalQuote.isNotEmpty && legalQuote != 'null') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC).withValues(alpha: 0.95), // Slate 50
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)), // Slate 300
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.gavel_rounded, size: 12, color: AppTheme.slate700),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  (actName != null && actName.isNotEmpty && actName != 'null')
                                      ? actName.toUpperCase()
                                      : 'OFFICIAL LMPC ACT QUOTATION',
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.slate700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            legalQuote,
                            style: const TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!isPass && penalty.isNotEmpty && penalty != 'null') ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RulesChatScreen(
                              initialTabIndex: 1,
                              quotedRuleCode: code,
                              quotedRuleTitle: title,
                              violationReason: reason,
                              violationPenalty: penalty,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB).withValues(alpha: 0.9), // Amber 50
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCD34D).withValues(alpha: 0.8)), // Amber 300
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_rounded, size: 12, color: Color(0xFF92400E)),
                                SizedBox(width: 4),
                                Text('PENALTIES / CONSEQUENCES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(penalty, style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Dedicated "Ask Legal AI" Button
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RulesChatScreen(
                            initialTabIndex: 1,
                            quotedRuleCode: code,
                            quotedRuleTitle: title,
                            violationReason: reason,
                            violationPenalty: penalty,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppTheme.slate900,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome, size: 13, color: AppTheme.emerald400),
                          const SizedBox(width: 6),
                          Text(
                            isPass ? 'Ask Legal AI About This Rule' : 'Ask Legal AI About This Violation',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.emerald400),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: _buildRightArrow(activeIndex, totalLength),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeftArrow(int activeIndex) {
    return GestureDetector(
      onTap: () {
        if (activeIndex > 0) {
          _pageController.animateToPage(activeIndex - 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      },
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.slate200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
          ],
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 11, color: AppTheme.slate700),
      ),
    );
  }

  Widget _buildRightArrow(int activeIndex, int totalLength) {
    return GestureDetector(
      onTap: () {
        if (activeIndex < totalLength - 1) {
          _pageController.animateToPage(activeIndex + 1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        }
      },
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.slate200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
          ],
        ),
        child: const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.slate700),
      ),
    );
  }

  // --- 4. Regulation Compliance Score Card ---
  Widget _buildComplianceScoreCard(int score) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Gauge
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: AppTheme.slate200,
                  color: score >= 80 ? AppTheme.emerald600 : (score >= 50 ? AppTheme.warningOrange : AppTheme.dangerRed),
                  strokeWidth: 5.5,
                ),
                Text(
                  '$score%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12.5,
                    fontFamily: 'monospace',
                    color: AppTheme.slate900,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Score Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'REGULATION COMPLIANCE SCORE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppTheme.slate800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    PulseIndicator(
                      color: score >= 80 ? AppTheme.emerald600 : AppTheme.warningOrange,
                      size: 7,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  score >= 80 ? 'Compliant with LMPC PC Rules 2011' : 'Non-compliance flags detected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: score >= 80 ? AppTheme.emerald600 : AppTheme.dangerRed,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Packaged Commodities & Drug Controller Standard',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Extracted Facts Table ---
  Widget _buildExtractedFactsTable({
    String? mfgName,
    String? prodName,
    String? netQty,
    String? batchId,
    String? contact,
    required Map<String, dynamic> declarations,
    Map<String, dynamic>? item,
    List<dynamic>? evaluations,
  }) {
    final rootItem = item ?? widget.item;
    final List<dynamic> evals = evaluations ?? (rootItem['evaluations'] as List?) ?? [];

    final failedEvals = evals.where((e) {
      final st = (e['status'] ?? '').toString().toUpperCase();
      return st == 'FAIL' || st == 'VIOLATION' || st == 'NON_COMPLIANT';
    }).toList();

    bool isRuleFailed(List<String> keywords) {
      for (final ev in failedEvals) {
        final rId = (ev['rule_id'] ?? ev['rule_code'] ?? '').toString().toLowerCase();
        final rTitle = (ev['rule_title'] ?? '').toString().toLowerCase();
        final reason = (ev['reason'] ?? '').toString().toLowerCase();
        final field = (ev['field'] ?? ev['field_name'] ?? '').toString().toLowerCase();

        for (final kw in keywords) {
          final k = kw.toLowerCase();
          if (rId.contains(k) || rTitle.contains(k) || reason.contains(k) || field.contains(k)) {
            return true;
          }
        }
      }
      return false;
    }

    String? getVal(List<String> keys) {
      for (final k in keys) {
        if (declarations.containsKey(k) && declarations[k] != null) {
          final v = declarations[k].toString().trim();
          if (v.isNotEmpty && v.toLowerCase() != 'null' && v.toLowerCase() != 'none') return v;
        }
        if (rootItem.containsKey(k) && rootItem[k] != null) {
          final v = rootItem[k].toString().trim();
          if (v.isNotEmpty && v.toLowerCase() != 'null' && v.toLowerCase() != 'none') return v;
        }
      }
      return null;
    }

    final List<Widget> rows = [];

    void maybeAddRow({
      required String label,
      required String? value,
      required bool isNonCompliant,
      bool isBold = false,
      bool isEmerald = false,
      bool isBadge = false,
      bool isMono = false,
      String missingLabel = 'Not Declared',
    }) {
      final bool isDetected = value != null &&
          value.trim().isNotEmpty &&
          value.trim().toLowerCase() != 'null' &&
          value.trim().toLowerCase() != 'none';

      // Show only what's extracted, and not missing unless it's non-compliant
      if (isDetected) {
        rows.add(_buildFactRow(
          label,
          value,
          isBold: isBold,
          isEmerald: isEmerald,
          isBadge: isBadge,
          isMono: isMono,
        ));
      } else if (isNonCompliant) {
        rows.add(_buildFactRow(
          label,
          null,
          isBold: isBold,
          isEmerald: isEmerald,
          isBadge: isBadge,
          isMono: isMono,
          missingLabel: missingLabel,
        ));
      }
    }

    // 1. Manufacturer Name
    final mfgVal = mfgName ?? getVal(['manufacturer_name', 'mfg_name', 'manufacturer']);
    maybeAddRow(
      label: 'Manufacturer Name',
      value: mfgVal,
      isNonCompliant: isRuleFailed(['manufacturer', 'rule-lm-003', 'packer', 'importer']),
      isBold: true,
    );

    // 2. Manufacturer Address
    final mfgAddrVal = getVal(['manufacturer_address', 'mfg_address', 'factory_address', 'premise_address']);
    maybeAddRow(
      label: 'Manufacturer Address',
      value: mfgAddrVal,
      isNonCompliant: isRuleFailed(['manufacturer_address', 'factory_address', 'premise_address']),
    );

    // 3. Generic Product Name
    final genericVal = prodName ?? getVal(['generic_product_name', 'generic_name', 'product_name', 'commodity_name']);
    maybeAddRow(
      label: 'Generic Product Name',
      value: genericVal,
      isNonCompliant: isRuleFailed(['generic_product_name', 'rule-lm-006', 'commodity', 'generic name']),
      isEmerald: true,
    );

    // 4. Maximum Retail Price (MRP)
    final rawMrp = getVal(['mrp', 'price', 'maximum_retail_price']);
    final currency = getVal(['currency']) ?? '₹';
    final mrpDisplay = rawMrp != null
        ? (rawMrp.startsWith('₹') || rawMrp.startsWith('Rs')
            ? '$rawMrp (Incl. of all taxes)'
            : '$currency $rawMrp (Incl. of all taxes)')
        : null;
    maybeAddRow(
      label: 'Maximum Retail Price (MRP)',
      value: mrpDisplay,
      isNonCompliant: isRuleFailed(['mrp', 'rule-lm-001', 'retail price', 'maximum price']),
      isBold: true,
    );

    // 5. Unit Sale Price (USP)
    final uspVal = getVal(['unit_sale_price', 'usp', 'unit_price']);
    maybeAddRow(
      label: 'Unit Sale Price (USP)',
      value: uspVal,
      isNonCompliant: isRuleFailed(['unit sale price', 'usp']),
    );

    // 6. Net Quantity
    final netQtyVal = netQty ?? (() {
      final q = getVal(['net_quantity', 'quantity', 'net_wt', 'net_weight', 'net_volume']);
      final u = getVal(['unit', 'net_quantity_unit', 'metric_unit']) ?? '';
      if (q != null && q.isNotEmpty) {
        return '$q $u'.trim();
      }
      return null;
    })();
    maybeAddRow(
      label: 'Net Quantity',
      value: netQtyVal,
      isNonCompliant: isRuleFailed(['net_quantity', 'rule-lm-002', 'quantity', 'weight', 'measure', 'unit']),
      isBadge: true,
    );

    // 7. Month & Year of Manufacture
    final mfgDateVal = getVal(['manufacturing_date', 'mfg_date', 'packing_date', 'packed_date']) ?? (() {
      final m = getVal(['manufacture_month', 'mfg_month']);
      final y = getVal(['manufacture_year', 'mfg_year']);
      if (m != null || y != null) {
        return '${m ?? ''}/${y ?? ''}'.trim();
      }
      return null;
    })();
    maybeAddRow(
      label: 'Date of Manufacture',
      value: mfgDateVal,
      isNonCompliant: isRuleFailed(['manufacture_date', 'rule-lm-004', 'month', 'year', 'packing date']),
    );

    // 8. Best Before / Expiry Date
    final expDateVal = getVal(['expiry_date', 'best_before', 'use_by', 'exp_date']);
    maybeAddRow(
      label: 'Expiry / Best Before',
      value: expDateVal,
      isNonCompliant: isRuleFailed(['expiry', 'best before', 'use by']),
    );

    // 9. Batch Identifier
    final batchVal = batchId ?? getVal(['batch_number', 'batch_no', 'lot_number', 'lot_no', 'batch_code']);
    maybeAddRow(
      label: 'Batch Identifier',
      value: batchVal,
      isNonCompliant: isRuleFailed(['batch', 'lot number', 'lot no']),
      isMono: true,
      missingLabel: 'Missing',
    );

    // 10. Consumer Care Support
    final phoneVal = getVal(['consumer_care_phone', 'customer_care_phone', 'helpline', 'care_phone', 'toll_free']);
    final emailVal = getVal(['consumer_care_email', 'customer_care_email', 'email', 'support_email']);
    final careAddrVal = getVal(['consumer_care_address', 'customer_care_address', 'care_address']);
    final careContact = contact ?? phoneVal ?? emailVal ?? careAddrVal;
    maybeAddRow(
      label: 'Consumer Care Support',
      value: careContact,
      isNonCompliant: isRuleFailed(['consumer_care', 'rule-lm-005', 'customer care', 'helpline', 'contact', 'telephone', 'email']),
      isMono: true,
      missingLabel: 'Missing',
    );

    // 11. Consumer Care Email (if distinct)
    if (emailVal != null && emailVal != careContact) {
      maybeAddRow(
        label: 'Consumer Care Email',
        value: emailVal,
        isNonCompliant: false,
        isMono: true,
      );
    }

    // 12. Consumer Care Address (if distinct)
    if (careAddrVal != null && careAddrVal != careContact) {
      maybeAddRow(
        label: 'Consumer Care Address',
        value: careAddrVal,
        isNonCompliant: false,
      );
    }

    // 13. Country of Origin
    final cooVal = getVal(['country_of_origin', 'origin_country', 'made_in', 'origin']);
    maybeAddRow(
      label: 'Country of Origin',
      value: cooVal,
      isNonCompliant: isRuleFailed(['country of origin', 'origin', 'made in']),
    );

    // 14. Packer Details
    final packerVal = getVal(['packer_name', 'packer_address', 'packed_by']);
    maybeAddRow(
      label: 'Packer Details',
      value: packerVal,
      isNonCompliant: isRuleFailed(['packer']),
    );

    // 15. Importer Details
    final importerVal = getVal(['importer_name', 'importer_address', 'imported_by']);
    maybeAddRow(
      label: 'Importer Details',
      value: importerVal,
      isNonCompliant: isRuleFailed(['importer']),
    );

    // 16. FSSAI License Number
    final fssaiVal = getVal(['fssai_license_number', 'fssai_license', 'fssai_no', 'license_no']);
    maybeAddRow(
      label: 'FSSAI License No.',
      value: fssaiVal,
      isNonCompliant: isRuleFailed(['fssai', 'food safety']),
      isMono: true,
    );

    // 17. Barcode / GS1 GTIN
    final barcodeVal = getVal(['barcode', 'ean_code', 'gtin', 'upc']);
    maybeAddRow(
      label: 'Barcode / GTIN',
      value: barcodeVal,
      isNonCompliant: isRuleFailed(['barcode', 'gtin', 'ean']),
      isMono: true,
    );

    // 18. Dietary Indicator (Veg / Non-Veg)
    final vegVal = getVal(['veg_nonveg', 'is_vegetarian', 'dietary_indicator']);
    maybeAddRow(
      label: 'Dietary Indicator',
      value: vegVal,
      isNonCompliant: isRuleFailed(['vegetarian', 'dietary']),
    );

    // 19. All other dynamic extracted fields (e.g. ingredients, dimensions, storage, etc.)
    final handledKeys = {
      'generic_product_name', 'generic_name', 'product_name', 'commodity_name',
      'mrp', 'price', 'maximum_retail_price', 'currency', 'unit_sale_price', 'usp', 'unit_price',
      'net_quantity', 'quantity', 'net_wt', 'net_weight', 'net_volume', 'unit', 'net_quantity_unit', 'metric_unit',
      'manufacturer_name', 'mfg_name', 'manufacturer', 'manufacturer_address', 'mfg_address', 'factory_address', 'premise_address',
      'packer_name', 'packer_address', 'packed_by', 'importer_name', 'importer_address', 'imported_by',
      'country_of_origin', 'origin_country', 'made_in', 'origin',
      'manufacturing_date', 'mfg_date', 'packing_date', 'packed_date', 'manufacture_month', 'mfg_month', 'manufacture_year', 'mfg_year',
      'expiry_date', 'best_before', 'use_by', 'exp_date',
      'batch_number', 'batch_no', 'lot_number', 'lot_no', 'batch_code',
      'consumer_care_phone', 'customer_care_phone', 'helpline', 'care_phone', 'toll_free',
      'consumer_care_email', 'customer_care_email', 'email', 'support_email',
      'consumer_care_address', 'customer_care_address', 'care_address',
      'consumer_care_name', 'customer_care_name', 'care_person',
      'fssai_license_number', 'fssai_license', 'fssai_no', 'license_no',
      'barcode', 'ean_code', 'gtin', 'upc',
      'veg_nonveg', 'is_vegetarian', 'dietary_indicator',
      'dynamic_fields', 'raw_extractions', 'raw_declarations', 'field_confidence', 'bounding_boxes',
    };

    void addDynamicField(String k, dynamic v) {
      if (v == null || handledKeys.contains(k.toLowerCase())) return;
      final str = v.toString().trim();
      if (str.isEmpty || str.toLowerCase() == 'null' || str.toLowerCase() == 'none') return;

      final formattedLabel = k
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');

      maybeAddRow(
        label: formattedLabel,
        value: str,
        isNonCompliant: false,
      );
    }

    declarations.forEach((k, v) {
      if (k == 'dynamic_fields' && v is Map) {
        v.forEach((dk, dv) => addDynamicField(dk.toString(), dv));
      } else if (k == 'raw_extractions' && v is Map) {
        v.forEach((rk, rv) => addDynamicField(rk.toString(), rv));
      } else {
        addDynamicField(k, v);
      }
    });

    final List<Widget> children = [];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(const Divider(height: 1, thickness: 0.5));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXTRACTED FACTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: AppTheme.slate600,
              ),
            ),
            Text(
              'EXTRACTED VALUE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppTheme.slate500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFactRow(
    String label,
    String? value, {
    bool isBold = false,
    bool isEmerald = false,
    bool isBadge = false,
    bool isMono = false,
    String missingLabel = 'Not Declared',
  }) {
    final bool isMissing = value == null || value.trim().isEmpty || value.trim().toLowerCase() == 'null' || value.trim().toLowerCase() == 'none';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: isMissing
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2), // Red 100
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCA5A5)), // Red 300
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 11,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          missingLabel,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  )
                : isBadge
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.slate200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            color: AppTheme.slate900,
                          ),
                        ),
                      )
                    : Text(
                        value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isBold || isEmerald ? FontWeight.w800 : FontWeight.w600,
                          fontFamily: isMono ? 'monospace' : null,
                          color: isEmerald
                              ? AppTheme.emerald600
                              : (isBold ? AppTheme.slate900 : AppTheme.slate800),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // --- 6. Digital E-Commerce Twin ---
  Widget _buildEcommerceTwinSection(String? mfgName, String? prodName, String scanId, String? mrpValue) {
    // Lazy fetch e-commerce twin data (twice-daily price checkpoints & violation history)
    if (_ecommerceTwinData == null && !_loadingEcommerceTwin && scanId.isNotEmpty && scanId != 'N/A') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchEcommerceTwin(scanId);
      });
    }

    final bool hasSearchQuery = (mfgName != null && mfgName.isNotEmpty) || (prodName != null && prodName.isNotEmpty);
    final String queryTerm = '${mfgName ?? ''} ${prodName ?? ''}'.trim();

    final twin = _ecommerceTwinData;
    final List rawPriceHistory = (twin?['price_history'] as List?) ?? [];
    final List<Map<String, dynamic>> priceHistory = rawPriceHistory
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final List rawViolations = (twin?['violation_history'] as List?) ?? [];
    final List<Map<String, dynamic>> violationHistory = rawViolations
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final stats = (twin?['price_statistics'] as Map?) ?? {};
    final double? declaredMrp = (stats['declared_mrp'] as num?)?.toDouble()
        ?? (mrpValue != null ? double.tryParse(mrpValue.replaceAll(RegExp(r'[^0-9.]'), '')) : null);

    final double? currentPrice = (stats['current_price'] as num?)?.toDouble()
        ?? (priceHistory.isNotEmpty ? (priceHistory.last['price'] as num?)?.toDouble() : declaredMrp);
    final double? minPrice = (stats['min_price'] as num?)?.toDouble();
    final double? maxPrice = (stats['max_price'] as num?)?.toDouble();
    final bool hasOvercharge = stats['has_overcharging_violation'] == true ||
        (declaredMrp != null && currentPrice != null && currentPrice > declaredMrp);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.emerald600.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.emerald600.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.storefront_rounded, size: 17, color: AppTheme.emerald600),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIGITAL E-COMMERCE TWIN',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        letterSpacing: 1.0,
                        color: AppTheme.slate800,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Continuous Market Price Surveillance & Violation Log',
                      style: TextStyle(color: AppTheme.slate500, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseIndicator(color: AppTheme.emerald600, size: 6),
                    SizedBox(width: 5),
                    Text(
                      '2x Daily Surveillance',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Rule 18(2) Compliance Alert Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasOvercharge ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasOvercharge ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasOvercharge ? Icons.gavel_rounded : Icons.verified_user_rounded,
                  size: 18,
                  color: hasOvercharge ? AppTheme.dangerRed : AppTheme.emerald600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasOvercharge
                            ? 'RULE 18(2) VIOLATION — DUAL PRICING DETECTED'
                            : 'RULE 18(2) COMPLIANT — PRICE WITHIN MRP',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: hasOvercharge ? AppTheme.dangerRed : AppTheme.emerald600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasOvercharge
                            ? 'Marketplace listing price exceeds the declared package MRP. Non-compliance under Rule 18(2) of LMPC Rules, 2011 punishable under Section 36.'
                            : 'All recorded morning (09:00 AM) & evening (06:00 PM) marketplace checkpoints comply with declared package MRP.',
                        style: TextStyle(
                          fontSize: 10,
                          color: hasOvercharge ? const Color(0xFF991B1B) : const Color(0xFF166534),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Price Statistics Strip
          Row(
            children: [
              Expanded(
                child: _buildPriceStatChip(
                  label: 'Current Online',
                  value: currentPrice != null ? '₹${currentPrice.toStringAsFixed(2)}' : 'N/A',
                  color: hasOvercharge ? AppTheme.dangerRed : AppTheme.emerald600,
                  isHighlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriceStatChip(
                  label: 'Declared MRP',
                  value: declaredMrp != null ? '₹${declaredMrp.toStringAsFixed(2)}' : 'N/A',
                  color: const Color(0xFFE11D48),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriceStatChip(
                  label: '7-Day Min',
                  value: minPrice != null ? '₹${minPrice.toStringAsFixed(2)}' : 'N/A',
                  color: AppTheme.slate700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriceStatChip(
                  label: '7-Day Max',
                  value: maxPrice != null ? '₹${maxPrice.toStringAsFixed(2)}' : 'N/A',
                  color: AppTheme.slate700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Subheader: Price History Graph
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TWICE-DAILY PRICE SURVEILLANCE TREND',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                  color: AppTheme.slate700,
                ),
              ),
              Text(
                '09:00 AM / 06:00 PM Log',
                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppTheme.slate400),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Interactive CustomPainter Spline Chart
          if (_loadingEcommerceTwin && priceHistory.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emerald600),
            )
          else
            PriceHistoryChart(
              priceHistory: priceHistory,
              declaredMrp: declaredMrp,
              height: 180,
            ),

          const SizedBox(height: 18),

          // Product Violation History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PRODUCT VIOLATION HISTORY',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                  color: AppTheme.slate700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: violationHistory.isNotEmpty
                      ? AppTheme.dangerRed.withValues(alpha: 0.12)
                      : AppTheme.emerald600.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  violationHistory.isNotEmpty ? '${violationHistory.length} Incident(s)' : 'Clean Record',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: violationHistory.isNotEmpty ? AppTheme.dangerRed : AppTheme.emerald600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (violationHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppTheme.emerald600),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No historical compliance violations recorded for this commodity.',
                      style: TextStyle(fontSize: 11, color: AppTheme.slate600, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: violationHistory.take(4).map((v) => _buildViolationHistoryCard(v)).toList(),
            ),

          const SizedBox(height: 14),

          // Cross-Reference Marketplaces
          const Text(
            'CROSS-REFERENCE MARKETPLACES',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              color: AppTheme.slate600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasSearchQuery
                      ? () async {
                          final query = Uri.encodeComponent(queryTerm);
                          final url = Uri.parse('https://www.google.com/search?tbm=shop&q=$query');
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        }
                      : null,
                  icon: const Icon(Icons.shopping_cart_outlined, size: 14),
                  label: const Text('Google Shopping', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withValues(alpha: 0.12),
                    foregroundColor: Colors.blue[800],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: hasSearchQuery
                      ? () async {
                          final query = Uri.encodeComponent(queryTerm);
                          final url = Uri.parse('https://www.amazon.in/s?k=$query');
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        }
                      : null,
                  icon: const Icon(Icons.search_rounded, size: 14),
                  label: const Text('Amazon Search', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.14),
                    foregroundColor: Colors.orange[900],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceStatChip({
    required String label,
    required String value,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlight ? color.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: AppTheme.slate500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViolationHistoryCard(Map<String, dynamic> v) {
    final isRepeat = v['is_repeat_offence'] == true;
    final ruleCode = (v['rule_code'] ?? 'RULE').toString();
    final ruleTitle = (v['rule_title'] ?? v['field_name'] ?? 'Violation').toString();
    final date = (v['date'] ?? '').toString();
    final reason = (v['reason'] ?? '').toString();
    final penalty = (v['penalty'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isRepeat ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isRepeat ? 'REPEAT OFFENCE (ESCALATED)' : 'FIRST OFFENCE',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 9, color: AppTheme.slate500, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFB45309)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$ruleCode: $ruleTitle',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              reason,
              style: const TextStyle(fontSize: 10, color: Color(0xFF78350F), height: 1.2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (penalty.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              penalty,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Color(0xFFB45309),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // --- Complaint View Fallback ---
  Widget _buildComplaintDetails(BuildContext context) {
    final item = widget.item;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shop & Retailer Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.slate900)),
              const Divider(height: 14),
              Text('Shopkeeper: ${item['shopkeeper_name'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate800)),
              const SizedBox(height: 4),
              Text('Address: ${item['shop_address'] ?? 'N/A'}', style: const TextStyle(fontSize: 12, color: AppTheme.slate600)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pricing Discrepancy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.slate900)),
              const Divider(height: 14),
              Text('Paid Price: ₹${item['paid_price']}', style: const TextStyle(fontSize: 14, color: AppTheme.dangerRed, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Printed MRP: ₹${item['printed_mrp']}', style: const TextStyle(fontSize: 12, color: AppTheme.slate500, decoration: TextDecoration.lineThrough)),
              const SizedBox(height: 6),
              Text('Description: ${item['description'] ?? 'None'}', style: const TextStyle(fontSize: 12, color: AppTheme.slate700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('ATTACHED EVIDENCE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.1, color: AppTheme.slate700)),
        const SizedBox(height: 8),
        Row(
          children: [
            if (item['receipt_image_url'] != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrl: '${ApiClient.getBaseUrl}${item['receipt_image_url']}',
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${ApiClient.getBaseUrl}${item['receipt_image_url']}',
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            if (item['product_image_url'] != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(
                        imageUrl: '${ApiClient.getBaseUrl}${item['product_image_url']}',
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${ApiClient.getBaseUrl}${item['product_image_url']}',
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // --- Floating Dock Bottom Action Bar ---
  Widget _buildFloatingDock(BuildContext context, bool isComplaint, String scanId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.auraBg.withValues(alpha: 0.0),
            AppTheme.auraBg.withValues(alpha: 0.95),
            AppTheme.auraBg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Re-scan Button
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go('/scan');
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.slate200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.crop_free_rounded, size: 16, color: AppTheme.slate700),
                      SizedBox(width: 5),
                      Text(
                        'Re-scan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Export Full Report Button
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () => _downloadPdfReport(context, isComplaint, scanId),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A), // Slate 900
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Export Audit Report',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Color(0xFF34D399), // Emerald 400
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PDF Export Handler ---
  Future<void> _downloadPdfReport(BuildContext context, bool isComplaint, String scanId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating Audit PDF Report...'),
          duration: Duration(seconds: 2),
        ),
      );
      final dio = Dio();
      final endpoint = isComplaint
          ? '/reports/complaint/$scanId/download'
          : '/reports/$scanId/download';

      final response = await dio.get(
        '${ApiClient.getBaseUrl}$endpoint',
        options: Options(responseType: ResponseType.bytes),
      );
      await Printing.sharePdf(
        bytes: response.data,
        filename: 'nirikshak_audit_$scanId.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF Download: $e')),
        );
      }
    }
  }
}

// Fullscreen Viewer for images
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
            errorBuilder: (c, e, s) => const Icon(
              Icons.broken_image_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}

class RoundedRectangleWidget extends RoundedRectangleBorder {
  const RoundedRectangleWidget({super.borderRadius});
}
