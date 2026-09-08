import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../core/api_client.dart';
import 'details_screen.dart';

class CitizenHomeScreen extends ConsumerStatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  ConsumerState<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends ConsumerState<CitizenHomeScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _history = [];
  int _rewardPoints = 0;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = ref.read(authProvider);
    try {
      final data = await _apiClient.fetchCitizenHistory(auth.userId);
      if (mounted) {
        setState(() {
          _history = data['history'] ?? [];
          _rewardPoints = data['reward_points'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _scans => _history.where((item) => item['type'] == 'SCAN').toList();
  List<dynamic> get _complaints => _history.where((item) => item['type'] == 'COMPLAINT').toList();

  /// Groups scans by manufacturer_name (brand).
  Map<String, List<dynamic>> get _scansByBrand {
    final Map<String, List<dynamic>> grouped = {};
    for (final scan in _scans) {
      final brand = scan['manufacturer_name']?.toString() ?? 'Unknown Brand';
      grouped.putIfAbsent(brand, () => []).add(scan);
    }
    // Sort each group by date descending
    for (final group in grouped.values) {
      group.sort((a, b) {
        final dateA = a['date']?.toString() ?? '';
        final dateB = b['date']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NIRIKSHAK AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Welcome Banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Welcome, ${auth.userName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentCyan.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text('$_rewardPoints PTS', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Photograph any packaged commodity to instantly extract declarations & verify legal metrology compliance.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => context.push('/scan'),
                        icon: const Icon(Icons.camera_alt_outlined, size: 24),
                        label: const Text('SCAN PACKAGED PRODUCT'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/complaint'),
                        icon: const Icon(Icons.receipt_long_outlined, color: AppTheme.warningOrange),
                        label: const Text('FILE MRP OVERCHARGING COMPLAINT', style: TextStyle(color: AppTheme.warningOrange, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.warningOrange),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: AppTheme.accentCyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: AppTheme.accentCyan,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner, size: 16),
                            const SizedBox(width: 6),
                            Text('My Scans (${_scans.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.report_problem_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text('Complaints (${_complaints.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScansTab(),
                      _buildComplaintsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildScansTab() {
    if (_scans.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No scans yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
              Text('Scan a product to get started', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final brandGroups = _scansByBrand;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: brandGroups.length,
      itemBuilder: (context, groupIndex) {
        final brand = brandGroups.keys.elementAt(groupIndex);
        final scans = brandGroups[brand]!;

        // Calculate brand stats
        final passCount = scans.where((s) => s['status'] == 'PASS').length;
        final failCount = scans.where((s) => s['status'] == 'FAIL').length;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 18, color: AppTheme.accentCyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        brand,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.accentCyan),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$passCount✓', style: const TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$failCount✗', style: const TextStyle(color: AppTheme.dangerRed, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Scan items under this brand
              ...scans.map((scan) {
                final isPass = scan['status'] == 'PASS';
                final date = scan['date']?.toString().substring(0, 16).replaceFirst('T', ' ') ?? '';
                final productName = scan['product_name'] ?? 'Unknown Product';

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailsScreen(item: Map<String, dynamic>.from(scan as Map)),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPass ? Icons.check_circle_outline : Icons.highlight_off,
                          color: isPass ? AppTheme.successGreen : AppTheme.dangerRed,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isPass ? AppTheme.successGreen : AppTheme.dangerRed).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            scan['status'] ?? 'UNKNOWN',
                            style: TextStyle(
                              color: isPass ? AppTheme.successGreen : AppTheme.dangerRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComplaintsTab() {
    if (_complaints.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No complaints filed', style: TextStyle(color: Colors.grey, fontSize: 16)),
              Text('File a complaint if you were overcharged', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _complaints.length,
      itemBuilder: (context, index) {
        final item = _complaints[index];
        final date = item['date']?.toString().substring(0, 16).replaceFirst('T', ' ') ?? '';
        final status = item['status'] ?? 'SUBMITTED';
        final isResolved = status != 'SUBMITTED';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsScreen(item: Map<String, dynamic>.from(item as Map)),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isResolved ? Icons.check_circle : Icons.pending_actions,
                        color: isResolved ? AppTheme.successGreen : AppTheme.warningOrange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['shopkeeper_name'] ?? 'Unknown Shop',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isResolved ? AppTheme.successGreen : AppTheme.warningOrange).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: isResolved ? AppTheme.successGreen : AppTheme.warningOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Paid: ₹${item['paid_price']}', style: const TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      Text('MRP: ₹${item['printed_mrp']}', style: const TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.lineThrough)),
                    ],
                  ),
                  if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('"${item['description']}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
